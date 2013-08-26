#!/usr/bin/ruby


fd = open('matches.txt')

buffer = []

counter = {
	'c' => {:total => 0, :error => 0, :extension => ['.h', '.c']}, 
	'cpp' => {:total => 0, :error => 0, :extension => ['.h', '.cpp']},   
	'csharp' => {:total => 0, :error => 0, :extension => ['.cs']},
	'php' => {:total => 0, :error => 0, :extension => ['.php']},
	'vb' => {:total => 0, :error => 0, :extension => ['.vb']},
	'java' => {:total => 0, :error => 0, :extension => ['.java']},
	'ruby' => {:total =>0, :error => 0, :extension => ['.rb']},
	'python' => {:total =>0, :error => 0, :extension => ['.py']}
}

while(!fd.eof?)
	line = fd.readline
	
	if line == "\n" 
		file = buffer[-3].strip
		extension = "." + file.split('_').first.split('/').last.strip
		lang = buffer.last.strip
		real_lang = counter.keys.select {|k| counter[k][:extension].include?(extension)}.to_a.first
		
# 		puts "#{real_lang}  #{lang} #{extension} "
		
		next unless counter.has_key?(real_lang)
		counter[real_lang][:total] += 1
		
		
		if extension != '.h'
			if real_lang != lang
				counter[real_lang][:error] += 1
			end
		end
		
		buffer = []
	else
		buffer << line
	end

end

fd.close

total = counter.keys.collect {|k| counter[k][:total]}.inject {|a,b| a+b}
error = counter.keys.collect {|k| counter[k][:error]}.inject {|a,b| a+b}

average_error = (error.to_f * 100.00 / total.to_f)

puts counter.inspect
puts "Average Error [#{average_error}]"