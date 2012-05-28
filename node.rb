#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

@@variables =[{}] # All declared variables. Each index is a separate scope
@@functions = {} # Function names, their nodes and their parameters
@@scope = 0 # Current scope level (index used in @@variables)

@@ffHelper = false #Set to true to see parse flow

# SCOPE HANDLING ------------------------------->

def open_scope
  @@scope += 1
  @@variables.push({})
  ffMessenger("Opened a scope, now at level #{@@scope}") if @@ffHelper
end

def close_scope
  @@variables.pop
  @@scope -= 1
  ffMessenger("Closed a scope, now at level #{@@scope}") if @@ffHelper
end

def add_to_scope(name, value)
  current_scope = @@variables[@@scope]
  current_scope[name] = value
end

def lookup(identifier, hash)
  ffMessenger("Called lookup function") if @@ffHelper
  if hash == @@functions
    hash[identifier]
    
  elsif hash == @@variables
    i = @@scope
    while(i >= 0)
	    ffMessenger("Searching for \"#{identifier}\" at scope #{i}") if @@ffHelper
      
	    if @@variables[i].include? (identifier) then
        return @@variables[i][identifier]
	    else
        i -= 1
	    end
    end
    if @@variables[0][identifier] == nil
	    ffMessenger("There is no variable called #{identifier}.")
    end
  end
end

# END SCOPE HANDLING --------------------------->

def ffMessenger(str)
  print "flip/flop says: "; puts str
end

class Program_Node
  def initialize(_stmt_list)
    @stmt_list = _stmt_list
  end
  
  def evaluate()
    ffMessenger("Entered Program_Node") if @@ffHelper
    
    @stmt_list.each do
      |prog|
      prog.evaluate()
    end
  end
end

class Print_Node
  def initialize(_expr)
    @expr = _expr
  end
  
  def evaluate()
    ffMessenger("Entered Print_Node") if @@ffHelper

    puts @expr.evaluate()
  end
end

# Used to print a specific value of an array or a variable
class PrintSubscript_Node
  attr_accessor :name, :subscript

  def initialize(_name, _int)
    @name = _name
    @subscript = _int
  end
  
  def evaluate()
    ffMessenger("Entered PrintSubscript_Node") if @@ffHelper
    
    value = lookup(@name.value, @@variables)
    
    if @subscript.evaluate() == 0 then
      ffMessenger("#{@subscript.evaluate()} is not a valid subscript value.")
      
    elsif value.class == String || value.class == Array
      if @subscript.evaluate() <= value.size
        puts value[@subscript.evaluate() - 1]
      else
        ffMessenger("#{@subscript.evaluate()} is not a valid subscript value.")
      end
      
    elsif value.class == Fixnum
      ffMessenger("It is not possible to subscript an Integer.")
      
    elsif value.class == Float
      ffMessenger("It is not possible to subscript a Float.")

    else
      puts "Oh, what do we have here? A #{value.class}. Guess we forgot to implement subscripting for that."
      
    end
  end
end

# Assign a value to a variable
class AssignValue_Node
  attr_accessor :var_name, :var_expr

  def initialize(_var_name, _var_expr)
    @var_name = _var_name
    @var_expr = _var_expr
  end

  def evaluate()
    ffMessenger("Entered AssignValue_Node") if @@ffHelper

    @@variables[@@scope][@var_name.value] = @var_expr.evaluate()

    ffMessenger("This is the current variable stack: #{@@variables}") if @@ffHelper
  end
end

# Used for if-else and if-elseif statements
class IfElse_Node
  attr_accessor :if_body, :else_body, :expressions

  def initialize(_if_body, _else_body, _expressions)
    @if_body = _if_body
    @else_body = _else_body
    @expressions = _expressions
  end

  def evaluate()
    ffMessenger("Entered IfElse_Node") if @@ffHelper

    if @expressions.evaluate() then
      @if_body.each do
        |if_stmt|
        if_stmt.evaluate()
      end
    else
      if @else_body.class == Array then
        @else_body.each do
          |else_stmt|
          else_stmt.evaluate()
        end
      else
        @else_body.evaluate()
      end
    end
  end
