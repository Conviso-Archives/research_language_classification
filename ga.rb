require './individual.rb'
require './macros.rb'
require 'pry'
require 'yaml'
require 'digest/sha1'
require 'net/smtp'

hostname = `hostname`.strip

if !File.exists?('config.yml')
  puts '[!] config.yml not found.'
  exit
end

config = YAML.load_file('config.yml')
# system("ssh -i /home/mabj/.ssh/experiment_id_dsa experiment@marcosalvares.com 'cat /dev/null > ~/experiment/#{hostname}.txt'")

already_tested = []
counter = {:total_tests => 0, :repeated_tests => 0, :envolve_period => 0}


File.delete('fitness.txt') if File.exists?('fitness.txt')
File.delete('best_solution.txt') if File.exists?('best_solution.txt')

fitness_fd = File.open('fitness.txt', 'a')
best_solution_fd = File.open('best_solution.txt', 'a')

def send_email(optimum = '', hostname = nil)
  puts '[+] Sending e-mail ...'
message = <<MESSAGE_END
From: BOT_#{hostname} <#{hostname}@marcosalvares.com>
To: Marcos Alvares <marcos.alvares@gmail.com>
Subject: I FOUND A NEW OPTIMUM! [#{optimum}]

I FOUND A NEW OPTIMUM! [#{optimum}]
#{Time.now}
MESSAGE_END

  Net::SMTP.start('localhost') do |smtp|
    smtp.send_message message, "#{hostname}@marcosalvares.com", 'marcos.alvares@gmail.com'
  end
end

def __calculate_dict_hash(individual = nil)
  str = individual.dict.keys.collect {|lang| individual.dict[lang].sort.join(',') }.sort.join('|')
  return Digest::SHA1.hexdigest(str)
end


def __rdn_dict(list = nil)
  new_dict = {}

  list.keys.each do |k|
    keyword_size = list[k][:keyword].size
    min = (keyword_size * 0.4).to_i
    new_dict[k] = {
      :keyword => list[k][:keyword].shuffle[0..(min+rand(keyword_size-min))],
      :extension => list[k][:extension]
    }
  end
  return new_dict
end

population = (1..config[:population_size]).collect { |x|
  Individual.new(__rdn_dict(LANGUAGES_KEYWORDS))
}

hall_of_fame = population[0..(config[:hall_of_fame_size]-1)]

puts "[+] Creating a population of #{population.size} individuals"

process_pool = []
(1..config[:iterations]).each do |iteration|
  i = 1
  puts "[+] Starting iteration [#{iteration}]"
  
  already_tested += population.collect { |i| __calculate_dict_hash(i)}
  already_tested.uniq!
  
  while i <= config[:population_size]  do

    # Calculates number of active processes
    process_pool = process_pool.select do |pid| 
      begin 
        Process.getpgid(pid)
        true
      rescue
        false
      end # begin
    end # do
    
    # If there is space inside the process pool just trigger one more process
    if process_pool.size < config[:paralelism]
#       puts "[+] Process pool with size #{process_pool.size}"
#       puts "[+] Adding a new process to the process pool"
      pid = fork {
        population[i-1].evaluate
      }
      Process.detach(pid)
      process_pool << pid
      i += 1
    else
      sleep 1
    end # if
  end # while
    

  # Checking out all the results after processing all population
  puts "[+] Collecting results for this population"
  population.sort!{|a,b| a.fit <=> b.fit}
  puts "[+] Fittest individual: #{population.first.fit}"
  puts "[+] Less fit individual: #{population.last.fit}"
  
  
  # Storing the "config[:hall_of_fame_size]" best solution
  last_fittest = hall_of_fame.first.fit
  hall_of_fame = (hall_of_fame + population[0..(config[:hall_of_fame_size]-1)]).sort {|a,b| a.fit <=> b.fit}[0..(config[:hall_of_fame_size]-1)].collect {|i| i.clone}
  new_fittest = hall_of_fame.first.fit
  
  puts "[+] Hall of Fame: [#{hall_of_fame.collect {|i| i.fit}.join(', ')}]"
  
  if last_fittest == new_fittest
    counter[:envolve_period] += 1
  end
  
  puts "[+] Global Best #{hall_of_fame.first.fit}"
  
  if new_fittest < last_fittest
#     system("ssh -i /home/mabj/.ssh/experiment_id_dsa experiment@marcosalvares.com 'echo [#{Time.now}] #{iteration} #{hall_of_fame.first.fit} >> ~/experiment/#{hostname}.txt'")
    fitness_fd.puts(hall_of_fame.first.fit)
    fitness_fd.flush
    best_solution_fd.puts(hall_of_fame.first.dict.to_yaml.inspect)
    best_solution_fd.flush
    send_email(new_fittest, hostname) if config[:send_email]
  end

  population.sort!{|a,b| a.fit <=> b.fit}
  population.each do |i| 
    i.crossover!(hall_of_fame.sample)
    counter[:total_tests] += 1
    while(already_tested.include?(__calculate_dict_hash(i)))
      counter[:repeated_tests] += 1
      i.crossover!(hall_of_fame.sample) 
    end

  end
  
  if counter[:envolve_period] == config[:randomize_threshold]
    puts "[+] Randomizing half of the population ..."
    population.shuffle[(config[:population_size]/2)..-1].each { |i|
      i.dict = __rdn_dict(LANGUAGES_KEYWORDS)
    }
    counter[:envolve_period] = 0
  end

  
  puts counter.inspect
  puts "\n"
end

fitness_fd.close
best_solution_fd.close
