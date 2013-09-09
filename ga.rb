require './individual.rb'
require './macros.rb'
require 'pry'

population_size = 6
iterations = 1
paralelism = 6

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

population = (1..population_size).collect { |x|
  Individual.new(__rdn_dict(LANGUAGES_KEYWORDS), (x-1))
}

hall_of_fame = []

puts "[+] Creating a population of #{population.size} individuals"

process_pool = []
(1..iterations).each do |iteration|
  i = 1
  puts "[+] Starting iteration [#{iteration}]"
  
  while i <= population_size  do

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
    if process_pool.size < paralelism
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
  puts "\n[+] Collecting results for this population"
  population.sort!{|a,b| a.fit <=> b.fit}
  puts "[+] Fittest individual: #{population.first.fit}"
  puts "[+] Less fittest individual: #{population.last.fit}"
  
  # Storing the 5 best solution
  hall_of_fame = (hall_of_fame + population[0..4]).sort {|a,b| a.fit <=> b.fit}[0..4].collect {|i| i.clone}
  
  population.each { |i| i.crossover!(hall_of_fame.sample) }
end
 