end

# Used only for the if-statement
class If_Node
  attr_accessor :if_body, :expressions
  
  def initialize(_if_body, _expressions)
    @if_body = _if_body
    @expressions = _expressions
  end
  
  def evaluate()
    ffMessenger("Entered If_Node") if @@ffHelper

    if @expressions.evaluate() then
      @if_body.each do
        |if_stmt|
        if_stmt.evaluate()
      end
    end
  end
end

class AddOne_Node
  attr_accessor :var_name

  def initialize(_var_name)
    @var_name = _var_name
  end
  
  def evaluate()
    ffMessenger("Entered AddOne_Node") if @@ffHelper
    
    old_value = lookup(@var_name.value, @@variables).to_i
    new_value = old_value + 1
    
    i = @@scope
    while(i >= 0)
      ffMessenger("Looking to add 1 to \"#{var_name.value}\" at scope #{i}") if @@ffHelper

      if @@variables[i].include? (@var_name.value) then
        @@variables[i][@var_name.value] = new_value
        break
      else
        i -= 1
      end
    end
    
    ffMessenger("Added 1 to #{var_name.value} at scope #{i}") if @@ffHelper
    
  end
end

class SubtractOne_Node
  attr_accessor :var_name
  
  def initialize(_var_name)
    @var_name = _var_name
  end
  
  def evaluate()
    ffMessenger("Entered SubtractOne_Node") if @@ffHelper
    
    old_value = lookup(@var_name.value, @@variables).to_i
    new_value = old_value - 1
    
    i = @@scope
    while(i >= 0)
      ffMessenger("Looking to subtract 1 from \"#{var_name.value}\" at scope #{i}") if @@ffHelper
      
      if @@variables[i].include? (@var_name.value) then
        @@variables[i][@var_name.value] = new_value
        break
      else
        i -= 1
	end
    end
    
    ffMessenger("Subtracted 1 from #{var_name.value}") if @@ffHelper
    
  end
end

# Compound_Node is used for several different operations
# It is used for predicate expressions and arithmetic expression
class Compound_Node
  attr_accessor :operator, :value1, :value2
  
  def initialize(_operator, _value1, _value2)
    @operator = _operator
    @value1 = _value1
    @value2 = _value2
  end
  
  def evaluate()
    ffMessenger("Entered Compound_Node") if @@ffHelper
    
    if value1.evaluate().class == String and value2.evaluate().class == String
      instance_eval("'#{value1.evaluate()}' #{operator} '#{value2.evaluate()}'")
    end
    
    instance_eval("#{value1.evaluate()} #{operator} #{value2.evaluate()}")
  end
end

# Returns true or false depending on the value
class NotTest_Node
  def initialize(_value)
    @value = _value
  end
  
  def evaluate()
    ffMessenger("Entered NotTest_Node") if @@ffHelper    
    
    return (not @value.evaluate())
  end
end

class ArrayNew_Node
  attr_accessor :array_name, :values
  
  def initialize(_array_name, _values)
    @array_name = _array_name
    @values = _values
  end
  
  def evaluate()
    ffMessenger("Entered ArrayNew_Node") if @@ffHelper
    
    r_array = []
    @values.each do
      |array_values|
      r_array << array_values.evaluate()
      @@variables[@@scope][@array_name.value] = r_array
      
      puts @@variables if @@ffHelper
    end
  end
end

=begin NOT IMPLEMENTED YET
class ArrayIndex_Node
  def initialize(_array_name, _get_index)
    @array_name = _array_name
    @get_index = _get_index
  end

  def evaluate()
    ffMessenger("Entered ArrayIndex_Node") if @@ffHelper

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
=end

class ArithmeticExpr_Node
  def initialize(_expr)
    @expr = _expr
  end

  def evaluate()
    ffMessenger("Entered ArithmeticExpr_Node") if @@ffHelper
    
    return @expr.evaluate()
  end

