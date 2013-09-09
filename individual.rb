require './type.rb'
require 'yaml'
require 'base64'

PPOOL_DIR = './ppool'
SAMPLE_DIR = './sample'
THREAD_LIMIT = 8


class Individual
  attr_reader :iid, :dict
  attr_accessor :fit, :fit_counter
  def initialize(dict = {}, iid = 0)
    @dict = dict
    @fit = nil
    @fit_counter = nil
    
    @reader, @writer = IO.pipe
  end
  
  def fit
    if @fit.nil? 
      @fit = @reader.gets.strip.to_f
      @fit_counter = YAML.load(Base64.decode64(@reader.gets.strip))
    end
    return @fit
  end
  
  def crossover (other = nil)
    
  end
  
  def mutate!
  end
  
  def evaluate
    counter = {
      :c => {:total => 0, :error => 0, :extension => ['.h', '.c']}, 
      :cpp => {:total => 0, :error => 0, :extension => ['.h', '.cpp']},   
      :csharp => {:total => 0, :error => 0, :extension => ['.cs']},
      :php => {:total => 0, :error => 0, :extension => ['.php']},
      :vb => {:total => 0, :error => 0, :extension => ['.vb']},
      :java => {:total => 0, :error => 0, :extension => ['.java']},
      :ruby => {:total =>0, :error => 0, :extension => ['.rb']},
      :python => {:total =>0, :error => 0, :extension => ['.py']}
    }
    
    total = 0
    errors = 0
    
    Dir.glob(File.join(SAMPLE_DIR, '*')).each do |f|
      extension = "." + f.split('.').last.strip
      next if extension == '.h'
      reality = @dict.keys.select {|k| @dict[k][:extension].include?(extension)}.to_a.first
      
      while (Thread.list.select{|t| t.status}.size == THREAD_LIMIT)
        sleep(1)
      end
      t = Thread.new {
	answer = __analyse_file(f)
        total += 1
        counter[reality][:total] += 1
	if reality != answer
	  errors += 1
          counter[reality][:error] += 1 
        end
      }
    end
    
    total_error = errors.to_f * 100.00 / total.to_f
    
    @writer.puts "#{total_error}"
    @writer.puts Base64.encode64(counter.to_yaml).gsub("\n", '')
    return total_error
  end
  
  def crossover!(i = nil)
    
    
    @fit = nil
    @fit_counter = nil
  end
  
  private
  def __analyse_file(file = nil)
    begin
      return Profile::Type::classify!(file, false)
    rescue
      return ''
    end
  end
end
