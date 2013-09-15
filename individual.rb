require './type.rb'
require 'yaml'
require 'base64'

PPOOL_DIR = './ppool'
SAMPLE_DIR = './sample'
THREAD_LIMIT = 8


class Individual
  attr_accessor :fit, :fit_counter, :dict
  def initialize(dict = {})
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
    @dict.keys.each do |lang|
      perc = @fit_counter[lang][:error] < i.fit_counter[lang][:error]? 0.8 : 0.2
      
      my_genetic = @dict[lang][:keyword].shuffle[0..(perc * @dict[lang][:keyword].size).to_i]
      p_genetic = i.dict[lang][:keyword].shuffle[0..((1.0 - perc) * i.dict[lang][:keyword].size).to_i]
      @dict[lang][:keyword] = (my_genetic + p_genetic).uniq
      mutate!(lang)
    end
    
    
    @fit = nil
    @fit_counter = nil
  end
  
  def mutate!(lang)
    return if @fit_counter[lang][:total].zero?

    error = @fit_counter[lang][:error].to_f / @fit_counter[lang][:total].to_f

    num_changing = (error * @dict[lang][:keyword].size).to_i
    
    if @dict[lang][:keyword].size.zero?
      num_changing = (error * LANGUAGES_KEYWORDS[lang][:keyword].size).to_i
    end
    
    new_size = @dict[lang][:keyword].size - num_changing
    new_kw = LANGUAGES_KEYWORDS[lang][:keyword][0..(num_changing*2)]
    old_kw = @dict[lang][:keyword].shuffle[0..new_size]

    if rand(2).zero? || @dict[lang][:keyword].size.zero?
      @dict[lang][:keyword] = (old_kw + new_kw).uniq
    else
      @dict[lang][:keyword] = (old_kw - new_kw).uniq
    end

#     puts "[+] changing keyword in [#{error * 100}%]"
#     puts "[+] num changing #{num_changing}"
#     puts "OLD: #{@dict[lang][:keyword].sort.inspect}"
#     puts "NEW: #{@dict[lang][:keyword].sort.inspect}"
  end
  
  private
  def __analyse_file(file = nil)
    begin
      return Profile::Type::classify!(file, false, @dict)
    rescue
      return ''
    end
  end
end
