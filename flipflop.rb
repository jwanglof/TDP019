#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require './rdparse.rb'
require './node.rb'

class FlipFlop
  def initialize
    @parser = Parser.new('Flip/Flop') do

      token(/^#(.)*$/) # Enradskommentarer matchas
      token(/^(##[\w\W\s]*##)/) # Blockkommentarer matchas
      token(/^(\s)/) # Whitespace matchas

      token(/^(scream|yes|no|fi|esle|else|esle fi|cluster)/) { |m| m }
      token(/^(\++|\+|\-|\*|\/|\%|\!=|\==|\=|\!|\&&|\<|\>|\<=|\>=|\(|\)|\]|\[|\|\||\;|\,)/) { |m| m } # Operators etc.
      token(/^(-(\d+[.]\d+))/) {|m| m.to_f } # negativa floattal matchas
      token(/^(\d+[.]\d+)/) {|m| m.to_f } # positiva floattal matchas
      token(/^(\d+)/) { |m| m.to_i } # Digits
      token(/^('[^\']*')/) { |m| m } # String with '
      token(/^("[^\"]*")/) { |m| m } # String with "
      token(/^([^\'\"][a-zA-Z0-9_]+[a-zA-Z0-9_]*)/) { |m| m } # Variables

      start :program do
        match(:statement_list) { |stmt_list| Program_Node.new(stmt_list) }
      end

      ## STATEMENT
      rule :statement_list do
        match(:statement_list, :statement) { |stmt_list, stmt| stmt_list << stmt }
        match(:statement) { |stmt| [stmt] }
      end
      
      rule :statement do
        match(:print_statement)
        match(:assign_statement)
        match(:if_statement)
        match(:expression)
        match(:loop_statement)
      end

      rule :print_statement do
        match(:expression, 'scream') { |expr, _| Print_Node.new(expr) }
        match(:identifier, '[', :integer_value, ']', 'scream') {
          |ident, _, int_value, _, _|
          PrintSubscript_Node.new(ident, int_value)
        }
      end

      rule :assign_statement do
        match(:expression, '=', :identifier) { |expr, _, ident| AssignValue_Node.new(ident, expr) }
      end

      rule :if_statement do
        match('fi', '(', :expression, ')', :statement_list, 'esle', :statement_list, 'else') {
          |_, _, expressions, _, stmt_list1, _, stmt_list2, _|
          IfElse_Node.new(stmt_list1, stmt_list2, expressions)
        }

        match('fi', '(', :expression, ')', :statement_list, 'esle', :if_statement) {
          |_, _, expressions, _, stmt_list1, _, stmt_list2|
          IfElse_Node.new(stmt_list1, stmt_list2, expressions)
        }

        match('fi', '(', :expression, ')', :statement_list) {
          |_, _, expressions, _, stmt_list|
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
        match(:identifier, "++") { |ident, _| AddOne_Node.new(ident) }
      end

      rule :subtract_one do
        match(:identifier, '--') { |ident, _| SubtractOne_Node.new(ident) }
      end

      rule :or_test do
        match(:and_test)
        match(:or_test, "||", :and_test) { |expr1, operator, expr2| Compound_Node.new(operator, expr1, expr2) }
      end

      rule :and_test do
        match(:not_test)
        match(:and_test, "&&", :not_test) { |expr1, operator, expr2| Compound_Node.new(operator, expr1, expr2) }
      end

      rule :not_test do
        match(:comparison)
        match("!", :not_test) { |_, expr| NotTest_Node.new(expr) }
      end

      rule :expression_addition do
        match(:expression_multiplication)
        match(:expression_addition, '+', :expression_multiplication) { |expr1, operator, expr2| Compound_Node.new(operator, expr1, expr2) }
        match(:expression_addition, '-', :expression_multiplication) { |expr1, operator, expr2| Compound_Node.new(operator, expr1, expr2) }
      end

      rule :expression_multiplication do
        match(:expression_unary)
        match(:expression_multiplication, '*', :expression_unary) { |expr1, operator, expr2| Compound_Node.new(operator, expr1, expr2) }
        match(:expression_multiplication, '/', :expression_unary) { |expr1, operator, expr2| Compound_Node.new(operator, expr1, expr2) }
        match(:expression_multiplication, '%', :expression_unary) { |expr1, operator, expr2| Compound_Node.new(operator, expr1, expr2) }
      end

      rule :expression_unary do
        match(:atom)
        match('-', :expression_unary) { |_, unary| unary * -1 }
      end

      ## ARRAY
      rule :array do
        match('cluster', '(', :array_values, ')', '=', :identifier) {
          |_, _, stmt_list, _, _, identifier|
          ArrayNew_Node.new(identifier, stmt_list)
        }
      end

      rule :array_values do
        match(:atom) { |atom| [atom] }
        match(:array_values, ',', :atom) { |array_values, _, atom| array_values << atom }
      end
      ## !ARRAY

      rule :comparison do
        match(:expression_addition, :op_relational, :expression_addition) { |expr1, operator, expr2| Compound_Node.new(operator, expr1, expr2) }
        match(:expression_addition) { |expr| ArithmeticExpr_Node.new(expr) }
      end
      
      rule :atom do
        match(:boolean_value)
        match(:integer_value)
        match(:float_value)
        match(:string_value)
        match(:identifier)
      end

      rule :boolean_value do
        match("yes") { |bool_value| Boolean_Node.new(bool_value) }
        match("no") { |bool_value| Boolean_Node.new(bool_value) }
      end

      rule :integer_value do
        match(Integer) { |int_value| Integer_Node.new(int_value) }
      end

      rule :float_value do
        match(Float) { |float_value| Float_Node.new(float_value) }
      end

      rule :string_value do
        match(/^('[^\']*')/) { |string_value| String_Node.new(string_value) }
        match(/^("[^\"]*")/) { |string_value| String_Node.new(string_value) }
      end

      rule :identifier do
        match(/[^(\'|\"|fi|if|esle|else|loop|pool|\,|cluster\[|\])][a-z_]+[a-zA-Z0-9_]*/) {
          |var|
          Variable_Node.new(var)
        }
      end
      ## !EXPRESSIONS

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
      ## !LOOP
      ## !STATEMENT

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
      puts "flip/flop says BYE BYE"
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
