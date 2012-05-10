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
      token(/^(\++|\+|\-|\*|\/|\%|\==|\=|\!|\&&|\<|\>|\<=|\>=|\!=|\(|\)|\]|\[|\|\||\;|\,)/) { |m| m } # Operators etc.
      # token(/-(\d+[.]\d+)/) {|m| Float_Node.new(m.to_f) } #<-- negativa floattal matchas
      # token(/\d+[.]\d+/) {|m| Float_Node.new(m.to_f) } #<-- positiva floattal matchas
      token(/^(-(\d+[.]\d+))/) {|m| m.to_f } # negativa floattal matchas
      token(/^(\d+[.]\d+)/) {|m| m.to_f } # positiva floattal matchas
      token(/^(\d+)/) { |m| m.to_i } # Digits
      token(/^('[^\']*')/) { |m| m } # String with '
      token(/^("[^\"]*")/) { |m| m } # String with "
      token(/^([^\'\"][a-zA-Z0-9_]+[a-zA-Z0-9_]*)/) { |m| m } # Variables

      # token(/./) { |m| m }

      start :program do
        match(:statement_list) { |a| Program_Node.new(a) }
      end

      ## STATEMENT
      rule :statement_list do
        match(:statement_list, :statement) { |a, b| a << b }
        match(:statement) { |a| [a] }
      end
      
      rule :statement do
        match(:print_statement)
        match(:assign_statement)
        match(:if_statement)
        match(:expression)
        match(:loop_statement)
      end

      rule :print_statement do
        match(:identifier, 'scream') { |a, b| Print_Node.new(a) }
        match(:expression, 'scream') { |a, b| Print_Node.new(a) }
        match(:identifier, '[', :integer_expr, ']', 'scream') {
          |a, _, b, _, _|
          PrintSubscript_Node.new(a, b)
        }
      end

      rule :assign_statement do
        match(:expression, '=', :identifier) { |a, b, c| AssignValue_Node.new(c, a) }
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
      ## STATEMENT


      ## EXPRESSIONS
      rule :expression do
        match(:add_one)
        match(:subtract_one)
        match(:or_test)
        match(:array)
        match(:atom)
      end

      rule :add_one do
        match(:identifier, "++") { |a, b| AddOne_Node.new(a) }
      end

      rule :subtract_one do
        match(:identifier, '--') { |a, b| SubtractOne_Node.new(a) }
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
        match(:expression_a) { |a| ArithmeticExpr_Node.new(a) }
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
      
      rule :atom do
        match('(', :comparison, ')') { |a, b, c| b }
        match(:boolean_expr)
        match(:integer_expr)
        match(:float_expr)
        match(:string_expr)
        match(:identifier)
      end

      rule :boolean_expr do
        match("yes") { |a| Boolean_Node.new(a) }
        match("no") { |a| Boolean_Node.new(a) }
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

      # Able to declare variables IF they starts with an underscore (_)
      rule :identifier do
        match(/\A[^(\'|\"|fi|if|esle|else|loop|pool|\,|cluster|cluster size|size|\[|\])][a-z_]+[a-zA-Z0-9_]*/) { |a| Variable_Node.new(a) }
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
ff.log(false)

if (ARGV.length > 0) then
  filename = ARGV[0]
  ff.parse_file(filename)
else
  ff.start_man
end
