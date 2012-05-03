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
      token(/(\+|\-|\*|\/|\%|\=|\!|\&|\<)/) { |m| m } # Operators etc.
      token(/'[^\']*'/) { |m| m } # String with '
      token(/"[^\"]*"/) { |m| m } # String with "

      token(/scream/) { |m| m }
      token(/spit/) { |m| m }
      
      token(/./) { |m| m }

      start :statement_list do
        match(:statement_list, :statement)
        match(:statement)
      end

      ## EXPRESSIONS
      rule :expression do
        match(:boolean_expr)
        match(:expression_arithmetic)
        match(:expression_pred)
        match(:function_call)
        match(:identifier_expr)
        match(:integer_expr)
        match(:float_expr)
        match(:string_expr)
      end


      rule :boolean_expr do

      end

      rule :expression_arithmetic do

      end

      rule :expression_pred do
        match(:expression, :op_relational, :expression) {}
        # match(:expression, :op_logic, :expression) {}
      end

      rule :function_call do

      end

      rule :identifier_expr do
        match(/[a-z_]+[a-zA-Z0-9_]*/) { |a| Variable_Node.new(a) }
      end

      rule :integer_expr do
        match(Integer) { |a| Integer_Node.new(a) }
      end

      rule :float_expr do
        match(Float) { |a| Float_Node.new(a) }
      end

      rule :string_expr do
        match(String) { |a| String_Node.new(a) }
      end
      ## EXPRESSIONS


      ## OPERATOR ARITHMETIC
      rule :op_arithmetic do
        match(:arithmetic_expressions)
      end

      rule :arithmetic_expressions do
        match(:expression, "+", :expression) { |a, b, c| Op_Arithmetic_Node.new(b, a, c) }
        match(:expression, "-", :expression) { |a, b, c| Op_Arithmetic_Node.new(b, a, c) }
        match(:expression, "*", :expression) { |a, b, c| Op_Arithmetic_Node.new(b, a, c) }
        match(:expression, "/", :expression) { |a, b, c| Op_Arithmetic_Node.new(b, a, c) }
        match(:expression, "%", :expression) { |a, b, c| Op_Arithmetic_Node.new(b, a, c) }
      end
      ## OPERATOR ARITHMETIC


      ## OPERATOR RELATIONAL
      rule :op_relational do
        match(:expression, '<', :expression) { |a, b, c| Op_Relational_Node.new(b, a, c) }
        match(:expression, '<=', :expression) { |a, b, c| Op_Relational_Node.new(b, a, c) }
        match(:expression, '>', :expression) { |a, b, c| Op_Relational_Node.new(b, a, c) }
        match(:expression, '>=', :expression) { |a, b, c| Op_Relational_Node.new(b, a, c) }
        match(:expression, '==', :expression) { |a, b, c| Op_Relational_Node.new(b, a, c) }
        match(:expression, '!=', :expression) { |a, b, c| Op_Relational_Node.new(b, a, c) }
      end
      ## OPERATOR RELATIONAL


      ## STATEMENT
      rule :statement do
        match(:assign_statement)
        match(:function_call)
        match(:function_declare)
        match(:if_statement)
        match(:loop_statement)
        match(:print_statement)
        match(:read_statement)
        match(:return_statement)

        # Borde flytta? Var då? Går inte ihop i grammatiken... -.-
        match(:op_arithmetic)
      end
      
      rule :assign_statement do
        match(:expression, :op_assignment, :identifier_expr)
      end

      rule :function_call do
        match("pool", :statement_list, "loop", "(", :assign_statement, :expression_pred, :statement, ")") { |no_use, statement_list, no_use2, no_use3, assign_statement, expression_pred, statement, no_use4| Loop_Node.new(statement_list, expression_pred, assign_statement, statement)
        match("pool", :statement_list, "loop", "(", :expression_pred, ")")
      end

      rule :function_declare do
        
      end

      rule :if_statement do
        
      end

      rule :loop_statement do
        
      end

      rule :print_statement do
        match(:string_expr, "scream") { |a, b| Print_Node.new(a) }
      end

      rule :read_statement do

      end
    
      rule :return_statement do
        match(:expression, "spit") { |a, b| Return_Node.new(a) }
      end

      ## Flytta?
      rule :op_assignment do
        match(:op_arithmetic, "=")
        match("=") { |a| a }
      end
      ## STATEMENT
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
