#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require './rdparse.rb'
require './node.rb'

class FlipFlop
  def initialize
    @parser = Parser.new('Flip/Flop') do

      token(/^#(.)*$/) # Enradskommentarer matchas
      token(/##[\w\W\s]*##/) # Blockkommentarer matchas
      token(/^(\s)/) # Whitespace matchas

      token(/^(scream|boj|job|spit|yes|no|fi|if|esle|else|fi esle|else if|esle fi|cluster|cluster size|size)/) { |m| m }
      token(/^(\++|\+|\-|\*|\/|\%|\=|\!|\&&|\<|\>|\<=|\>=|\==|\!=|\(|\)|\]|\[|\|\||\;|\,)/) { |m| m } # Operators etc.
      # token(/-(\d+[.]\d+)/) {|m| Float_Node.new(m.to_f) } #<-- negativa floattal matchas
      # token(/\d+[.]\d+/) {|m| Float_Node.new(m.to_f) } #<-- positiva floattal matchas
      token(/^(-(\d+[.]\d+))/) {|m| m.to_f } # negativa floattal matchas
      token(/^(\d+[.]\d+)/) {|m| m.to_f } # positiva floattal matchas
      token(/^(\d+)/) { |m| m.to_i } # Single digit
      token(/^('[^\']*')/) { |m| m } # String with '
      token(/^("[^\"]*")/) { |m| m } # String with "
      token(/^(\A[^\'\"][a-zA-Z0-9_]+[a-zA-Z0-9_]*)/) { |m| m } # Variables

      # token(/./) { |m| m }

      start :program do
        match(:statement_list) { |a| Program_Node.new(a) }
      end

      ## STATEMENT
      rule :statement_list do
        match(:statement_list, :statement) { |a, b| puts "#{a.class} - #{b.class}"; a << b }
        match(:statement) { |a| [a] }
      end
      
      rule :statement do
        match(:print_statement)
        match(:assign_statement)
        match(:if_statement)
        match(:function_declare)
        match(:return_statement)
        match(:expression)
        match(:loop_statement)
        # match(:read_statement)
      end

      rule :print_statement do
        match(:identifier, 'scream') { |a, b| Print_Node.new(a) }
        match(:atom, 'scream') { |a, b| Print_Node.new(a) }
      end

      rule :assign_statement do
        match(:expression, '=', :identifier) { |a, b, c| AssignValue_Node.new(c, a) }
      end

      rule :if_statement do
        # If-else stmt
        match('fi', :statement_list, 'if', '(', :expression, ')', 'esle', :statement_list, 'else') {
          |_, stmt_list1, _, _, expressions, _, _, stmt_list2, _|
          IfElse_Node.new(stmt_list1, stmt_list2, expressions)
        }

        # If-if else-else stmt
        # Doesn't work. Dunno how to fix it. If else SUCKS!
        # match('fi', :statement_list, 'if', '(', :expression, ')', 'fi esle', :statement_list, 'else if', :expression, 'esle', :statement_list, 'else') {
        #   |_, stmt_list1, _, _, expressions1, _, _, stmt_list2, _, expressions2, _, stmt_list3, _|
        #   IfElse_node
        # }
        match('fi', :statement_list, 'if', '(', :expression, ')', 'esle', :if_statement) {
          |_, stmt_list1, _, _, expressions, _, _, stmt_list2, _|
          IfElse_Node.new(stmt_list1, stmt_list2, expressions)
        }

        # If stmt
        match('fi', :statement_list, 'if', '(', :expression, ')') {
          |_, stmt_list, _, _, expressions, _|
          If_Node.new(stmt_list, expressions)
        }
        # match(:if_only)

        # match('fi', '(', :expression, ')', :statement_list, 'if', :statement_list, 'esle') {
        #   |_, _, expressions, _, stmt_list1, _, stmt_list2, _|
        #   IfElse_Node.new(stmt_list1, stmt_list2, expressions)
        # }

        # match('fi', '(', :expression, ')', :statement_list, 'if', :statement_list, 'esle', :if_statement) {
        #   |_, _, expressions, _, stmt_list1, _, stmt_list2, _|
        #   IfElse_Node.new(stmt_list1, stmt_list2, expressions)
        # }
      end


      ## FUNCTION_DECLARE
      # Does not work!
      rule :function_declare do
        match('boj', :statement_list, 'job', :identifier, '(', :parameter_list, ')') {
          |_, statement_list, _, identifier, _, parameter_list, _|
          FunctionDec_Node.new(statement_list, identifier, parameter_list)
        }
      end

      rule :parameter_list do
        match(:parameter_list, :parameter)
        match(:parameter)
      end

      rule :parameter do
        match(:atom)
      end
      ## FUNCTION_DECLARE


      rule :return_statement do
        match(:expression, "spit") { |a, b| Return_Node.new(a) }
      end


      # rule :read_statement do

      # end
      ## STATEMENT


      ## EXPRESSIONS
      rule :expression do
        match(:add_one)
        match(:subtract_one)
        match(:or_test)
        match(:function_call)
        match(:array)
        match(:array_index)
        # match(:array_size)
        match(:atom)
      end


      rule :or_test do
        match(:and_test)
        match(:or_test, "||", :and_test) { |a, b, c| Compound_Node.new(b, a, c) }
      end

      rule :and_test do
        match(:not_test)
        match(:and_test, "&&", :not_test) { |a, b, c| Compound_Node.new(b, a, c) }
      end

      rule :not_test do
        match(:comparison)
        match("!", :not_test) { |a, b| NotTest_Node.new(b) }
      end

      rule :comparison do
        match(:expression_a, :op_relational, :expression_a) { |a, b, c| Compound_Node.new(b, a, c) }
        match(:expression_a) { |a| ArithmeticExpr_Node2.new(a) }
      end

      rule :expression_a do
        match(:expression_m)
        match(:expression_a, '+', :expression_m) { |a, b, c| Compound_Node.new(b, a, c) }
        match(:expression_a, '-', :expression_m) { |a, b, c| Compound_Node.new(b, a, c) }
      end

      rule :expression_m do
        match(:expression_u)
        match(:expression_m, '*', :expression_u) { |a, b, c| Compound_Node.new(b, a, c) }
        match(:expression_m, '/', :expression_u) { |a, b, c| Compound_Node.new(b, a, c) }
        match(:expression_m, '%', :expression_u) { |a, b, c| Compound_Node.new(b, a, c) }
      end

      rule :expression_u do
        match(:atom)
        match('-', :expression_u) { |a, b| b * -1 }
      end
      
      rule :atom do
        match('(', :comparison, ')') { |a, b, c| b }
        match(:boolean_expr)
        match(:integer_expr)
        match(:float_expr)
        match(:string_expr)
        match(:identifier)
      end

      rule :function_call do

        # match(:identifier, "(", :arg_list, ")")
      end

      rule :array do
        match('cluster', '(', :array_values, ')', '=', :identifier) {
          |_, _, stmt_list, _, _, identifier|
          ArrayNew_Node.new(identifier, stmt_list)
        }
      end

      rule :array_values do
        match(:atom) { |a| [a] }
        match(:array_values, ',', :atom) { |a, b, c| a << c }
      end

      # rule :array_size do
      #   match('size cluster', :identifier) { |a, b| ArraySize_Node.new(b) }
      # end

      rule :array_index do
        match(:identifier, '[', :integer_expr, ']') { |a, _, b, _| ArrayIndex_Node.new(a, b) }
      end

      rule :add_one do
        match(:identifier, "++") { |a, b| AddOne_Node.new(a) }
      end

      rule :subtract_one do
        match(:identifier, '--') { |a, b| SubtractOne_Node.new(a) }
      end

      # Able to declare variables IF they starts with an underscore (_)
      rule :identifier do
        match(/\A[^(\'|\"|fi|if|esle|else|loop|pool|\,|cluster|cluster size|size|\[|\])][a-z_]+[a-zA-Z0-9_]*/) { |a| Variable_Node.new(a) }
        #match(String) { |a| Variable_Node.new(a) }
      end

      rule :integer_expr do
        match(Integer) { |a| Integer_Node.new(a) }
      end

      rule :float_expr do
        match(Float) { |a| Float_Node.new(a) }
      end

      rule :string_expr do
        match(/^('[^\']*')/) { |a| String_Node.new(a) }
        match(/^("[^\"]*")/) { |a| String_Node.new(a) }
      end

      rule :boolean_expr do
        match("yes") { |a| Boolean_Node.new(a) }
        match("no") { |a| Boolean_Node.new(a) }
      end
      ## EXPRESSIONS

      ## LOOP
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
      ## LOOP


      ## OPERATOR RELATIONAL
      rule :op_relational do
        match('<')
        match('<=')
        match('>')
        match('>=')
        match('==')
        match('!=')
      end
      ## OPERATOR RELATIONAL
    end
  end
  
  def done(str)
    ['quit', 'exit'].include?(str.chomp)
  end

  def start_man
    print "ff > "
    user_input = gets

    if done(user_input) then
      puts "Hej da"
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
  ff.start_man
end