end

# NOT PROPERLY IMPLEMENTED YET. SHOULD RETURN 'yes' AND 'no'.
class Boolean_Node
  def initialize(_expr)
    @expr = _expr
  end
  
  def evaluate()
    ffMessenger("Entered Boolean_Node") if @@ffHelper
    
    case @expr
    when 'yes'
      return true
    when 'no'
      return false
    end
  end
end

class Integer_Node
  def initialize(_value)
    @value = _value
  end
  
  def evaluate()
    ffMessenger("Entered Integer_Node") if @@ffHelper
    
    return @value
  end
end

class Float_Node
  def initialize(_value)
    @value = _value
  end

  def evaluate()
    ffMessenger("Entered Float_Node") if @@ffHelper
    return @value
  end
end

class String_Node
  def initialize(_value)
    @value = _value
  end
  
  def evaluate()
    ffMessenger("Entered String_Node") if @@ffHelper
    
    return @value.delete "\"\'" # Deletes quotation marks to prevent subscript issues
  end
end

class Variable_Node
  attr_accessor :var

  def initialize(_var)
    @var = _var
  end
  
  def evaluate()
    ffMessenger("Entered Variable_Node") if @@ffHelper
    
    return lookup(@var, @@variables)

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
    ffMessenger("Entered LoopFor_Node") if @@ffHelper

    open_scope()
    @assign_stmt.evaluate()
    ffMessenger("Created and assigned loop variable") if @@ffHelper

    while @or_test.evaluate() do
	ffMessenger("Executing loop statements...") if @@ffHelper
	@stmt_list.each do
	    |stmt|
	    stmt.evaluate()
	end
	@expr.evaluate()
    end
    close_scope()
  end
end

class LoopWhile_Node
  attr_accessor :stmt_list, :expressions
  
  def initialize(_stmt_list, _expressions)
    @stmt_list = _stmt_list
    @expressions = _expressions
  end
  
  def evaluate()
    ffMessenger("Entered LoopWhile_Node") if @@ffHelper
    
    open_scope()
    while @expressions.evaluate() do
      @stmt_list.each do
        |stmt|
        stmt.evaluate()
      end
    end
    close_scope()
  end
end

class FunctionDeclare_Node
    attr_accessor :stmt_list, :identifier, :param_list
  
  def initialize(_stmt_list, _identifier, _param_list)
    @stmt_list = _stmt_list
    @identifier = _identifier
    @param_list = _param_list
    end
  
  def evaluate()
    ffMessenger("Entered FunctionDeclare_Node") if @@ffHelper
    
    ffMessenger("param_list: #{@param_list.inspect}") if @@ffHelper
    
    @@functions[@identifier.value] = [@stmt_list, @param_list]
  end
end

class FunctionCall_Node
  attr_accessor :name, :arg_list
  
  def initialize(_name, _arg_list)
    @name = _name
    @arg_list = _arg_list
  end
  
  def evaluate()
    ffMessenger("Entered FunctionCall_Node") if @@ffHelper
    
    open_scope()
    
    ffMessenger("These are the #{@name.value} parameters:") if @@ffHelper
    
    if @@functions[@name.value][1] != nil then
	    ffMessenger("#{@@functions[@name.value][1].inspect}") if @@ffHelper
    else
	    ffMessenger("#{@name.value} has no parameters.") if @@ffHelper
    end
    
    params = @@functions[@name.value][1]
    if params.size != @arg_list.size then
      ffMessenger("Passed #{@arg_list.size} arguments to #{@name.value}, but #{params.size} are required.")
    end
    
    # Add arguments to scope
    params.each_with_index do |param, i|
      name = param.value
      arg = @arg_list[i]
      add_to_scope(name, arg.evaluate)
    end
    
    # Executes the function body
    stmt_list = @@functions[@name.value][0]
    stmt_list.each do |stmt|
	    stmt.evaluate()
    end
    ffMessenger("The function body executed ok.") if @@ffHelper
    
    close_scope()
  end
end
