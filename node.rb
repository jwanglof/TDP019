#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

@@variableHash = {}
@@functionHash = {}

def hashLookup(var_name, hash_name)
  hash_name[var_name]
end

def hashChange(var_name, hash_name, new_value)
  hash_name[var_name] = new_value
end

class If_Stmt
  def initialize(_expr, _body)
    @expr = _expr
    @body = _body
  end

  def evaluate()
    puts "-----> Entered If_Node"
  end
end

class Float_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Float_Node"
    return @value
  end
end

class Integer_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Integer_Node"
    return @value
  end
end

class String_Node
  def initialize(_value)
    @value = _value
  end
  
  def evaluate()
    puts "-----> Entered String_Node"
    return @value
  end
end

class Print_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Print_Node"
    puts @value.evaluate()
  end
end

class Variable_Node
  attr_accessor :value

  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Variable_Node"
    return hashLookup(@value, @@variableHash)
  end
end

class Return_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Return_Node"
    return @value.evaluate()
  end
end

# class Op_Arithmetic_Node
class ArithmeticExpr_Node
  def initialize(_operator, _operand1, _operand2)
    @operator = _operator
    @operand1 = _operand1
    @operand2 = _operand2
  end
    
  def evaluate()
    puts "-----> Entered ArithmeticExpr_Node"
    case @operator
    when '+'
      return @operand1.evaluate() + @operand2.evaluate()
    when '-'
      return @operand1.evaluate() - @operand2.evaluate()
    when '*'
      return @operand1.evaluate() * @operand2.evaluate()
    when '/'
      return @operand1.evaluate() / @operand2.evaluate()
    when '%'
      return @operand1.evaluate() % @operand2.evaluate()
    end
  end
end

# class Op_Relational_Node
class PredicatExpr_Node
  attr_accessor :operator, :value1, :value2
  
  def initialize(_operator, _value1, _value2)
    @operator = _operator
    @value1 = _value1
    @value2 = _value2
  end

  def evaluate()
    puts "-----> Entered PredicatExpr_Node"
    case @operator
    when '<'
      return @value1.evaluate() < @value2.evaluate()
    when '<='
      return @value1.evaluate() <= @value2.evaluate()
    when '>'
      return @value1.evaluate() > @value2.evaluate()
    when '>='
      return @value1.evaluate() >= @value2.evaluate()
    when '=='
      return @value1.evaluate() == @value2.evaluate()
    when '!='
      return @value1.evaluate() != @value2.evaluate()
    end
  end
end

class Loop_Node
  def initialize(_statement_list, _expression_pred, _assign_statement = "", _statement = "")
    @statement_list = _statement_list
    @expression_pred = _expression_pred
    @assign_statement = _assign_statement
    @statement = _statement
  end

  def evaluate()
    puts "-----> Entered Loop_Node"
  end
end

# Fixa så det står no och yes ist för true och false
class Boolean_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Boolean_Node"
    case @value
    when 'yes'
      return true
    when 'no'
      return false
    end
  end
end

class AssignValue_Node
  attr_accessor :var_name, :var_value

  def initialize(_var_name, _var_value)
    @var_name = _var_name
    @var_value = _var_value
  end

  def evaluate()
    puts "-----> Entered AssignValue_Node"
    # if not @@variableHash.include? (@var_name.value)
    @@variableHash[@var_name.value] = @var_value.evaluate()
    # else
    #   puts "A variable called #{@var_name.value} already exists."
    # end
  end
end

class FunctionDec_Node
  attr_accessor :statement_list, :identifier, :parameter_list

  def initialize(_statement_list, _identifier, _parameter_list)
    @statement_list = _statement_list
    @identifier = _identifier
    @parameter_list = _parameter_list
  end

  def evaluate()
    puts "-----> Entered FunctionDec_Node"

    puts identifier.value
#    if not @@functionHash.include? (identifier.value)
  end
end
