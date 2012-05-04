#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require './rdparse.rb'
require './node.rb'

class FlipFlop
  def initialize
    @parser = Parser.new('Flip/Flop') do

      token(/\s/)
      # token(/-(\d+[.]\d+)/) {|m| Float_Node.new(m.to_f) } #<-- negativa floattal matchas
      # token(/\d+[.]\d+/) {|m| Float_Node.new(m.to_f) } #<-- positiva floattal matchas
      token(/-(\d+[.]\d+)/) {|m| m.to_f } #<-- negativa floattal matchas
      token(/\d+[.]\d+/) {|m| m.to_f } #<-- positiva floattal matchas
      token(/\d+/) { |m| m.to_i } # Single digit
      token(/(\+|\-|\*|\/|\%|\=|\!|\&|\<|\>|\<=|\>=|\==|\!=|\(|\))/) { |m| m } # Operators etc.
      token(/'[^\']*'/) { |m| m } # String with '
      token(/"[^\"]*"/) { |m| m } # String with "
      token(/\A[^\'\"][a-zA-Z0-9_]+[a-zA-Z0-9_]*/) { |m| m } # Variables
      
      token(/scream|boj|job|spit|yes|no/) { |m| m }
      
      token(/./) { |m| m }

      ## STATEMENT
      start :statement_list do
        match(:statement_list, :statement)
        match(:statement)
      end
      
      rule :statement do
        match(:print_statement)
        match(:assign_statement)
        match(:function_declare)
        match(:expression)
        match(:return_statement)
        # match(:if_statement)
        # match(:loop_statement)
        # match(:read_statement)
      end
      
      rule :print_statement do
        match(:identifier, 'scream') { |a, b| Print_Node.new(a) }
        match(:atom, 'scream') { |a, b| Print_Node.new(a) }
      end

      rule :assign_statement do
        match(:expression, '=', :identifier) { |a, b, c| AssignValue_Node.new(c, a) }
      end

      # Does not work!
      rule :function_declare do
        match('boj', :statement_list, 'job', :identifier, '(', :parameter_list, ')') {
          |_, statement_list, _, identifier, _, parameter_list, _|
          FunctionDec_Node.new(statement_list, identifier, parameter_list)
        }
      end


      ## FUNCTION_DECLARE
      rule :parameter do
        match(:atom)
      end
      
      rule :parameter_list do
        match(:parameter_list, :parameter)
        match(:parameter)
      end
      ## FUNCTION_DECLARE


      rule :return_statement do
        match(:expression, "spit") { |a, b| Return_Node.new(a) }
      end

      # rule :if_statement do
        
      # end

      # rule :loop_statement do
      #   match("pool", :statement_list, "loop", "(", :assign_statement, :expression_pred, :statement, ")") { |no_use, statement_list, no_use2, no_use3, assign_statement, expression_pred, statement, no_use4| Loop_Node.new(statement_list, expression_pred, assign_statement, statement) }
      #   match("pool", :statement_list, "loop", "(", :expression_pred, ")") { }        
      # end

      # rule :read_statement do

      # end

      # rule :op_assignment do
      #   match('=')
      # end
      ## STATEMENT


      ## EXPRESSIONS
      rule :expression do
        match(:expression_pred)
        match(:expression_arithmetic)
        match(:function_call)
        match(:atom)
      end

      rule :expression_pred do
        match(:atom, :op_relational, :expression) { |a, b, c| PredicatExpr_Node.new(b, a, c) }
        match(:atom, :op_logic, :expression) { |a, b, c| PredicatExpr_Node.new(b, a, c) }
      end

      rule :expression_arithmetic do
        match(:atom, :op_arithmetic, :expression) { |a, b, c| ArithmeticExpr_Node.new(b, a, c) }
      end

      rule :function_call do
        # match(:identifier, "(", :arg_list, ")")
      end

      rule :atom do
        match(:identifier)
        match(:integer_expr)
        match(:float_expr)
        match(:string_expr)
        match(:boolean_expr)
      end

      rule :identifier do
        match(/\A[^\'\"][a-z_]+[a-zA-Z0-9_]*/) { |a| Variable_Node.new(a) }
      end

      rule :integer_expr do
        match(Integer) { |a| Integer_Node.new(a) }
      end

      rule :float_expr do
        match(Float) { |a| Float_Node.new(a) }
      end

      rule :string_expr do
        match(/'[^\']*'/) { |a| String_Node.new(a) }
        match(/"[^\"]*"/) { |a| String_Node.new(a) }
      end

      rule :boolean_expr do
        match("yes") { |a| Boolean_Node.new(a) }
        match("no") { |a| Boolean_Node.new(a) }
      end
      ## EXPRESSIONS


      ## OPERATOR ARITHMETIC
      rule :op_arithmetic do
        match("+")
        match("-")
        match("*")
        match("/")
        match("%")
      end
      ## OPERATOR ARITHMETIC
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
      ## OPERATOR LOGIC
      rule :op_logic do
        match('!')
        match('&')
        match('|')
      end
      ## OPERATOR LOGIC
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
ff.start_man
