#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require './rdparse.rb'
require './node.rb'

class FlipFlop
    def initialize
	@parser = Parser.new('Flip/Flop') do

	    
	## LEXER

	# One-row comments
	token(/^#(.)*$/)
	# Multi-rows comments
	token(/^(##[\w\W\s]*##)/)
	# White spaces
	token(/^(\s)/)
	# Specific syntax for the language
	token(/^(scream|yes|no|fi|esle|else|esle fi|cluster|boj|job)/) { |m| m }
	# Operators etc.
	token(/^(\++|\--|\+|\-|\*|\/|\%|\!=|\==|\<=|\>=|\=|\!|\&&|\<|\>|\(|\)|\]|\[|\|\||\;|\,)/) { |m| m } 
	# Negative floats
	token(/^(-(\d+[.]\d+))/) {|m| m.to_f }
	# Positive floats
	token(/^(\d+[.]\d+)/) {|m| m.to_f }
	# Digits
	token(/^(\d+)/) { |m| m.to_i }
	# Strings that starts with '
	token(/^('[^\']*')/) { |m| m }
	# Strings that starts with "
	token(/^("[^\"]*")/) { |m| m }
	# Variables
	token(/[a-zA-Z0-9_]+/) { |m| m }

	## !LEXER


	start :program do
	    match(:statement_list) { |stmt_list|
		Program_Node.new(stmt_list)
	    }
	end

	## STATEMENTS
	rule :statement_list do
	    match(:statement_list, :statement) { |stmt_list, stmt|
		stmt_list << stmt
	    }
	    match(:statement) { |stmt| [stmt] }
	end
      
	rule :statement do
	    match(:function_call)
	    match(:print_statement)
	    match(:assign_statement)
	    match(:if_statement)
	    match(:expression)
	    match(:loop_statement)
	    match(:function_declare)
	end

	## FUNCTION CALL
	rule :function_call do
	    match(:identifier, '(', ')') { |name, _, _|
		FunctionCall_Node.new(name, nil)
	    }
	    match(:identifier, '(', :argument_list, ')') { |name, _, arg_list, _|
		FunctionCall_Node.new(name, arg_list)
	    }
	end
	## !FUNCTION CALL

	# The first print-statement will print an expression
	# The second print-statement will subscript a variable or an array and print the value
	rule :print_statement do
	    match(:expression, 'scream') { |expr, _|
		Print_Node.new(expr)
	    }
	    match(:identifier, '[', :integer_value, ']', 'scream') { |ident, _, int_value, _, _|
		PrintSubscript_Node.new(ident, int_value)
	    }
	end

	# Assign an expression to a variable
	rule :assign_statement do
	    match(:expression, '=', :identifier) { |expr, _, ident|
		AssignValue_Node.new(ident, expr)
	    }
	end

	# The first if-statement is an if with an else
	# The second statement is an if with a number of if-else-statements
	# The third one is just an if
	rule :if_statement do
	    # If-else
	    match('fi', '(', :expression, ')', :statement_list, 'esle', :statement_list, 'else') { |_, _, expressions, _, stmt_list1, _, stmt_list2, _|
		IfElse_Node.new(stmt_list1, stmt_list2, expressions)
	    }

	    # If-elseif
	    match('fi', '(', :expression, ')', :statement_list, 'esle', :if_statement) { |_, _, expressions, _, stmt_list1, _, stmt_list2|
		IfElse_Node.new(stmt_list1, stmt_list2, expressions)
	    }

	    # If
	    match('fi', '(', :expression, ')', :statement_list, 'if') { |_, _, expressions, _, stmt_list, _|
		If_Node.new(stmt_list, expressions)
	    }
	end

	## EXPRESSIONS
	rule :expression do
	    match(:add_one)
	    match(:subtract_one)
	    match(:or_test)
	    match(:array)
	    match('(', :comparison, ')') { |_, comp, _| comp }
	    match(:atom)
	end

	rule :add_one do
	    match(:identifier, "++") { |ident, _|
		AddOne_Node.new(ident)
	    }
	end

	rule :subtract_one do
	    match(:identifier, '--') { |ident, _|
		SubtractOne_Node.new(ident)
	    }
	end

	rule :or_test do
	    match(:and_test)
	    match(:or_test, "||", :and_test) { |expr1, operator, expr2|
		Compound_Node.new(operator, expr1, expr2)
	    }
	end

	rule :and_test do
	    match(:not_test)
	    match(:and_test, "&&", :not_test) { |expr1, operator, expr2|
		Compound_Node.new(operator, expr1, expr2)
	    }
	end

	rule :not_test do
	    match(:comparison)
	    match("!", :not_test) { |_, expr|
		NotTest_Node.new(expr)
	    }
	end

	rule :expression_addition do
	    match(:expression_multiplication)
	    match(:expression_addition, '+', :expression_multiplication) { |expr1, operator, expr2|
		Compound_Node.new(operator, expr1, expr2)
	    }
	    match(:expression_addition, '-', :expression_multiplication) { |expr1, operator, expr2|
		Compound_Node.new(operator, expr1, expr2)
	    }
	end

	rule :expression_multiplication do
	    match(:expression_unary)
	    match(:expression_multiplication, '*', :expression_unary) { |expr1, operator, expr2|
		Compound_Node.new(operator, expr1, expr2)
	    }
	    match(:expression_multiplication, '/', :expression_unary) { |expr1, operator, expr2|
		Compound_Node.new(operator, expr1, expr2)
	    }
	    match(:expression_multiplication, '%', :expression_unary) { |expr1, operator, expr2|
		Compound_Node.new(operator, expr1, expr2)
	    }
	end

	rule :expression_unary do
	    match(:atom)
	    match('-', :expression_unary) { |_, unary| unary * -1 }
	end

	## ARRAY
	rule :array do
	    match('cluster', '(', :array_values, ')', '=', :identifier) { |_, _, stmt_list, _, _, identifier|
		ArrayNew_Node.new(identifier, stmt_list)
	    }
	end

	rule :array_values do
	    match(:atom) { |atom| [atom] }
	    match(:array_values, ',', :atom) { |array_values, _, atom|
		array_values << atom
	    }
	end
	## !ARRAY

	rule :comparison do
	    match(:expression_addition, :op_relational, :expression_addition) { |expr1, operator, expr2|
		Compound_Node.new(operator, expr1, expr2)
	    }
	    match(:expression_addition) { |expr|
		ArithmeticExpr_Node.new(expr)
	    }
	end
      
	rule :atom do
	    match(:boolean_value)
	    match(:integer_value)
	    match(:float_value)
	    match(:string_value)
	    match(:identifier)
	end

	rule :boolean_value do
	    match("yes") { |bool_value|
		Boolean_Node.new(bool_value)
	    }
	    match("no") { |bool_value|
		Boolean_Node.new(bool_value)
	    }
	end

	rule :integer_value do
	    match(Integer) { |int_value|
		Integer_Node.new(int_value)
	    }
	end

	rule :float_value do
	    match(Float) { |float_value|
		Float_Node.new(float_value)
	    }
	end

	rule :string_value do
	    match(/^('[^\']*')/) { |string_value|
		String_Node.new(string_value)
	    }
	    match(/^("[^\"]*")/) { |string_value|
		String_Node.new(string_value)
	    }
	end

	# Variable match
	# The reg-exp is pretty ugly but for some reason we need to have it like this or
	#  the parser won't recognize when we declare our variables
	rule :identifier do
	    match(/[^(\'|\"|fi|if|esle|else|loop|pool|boj|job|\(|\)|\,|cluster\[|\])][a-z_]+[a-zA-Z0-9_]*/) { |var|
		Variable_Node.new(var)
	    }
	end
	## !EXPRESSIONS

	## LOOP

	# The first statement is for a for-loop.
	# The second is for a while-loop.
	rule :loop_statement do
	    # For-loop
	    match("pool", :statement_list, "loop", "(", :assign_statement, ';', :or_test, ';', :expression, ")") {
	    |_, statement_list, _, _, assign_statement, _, or_test, _, expression, _|
		LoopFor_Node.new(statement_list, assign_statement, or_test, expression)
	    }

	    # While-loop
	    match("pool", :statement_list, "loop", "(", :expression, ")") {
	    |_, stmt_list, _, _, expressions, _|
		LoopWhile_Node.new(stmt_list, expressions)
	    }
	end
	## !LOOP

	## FUNCTION DECLARATION
	rule :function_declare do
	    match('boj', :statement_list, 'job', :identifier, '(', :parameter_list, ')') { |_, stmt_list, _, name, _, param_list, _|
		FunctionDeclare_Node.new(stmt_list, name, param_list)
	    }
	    match('boj', :statement_list, 'job', :identifier, '(', ')') { |_, stmt_list, _, identifier, _, _|
		FunctionDeclare_Node.new(stmt_list, identifier, nil)
	    } 
	end
	## !FUNCTION DECLARATION
	## !STATEMENTS

	## OPERATOR RELATIONAL
	rule :op_relational do
	    match('<')
	    match('<=')
	    match('>')
	    match('>=')
	    match('==')
	    match('!=')
	end
	##  !OPERATOR RELATIONAL

	rule :argument_list do
	    match(:argument_list, ',', :argument) { |arg_list, _, arg|
		arg_list+ [arg]
	    }
	    match(:argument) { |arg| [arg] }
	end

	rule :argument do
	    match(:expression)
	end

	rule :parameter_list do
	    match(:parameter_list, ',', :parameter) { |param_list, _, param|
		param_list+ [param]
	    }
	    match(:parameter) { |param| [param] }
	end

	rule :parameter do
#	    match(:expression)
        match(:identifier)
	end

   end
  
    def done(str)
	['exit', 'quit', 'q'].include?(str.chomp)
    end

    def start_man
	ffMessenger("Current scope: #{@@scope}") if @@ffHelper
	ffMessenger("Current variable stack: #{@@variables}") if @@ffHelper
	ffMessenger("Current function stack: #{@@functions}") if @@ffHelper

	print "f/f > "
	user_input = gets

	if done(user_input) then
	    ffMessenger("Bye bye!\n\n")
	else
	result = @parser.parse(user_input)

	result.evaluate()
	start_man
	end
    end

    def parse_file(filename)
	@parser.parse(IO.read(filename)).evaluate()
    end

    def log(state = true)
	if state
	    @parser.logger.level = Logger::DEBUG
	else
	    @parser.logger.level = Logger::WARN
	end
    end
end

ff = FlipFlop.new
ff.log(true)

if (ARGV.length > 0) then
    filename = ARGV[0]
    ff.parse_file(filename)
else
    puts ""
    84.times { |x| print "*" }; puts "*"
    print "*", " ".center(83); puts "*"
    print "*", "FLIP/FLOP 1.0".center(83); puts "*"
    print "*", " ".center(83); puts "*"
    print "*", "Dishing out f/f awesomeness since 2012. All rights reserved. Not really.".center(83); puts "*"
    print "*", "User's manual is located in /Docs.".center(83); puts "*"
    print "*", "Type 'exit', 'quit' or 'q' to exit.".center(83); puts "*"
    print "*", " ".center(83); puts "*"
    84.times { |x| print "*" }; puts "*"
    
    ff.start_man
end
end
