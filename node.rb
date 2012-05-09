#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

@@variableHash = {}
@@functionHash = {}
@@arrayHash = {}

@@logLevel = false

def hashLookup(var_name, hash_name)
  hash_name[var_name]
end

def hashChange(var_name, hash_name, new_value)
  hash_name[var_name] = new_value
end

class ArrayNew_Node
  attr_accessor :array_name, :values

  def initialize(_array_name, _values)
    @array_name = _array_name
    @values = _values
  end

  def evaluate()
    puts "-----> Entered ArrayNew_Node" if @@logLevel

    r_array = []
    @values.each do
      |g|
      r_array << g.evaluate()
     @@arrayHash[@array_name.value] = r_array
    end
    # @array_name.each do
    #   if not @@arrayHash.include? (array_name.value)
    #     puts array_name.value
    #   end
    # end
  end
end

class ArrayIndex_Node
  def initialize(_array_name, _get_index)
    @array_name = _array_name
    @get_index = _get_index
  end

  def evaluate()
    puts "-----> Entered ArrayIndex_Node" if @@logLevel

    puts @@arrayHash[@array_name]
  end
end

class ArraySize_Node
  def initialize(_array_name)
    @array_name = _array_name
  end

  def evaluate()
    puts @array_name.value
  end
end

class Float_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Float_Node" if @@logLevel
    return @value
  end
end

class Integer_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Integer_Node" if @@logLevel
    
    return @value
  end
end

class String_Node
  def initialize(_value)
    @value = _value
  end
  
  def evaluate()
    puts "-----> Entered String_Node" if @@logLevel

    return @value
  end
end

class Print_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Print_Node" if @@logLevel

    # @value.each do
    #   |a|
    #   puts a.evaluate()
    # end
    puts @value.evaluate()
  end
end

class PrintSubscript_Node
  attr_accessor :name, :subscript

  def initialize(_name, _int)
    @name = _name
    @subscript = _int
  end
  
  def evaluate()
    puts "-----> Entered PrintSubscript_Node" if @@logLevel

    if @subscript.evaluate() == 0 then
      puts "Not a valid value"
    elsif @@arrayHash.include? (@name.value) then
      _counter = 1
      @@arrayHash[@name.value].each do
        |a|
        if _counter == @subscript.evaluate() then
          puts a
        end
        _counter += 1
      end
    elsif @@variableHash.include? (@name.value) then
      
      puts @@variableHash[@name.value][@subscript.evaluate()]
    end
  end
end

class Variable_Node
  attr_accessor :value

  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Variable_Node" if @@logLevel

    if @@variableHash.include? (@value) then
      return @@variableHash[@value]
    elsif @@arrayHash.include? (@value) then
      return @@arrayHash[@value]
    else
      return "Nope!"
    end
  end
end

class ArithmeticExpr_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered ArithmeticExpr_Node" if @@logLevel

    return @value.evaluate()
  end
end

class Compound_Node
  attr_accessor :operator, :value1, :value2

  def initialize(_operator, _value1, _value2)
    @operator = _operator
    @value1 = _value1
    @value2 = _value2
  end

  def evaluate()
    puts "-----> Entered Compound_Node" if @@logLevel

    if value1.evaluate().class == String and value2.evaluate().class == String
      instance_eval("'#{value1.evaluate()}' #{operator} '#{value2.evaluate()}'")
    end

    instance_eval("#{value1.evaluate()} #{operator} #{value2.evaluate()}")
  end
end

# Fixa så det står no och yes ist för true och false
class Boolean_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Boolean_Node" if @@logLevel

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
    puts "-----> Entered AssignValue_Node" if @@logLevel

    @@variableHash[@var_name.value] = @var_value.evaluate()
  end
end

class AddOne_Node
  attr_accessor :var_name

  def initialize(_var_name)
    @var_name = _var_name
  end

  def evaluate()
    puts "-----> Entered AddOne_Node" if @@logLevel

    old_value = @@variableHash[@var_name.value].to_i
    new_value = old_value+1
    @@variableHash[@var_name.value] = new_value
  end
end

class SubtractOne_Node
  attr_accessor :var_name

  def initialize(_var_name)
    @var_name = _var_name
  end

  def evaluate()
    puts "-----> Entered SubtractOne_Node" if @@logLevel

    old_value = @@variableHash[@var_name.value].to_i
    new_value = old_value-1
    @@variableHash[@var_name.value] = new_value
  end
end

class If_Node
  attr_accessor :if_body, :expressions

  def initialize(_if_body, _expressions)
    @if_body = _if_body
    @expressions = _expressions
  end

  def evaluate()
    puts "-----> Entered If_Node" if @@logLevel

    if @expressions.evaluate() then
      @if_body.each do
        |a|
        a.evaluate()
      end
    end
  end
end

class IfElse_Node
  attr_accessor :if_body, :else_body, :expressions

  def initialize(_if_body, _else_body, _expressions)
    @if_body = _if_body
    @else_body = _else_body
    @expressions = _expressions
  end

  def evaluate()
    puts "-----> Entered IfElse_Node" if @@logLevel

    if @expressions.evaluate() then
      @if_body.each do
        |a|
        a.evaluate()
      end
    else
      if @else_body.class == Array then
        @else_body.each do
          |b|
          b.evaluate()
        end
      else
        @else_body.evaluate()
      end
    end
  end
end

class LoopWhile_Node
  attr_accessor :stmt_list, :expressions

  def initialize(_stmt_list, _expressions)
    @stmt_list = _stmt_list
    @expressions = _expressions
  end

  def evaluate()
    puts "-----> Entered LoopWhile_Node" if @@logLevel

    while @expressions.evaluate() do
      @stmt_list.each do
        |a|
        a.evaluate()
      end
    end
  end
end

class LoopFor_Node
  attr_accessor :stmt_list, :assign_stmt, :or_test, :expr

  def initialize(_stmt_list, _assign_stmt, _or_test, _expr)
    @stmt_list = _stmt_list
    @assign_stmt = _assign_stmt
    @or_test = _or_test
    @expr = _expr
  end

  def evaluate()
    puts "-----> Entered LoopFor_Node" if @@logLevel

    # Add the variable to the variable hash and assign a value
    var_name = @assign_stmt.var_name.value
    var_orig_value = assign_stmt.evaluate()
    @@variableHash[var_name] = var_orig_value

    while not @or_test.evaluate() do
      # Add 1 to the variable
      @@variableHash[var_name] = @@variableHash[var_name]+1

      @stmt_list.each do
        |a|
        a.evaluate()
      end
    end
  end
end

class Program_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered Program_Node" if @@logLevel

    @value.each do
      |a|
      a.evaluate()
    end
  end
end

class NotTest_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    puts "-----> Entered NotTest_Node" if @@logLevel    

    return (not @value.evaluate())
  end
end 
