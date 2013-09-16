#
#  Marcos Álvares (malvares@conviso.com.br)  2013
#
# This module is resposible for detecting the used programming language by
# using a scoring approach.
#
# http://en.cppreference.com/w/cpp/keyword
# http://en.wikipedia.org/wiki/C_syntax#Reserved_keywords
# http://docs.oracle.com/javase/specs/jls/se5.0/html/lexical.html#3.9
# http://phrogz.net/ProgrammingRuby/language.html#names
# http://en.wikipedia.org/wiki/Python_syntax_and_semantics#Keywords
# 
#
#

require './macros.rb'

module Profile
  class Type
    @@mlcomment = false
    def Type::classify!(input = '', use_extension = true, dict = nil)
      @dict = dict || LANGUAGES_KEYWORDS
      
      @@use_extension = use_extension
      score_vector = {}
      
      if (File.exists?(input))
        score_vector = __classify_by_file_name(input)
      else
        score_vector = __classify_by_string(input)
      end
      
      str1 = score_vector.inspect
      str2 = score_vector.keys.sort {|a,b| score_vector[a] <=> score_vector[b]}.last
      # puts "#{ARGV[0]}\n#{str1}\n#{str2}\n\n"
      return str2
    end
    
    private
    def Type::__classify_by_string(input = '')
      score_vector = {}

      @dict.keys.collect do |k|
        score_vector[k] = score_vector[k].to_i
        score_vector[k] += __analyse_string_for_language(k, input)
      end

      return score_vector
    end

    def Type::__classify_by_file_name(input = '')
      fd = File.open(input)
      score_vector = {}
      
      score_vector = __analyse_file_extension(input) if @@use_extension
      while(!fd.eof?)
        line = fd.readline
        @dict.keys.collect do |k|
          score_vector[k] = score_vector[k].to_i
          score_vector[k] += __analyse_string_for_language(k, line)
        end
      end
      
      fd.close
      return score_vector
    end
    
    def Type::__analyse_file_extension(input)
      score_vector = {}

      @dict.keys.each do |k|
        extension = @dict[k][:extension]
        score_vector[k] = score_vector[k].to_i
        score_vector[k] += @dict if extension.include?("." + input.split('.').last)
      end
      
      return score_vector
    end
    
    def Type::__analyse_string_for_language(k, line)
      unique_keywords = __get_unique_keywords_for_language(k)
      intersection_group = __get_intersection_group
      keywords = @dict[k][:keyword] - unique_keywords
      keywords -= intersection_group
      line.strip!
      
      # Discarding few comments lines 
      @@mlcomment = true if (line =~ /^\/\*/)
      
      @@mlcomment = false if @@mlcomment && line =~ /\*\/$/
      line = '' if @@mlcomment
      line = '' if (line =~ /^(# |\/\/)/)

      qty_unq = line.scan(/(^|\b)(#{unique_keywords.join('|')})\b/i).uniq.size
      
      qty_mtc = line.scan(/(^|\b)(#{keywords.join('|')})\b/i).uniq.size

      if (!qty_mtc.zero? || !qty_unq.zero?) && k == :c
#         puts k
#         puts line.scan(/(^|\b)(#{unique_keywords.join('|')})\b/i).inspect
#         puts line.scan(/(^|\b)(#{keywords.join('|')})\b/i).inspect
      end

      return (qty_unq * UNIQUE_KEYWORD_WEIGHT) + (qty_mtc * KEYWORD_WEIGHT)
    end
    
    def Type::__get_unique_keywords_for_language(k)
      tks = @dict.clone
      ks = []
      ks << tks.delete(k)[:keyword]
      tks.each {|k1,v| ks << v[:keyword]}
      ks.inject{|a,b| a - b}
    end
    
    def Type::__get_intersection_group
      @dict.collect {|k,v|v[:keyword]}.inject {|a,b| a & b}
    end
  end
end