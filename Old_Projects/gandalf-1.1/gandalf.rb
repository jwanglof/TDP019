require "parser"

@wizard = Gandalf.new

def read_manual_input(code = "")
	if code == "" 
		print "Gdf> "
	else
		print ".... "
	end
	line = gets
	if(line == "\n" && code != "")
		code += line
		puts "=> #{@wizard.parser.parse(code)}"
		read_manual_input
	elsif(!["quit","exit"].include?(line.chomp))
		code += line if line != "\n"
		read_manual_input(code)
	end
end

def read_file_input(code = "")
	input = gets
	if (input)
		read_file_input(code += input)
	else
		puts "=> #{@wizard.parser.parse(code + "\n")}"
	end
end

if ARGV.length > 0
	read_file_input
else
	read_manual_input
end
