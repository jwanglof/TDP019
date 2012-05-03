#!/usr/bin/env ruby

@@variableHash = {}

def hashLookup(var_name, hash_name)
  hash_name[var_name]
end

class If_Stmt
  def initialize(_expr, _body)
    @expr = _expr
    @body = _body
  end

  def evaluate()
    
  end
end

class Float_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    return @value
  end
end

class Integer_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    return @value
  end
end

class String_Node
  def initialize(_value)
    @value = _value
  end
  
  def evaluate()
    return @value
  end
end

class Print_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts @value.evaluate()
  end
end

class Variable_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    return hashLookup(@value, @@variableHash)
  end
end

class Return_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    return @value.evaluate()
  end
end

class Op_Arithmetic_Node
  def initialize(_operator, _operand1, _operand2)
    @operator = _operator
    @operand1 = _operand1
    @operand2 = _operand2
  end
    
  def evaluate()
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

class Op_Relational_Node
  def initialize(_operator, _value1, _value2)
    @operator = _operator
    @value1 = _value1
    @value2 = _value2
  end

  def evaluate()
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
    
  end
end
