#!/usr/bin/env ruby

require 'rdparse'

class If_Stmt
  def initialize(_expr, _body)
    @expr = _expr
    @body = _body
  end

  def evaluate()
    
  end
end

class Op_Adder
  def initialize(_expr1, _expr2)
    @expr1 = _expr1
    @expr2 = _expr2
  end

  def evaluate()
    expr1_value = @expr1.evaluate()
    expr2_value = @expr2.evaluate()

    if not expr1_value.is_a? String and expr2_value.is_a? String
      return expr1_value + expr2_value
    end
  end
end
