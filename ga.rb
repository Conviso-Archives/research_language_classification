require './individual.rb'
require './macros.rb'

ppool_size = 4
population_size = 76
iterations = 200
paralelism = 2

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

reader, writer = IO.pipe

population = (1..population_size).collect { |x|
  Individual.new(__rdn_dict(LANGUAGES_KEYWORDS), (x-1), writer)
}


process_pool = []
(1..iterations).each do
  i = 0
  
  while i != (population_size - 1)  do
    process_pool = process_pool.select do |pid| 
        begin 
          Process.getpgid(pid)
          true
        rescue
          false
        end
      end
    if process_pool.size < paralelism
      pid = fork {
        population[i].evaluate
      }
      process_pool << pid
      i += 1
    end
  end
    

  # Checking out all the results
  (0..(population_size - 1)).each do
    line = reader.gets
    puts line
  end

end


process_pool << pid

while (true) do
  puts process_pool.size
  sleep 1
end
  