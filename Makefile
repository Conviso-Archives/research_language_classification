:all clean
	ls sample/* | xargs -P7 -I '{}' sh -c 'ruby type.rb {} >> matches.txt'

:clean
	rm -rf matches.txt
