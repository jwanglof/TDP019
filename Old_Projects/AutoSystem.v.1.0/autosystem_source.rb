#!/usr/bin/env ruby

require "rdparser"
require "win32ole"

$autoit = WIN32OLE.new("AutoItX3.Control")

class IfStatement
  def initialize(_expr, _body)
    @expr = _expr
    @body = _body
  end
  
  def evaluate()
    if @expr.evaluate() == true
      @body.evaluate()
    end
  end
end

class RepStatementIntToInt
  def initialize(ident, int_start, int_end, body)
    @identifier = ident
    @int_start = int_start
    @int_end = int_end
    @body = body
  end
  
  def evaluate()
    $current_scope += 1
     $current_rep += 1
     
     #puts "Current Scope(when adding new function): #{$current_scope}"
     
     #Creates the hash container where all the variables for this rep will be stored
     $variables[$current_scope] = Hash.new()
     
     #puts "Variables for rep #{$current_scope}: #{$variables[$current_scope]}."
 
     #start the for loop (int) from start to end
     for i in @int_start.evaluate()..@int_end.evaluate()
        $variables[$current_scope][@identifier.evaluate()] = i#set the indexing variable of the current loop to the corresponding value
        
        value = @body.evaluate()
        if value.class == Array
             if value[0] == "break"
               $current_scope -= 1
               $current_rep -= 1
                         
               break
             end
         end
     end
 
     #$current_scope = old_scope
     $current_scope -= 1
     $current_rep -= 1
  end
end

class RepStatementList
  def initialize(ident, body, variable_list)
    @identifier = ident
    @body = body
    @variable_list = variable_list
  end
  
  def evaluate()
    $current_scope += 1
    $current_rep += 1
#    puts "Current Scope(when adding new function): #{$current_scope}"
    
    #Creates the hash container where all the variables for this rep will be stored
    $variables[$current_scope] = Hash.new()
    
 #   puts "Variables for rep #{$current_scope}: #{$variables[$current_scope]}."

    #start the for loop (list)

    for i in @variable_list.evaluate()
       $variables[$current_scope][@identifier.evaluate()] = i#set the indexing variable of the current loop to the corresponding list-index-value
       
        value = @body.evaluate()
        if value.class == Array
            if value[0] == "break"
              $current_scope -= 1
              $current_rep -= 1
              
              break
            end
        end
    end

    $current_scope -= 1
    $current_rep -= 1
  end
end

class RepStatementWhile
  def initialize(body ,expr)
    @body = body
    @expr = expr
  end
  
  def evaluate()
    #old_scope = $current_scope
    #$current_scope = "rep#{$current_rep}"
    $current_scope += 1
    $current_rep += 1
    #puts "Current Scope(when adding new function): #{$current_scope}"
    
    #Creates the hash container where all the variables for this rep will be stored
    $variables[$current_scope] = Hash.new()
    
    #puts "Variables for rep #{$current_scope}: #{$variables[$current_scope]}."

    while @expr.evaluate()
      value = @body.evaluate()
      if value.class == Array
        if value[0] == "break"
          $current_scope -= 1
          $current_rep -= 1
          
          break
        end       
      end
    end

    #$current_scope = old_scope
    $current_scope -= 1
    $current_rep -= 1
  end
end

class ListDefinition
  def initialize(elements)
    @elements = elements
  end
  
  def evaluate()
    if @elements!=nil
    return @elements.evaluate()
    else
    return []
    end
  end
end

class Elements
  def initialize(element,elements)
    @element = element
    @elements = elements
  end
  
  def evaluate()
    if @elements!=nil
    return @elements.evaluate() + @element.evaluate()
    else
    return @element.evaluate()
    end
  end
end

class Element
  def initialize(element)
    @element = element
  end
  
  def evaluate()
    return [@element.evaluate()]
  end
end

class ListCall
  def initialize(var_name, list_brackets)
    @var_name = var_name
    @list_brackets = list_brackets
  end

  def evaluate()
    if @list_brackets!=nil
      current_array_dim = $variables[$current_scope][@var_name.evaluate()]
      for item in @list_brackets.evaluate()
        current_array_dim = current_array_dim[item]
      end
      return current_array_dim
    else
      return nil
    end
  end
end

class ListBrackets
  def initialize(brackets,bracket)
    @brackets = brackets
    @bracket = bracket
  end
  
  def evaluate()
    if @brackets!=nil
    return @brackets.evaluate() + @bracket.evaluate()
    else
    return @bracket.evaluate()
    end
  end
end

class ListBracket
  def initialize(bracket)
    @bracket = bracket
  end
  
  def evaluate()
    return [@bracket.evaluate()]
  end
end

class AddQuickAssignStatement
  def initialize(var_name, calc_expr)
    @var_name = var_name
    @calc_expr = calc_expr
  end
  
  def evaluate()
    scope = $current_scope
    until scope < 0
      if $variables[scope].has_key?(@var_name.evaluate()) == true      
        expr_class = @calc_expr.evaluate().class()
        var_class = $variables[scope][@var_name.evaluate()].class()
          
        if var_class != String and expr_class != String
          $variables[scope][@var_name.evaluate()] = $variables[scope][@var_name.evaluate()] + @calc_expr.evaluate()
        elsif var_class == String and expr_class == String
          $variables[scope][@var_name.evaluate()] = $variables[scope][@var_name.evaluate()] + @calc_expr.evaluate()
        elsif var_class == String and expr_class != String
          $variables[scope][@var_name.evaluate()] = $variables[scope][@var_name.evaluate()] + @calc_expr.evaluate().to_s
        elsif var_class != String and expr_class == String
          $variables[scope][@var_name.evaluate()] = $variables[scope][@var_name.evaluate()].to_s + @calc_expr.evaluate()
        else
          raise "AutoSystem :: The variable type or value type are incorrect. VariableType(#{var_class}) ExprType(#{expr_class})"
        end
        break
        #Puts "Variable list: #{$variables[scope]}"
      elsif scope == 0
        raise "AutoSystem :: The variable '#{@var_name.evaluate()}' does not exist."
      end
        scope -= 1
    end
  end
end

class SubQuickAssignStatement
  def initialize(var_name, calc_expr)
    @var_name = var_name
    @calc_expr = calc_expr
  end
  
  def evaluate()
    scope = $current_scope
      until scope < 0
        if $variables[scope].has_key?(@var_name.evaluate()) == true      
          expr_class = @calc_expr.evaluate().class()
          var_class = $variables[scope][@var_name.evaluate()].class()
            
          if var_class != String and expr_class != String
            $variables[scope][@var_name.evaluate()] = $variables[scope][@var_name.evaluate()] - @calc_expr.evaluate()
          else
            raise "AutoSystem :: The variable type or value type are incorrect. VariableType(#{var_class}) ExprType(#{expr_class})"
          end
          break
          #Puts "Variable list: #{$variables[scope]}"
        elsif scope == 0
          raise "AutoSystem :: The variable '#{@var_name.evaluate()}' does not exist."
        end
          scope -= 1
      end    
  end
end

class MultiQuickAssignStatement
  def initialize(var_name, calc_expr)
    @var_name = var_name
    @calc_expr = calc_expr
  end
  
  def evaluate()
    scope = $current_scope
    until scope < 0
      if $variables[scope].has_key?(@var_name.evaluate()) == true      
        expr_class = @calc_expr.evaluate().class()
        var_class = $variables[scope][@var_name.evaluate()].class()
          
        if var_class != String and expr_class != String
          $variables[scope][@var_name.evaluate()] = $variables[scope][@var_name.evaluate()] * @calc_expr.evaluate()
        elsif var_class == String and expr_class != String
          $variables[scope][@var_name.evaluate()] = $variables[scope][@var_name.evaluate()] * @calc_expr.evaluate()
        else
          raise "AutoSystem :: The variable type or value type are incorrect. VariableType(#{var_class}) ExprType(#{expr_class})"
        end
        break
        #Puts "Variable list: #{$variables[scope]}"
      elsif scope == 0
        raise "AutoSystem :: The variable '#{@var_name.evaluate()}' does not exist."
      end
        scope -= 1
    end
  end
end

class DivQuickAssignStatement
  def initialize(var_name, calc_expr)
    @var_name = var_name
    @calc_expr = calc_expr
  end
  
  def evaluate()
    scope = $current_scope
    until scope < 0
      if $variables[scope].has_key?(@var_name.evaluate()) == true      
        expr_class = @calc_expr.evaluate().class()
        var_class = $variables[scope][@var_name.evaluate()].class()
          
        if var_class != String and expr_class != String
          $variables[scope][@var_name.evaluate()] = $variables[scope][@var_name.evaluate()] / @calc_expr.evaluate()
        elsif var_class == String and expr_class != String
          $variables[scope][@var_name.evaluate()] = $variables[scope][@var_name.evaluate()][0..($variables[scope][@var_name.evaluate()].length-1) / @calc_expr.evaluate()]
        else
          raise "AutoSystem :: The variable type or value type are incorrect. VariableType(#{var_class}) ExprType(#{expr_class})"
        end
        break
        #Puts "Variable list: #{$variables[scope]}"
      elsif scope == 0
        raise "AutoSystem :: The variable '#{@var_name.evaluate()}' does not exist."
      end
        scope -= 1
    end
  end
end

class ModQuickAssignStatement
  def initialize(var_name, calc_expr)
    @var_name = var_name
    @calc_expr = calc_expr
  end
  
  def evaluate()
    scope = $current_scope
    until scope < 0
      if $variables[scope].has_key?(@var_name.evaluate()) == true      
        expr_class = @calc_expr.evaluate().class()
        var_class = $variables[scope][@var_name.evaluate()].class()
          
        if var_class != String and expr_class != String
          $variables[scope][@var_name.evaluate()] = $variables[scope][@var_name.evaluate()] % @calc_expr.evaluate()
        else
          raise "AutoSystem :: The variable type or value type are incorrect. VariableType(#{var_class}) ExprType(#{expr_class})"
        end
        break
        #Puts "Variable list: #{$variables[scope]}"
      elsif scope == 0
        raise "AutoSystem :: The variable '#{@var_name.evaluate()}' does not exist."
      end
        scope -= 1
    end    
  end
end

class Float_Type
  def initialize(_float)
    @value = _float
  end
  
  def evaluate()
    return @value
  end
end

class Integer_Type
  def initialize(_integer)
    @value = _integer
  end
  
  def evaluate()
    return @value
  end
end

class String_Type
  def initialize(_string)
    @value = _string
  end
  
  def evaluate()
    return @value
  end
end

class Bool_Type
  def initialize(_bool)
    @value = _bool
  end
  
  def evaluate()
    return @value
  end
end


class Statement
  def initialize(_stmt)
    @stmt = _stmt
  end
  
  def evaluate()
    @stmt.evaluate()
  end
end


class AddCalculateExpr
  def initialize(_expr1, _expr2)
    @expr1 = _expr1
    @expr2 = _expr2
  end
  
  def evaluate()
    expr1_class = @expr1.evaluate().class()
    expr2_class = @expr2.evaluate().class()

    if expr1_class != String and expr2_class != String
    	return @expr1.evaluate() + @expr2.evaluate()
    elsif expr1_class == String and expr2_class == String
    	return @expr1.evaluate() + @expr2.evaluate()
    elsif expr1_class == String and expr2_class != String
        return @expr1.evaluate() + @expr2.evaluate().to_s
    elsif expr1_class != String and expr2_class == String
        return @expr1.evaluate().to_s + @expr2.evaluate()
    end
  end
end


class SubCalculateExpr
  def initialize(_expr1, _expr2)
    @expr1 = _expr1
    @expr2 = _expr2
  end
    
  def evaluate()
    expr1_class = @expr1.evaluate().class()
    expr2_class = @expr2.evaluate().class()

    if expr1_class != String and expr2_class != String
    	return @expr1.evaluate() - @expr2.evaluate()
    end
  end
end


#todo, negative multi ska inte fungera med strings, t.ex "hej" * (-3)
class MultiCalculateExpr
  def initialize(_expr1, _expr2)
    @expr1 = _expr1
    @expr2 = _expr2
  end
  
  def evaluate()
    expr1_class = @expr1.evaluate().class()
    expr2_class = @expr2.evaluate().class()

    if expr1_class != String and expr2_class != String
    	return @expr1.evaluate() * @expr2.evaluate()
    elsif expr1_class == String and expr2_class != String
    	return @expr1.evaluate() * @expr2.evaluate()
    end
  end
end


class DivCalculateExpr
  def initialize(_expr1, _expr2)
    @expr1 = _expr1
    @expr2 = _expr2
  end
  
  def evaluate()
    expr1_class = @expr1.evaluate().class()
    expr2_class = @expr2.evaluate().class()
    
    if expr1_class != String and expr2_class != String
    	return @expr1.evaluate() / @expr2.evaluate()
    elsif expr1_class == String and expr2_class != String
    	return @expr1.evaluate()[0..(@expr1.evaluate().length-1) / @expr2.evaluate()]
    end
  end
end

class ModCalculateExpr
  def initialize(_expr1, _expr2)
    @expr1 = _expr1
    @expr2 = _expr2
  end
  
  def evaluate()
    expr1_class = @expr1.evaluate().class()
    expr2_class = @expr2.evaluate().class()
    
    if expr1_class != String and expr2_class != String
    	return @expr1.evaluate() % @expr2.evaluate()
    end
  end
end

class NegativeAtom
  def initialize(_atom)
    @atom = _atom
  end
  
  def evaluate()
    expr_class = @atom.evaluate().class()
    
    if expr_class == String
    	return @atom.evaluate().reverse
    else
        return -@atom.evaluate()
    end
  end
end

class Expression
  def initialize(_expr)
    @expr = _expr
  end
  
  def evaluate()
    return @expr.evaluate()
  end
end


class Relation_Expr
  def initialize(_expr1, _op = nil, _expr2 = nil)
    @op = _op
    @expr1 = _expr1
    @expr2 = _expr2
  end
  
  def evaluate()
    if @op == nil and @expr2 == nil
      return @expr1
    else
      if @op.to_s == "<"
        return (@expr1.evaluate() < @expr2.evaluate())
      elsif @op.to_s == ">"
        return (@expr1.evaluate() > @expr2.evaluate())
      elsif @op.to_s == "<="
        return (@expr1.evaluate() <= @expr2.evaluate())
      elsif @op.to_s == ">="
        return (@expr1.evaluate() >= @expr2.evaluate())
      elsif @op.to_s == "=="
        return (@expr1.evaluate() == @expr2.evaluate())
      elsif @op.to_s == "!="
        return (@expr1.evaluate() != @expr2.evaluate())
      else
        raise "AutoSystem :: Expected '<, >, <=, >=, ==, !=' got '#{@op}'"
      end
    end     
  end
end


class Logical_Expr
  def initialize(_expr1, _op = nil, _expr2 = nil)
    @op = _op
    @expr1 = _expr1
    @expr2 = _expr2
  end
  
  def evaluate()
    if @op == nil and @expr2 == nil
      return @expr1.evaluate()
    else
      if @op.to_s == "and"
        return (@expr1.evaluate() and @expr2.evaluate())
      elsif @op.to_s == "or"
        return (@expr1.evaluate() or @expr2.evaluate())
      else
        raise "AutoSystem :: Expected 'and, or' got '#{@op}'"
      end
    end
  end
end

class Not_Expr
  def initialize(_expr)
    @expr = _expr
  end
  
  def evaluate()
    return (not @expr.evaluate())
  end
end

class SimpleStatement
  def initialize(_stmt)
    @stmt = _stmt
  end
  
  def evaluate()
    value = @stmt.evaluate()
    
    #Check if last statement runned was
    if value.class == Array
      if value[0] == "return"
        return value
      elsif value[0] == "break"
        return value
      end
    end
  end
end

class StatementList
  def initialize(_stmt, _stmts = nil)
    @stmt = _stmt
    @stmts = _stmts
  end
  
  def evaluate()
    if @stmts == nil
      #Look for "return" or "break" statement
      value = @stmt.evaluate()
      if value.class == Array
        if value[0] == "return"
          return value
        elsif value[0] == "break"
          return value
        end
      end
      
    else
    #Look for "return" or "break" statement
      value = @stmt.evaluate()
      if value.class == Array
        if value[0] == "return"
          return value
        elsif value[0] == "break"
          return value
        end
      end
        
  #Look for "return" or "break" statement
      value = @stmts.evaluate()
      if value.class == Array
        if value[0] == "return"
          return value
        elsif value[0] == "break"
          return value
        end
      end
    end
  end
end

class Program
  def initialize(_stmt_list)
    @stmt_list = _stmt_list
    evaluate()
  end
  
  def evaluate()
    #puts "End value: #{@stmt_list.evaluate()}"
    @stmt_list.evaluate()
  end
end

class Identifier
  def initialize(_id_name)
    @id_name = _id_name
  end
  
  def evaluate()
    @id_name
  end
end


class AssignStatement
  def initialize(_var_name, _value)
    @var_name = _var_name
    @value = _value
  end
  
  def evaluate()
    #puts "Current Scope(when adding new variable): #{$current_scope}"
    $variables[$current_scope][@var_name.evaluate()] = @value.evaluate()
    #puts "Variable List: #{$variables[$current_scope]}"
  end
end


class VariableCall
  def initialize(_var_name)
    @var_name = _var_name
  end
  
  def evaluate()
    scope = $current_scope
    
    #Checks if another scope Element needs to be added for the $function Array.
    if $variables.length() < $current_scope+1
      $variables[$current_scope] = Hash.new()
    end
    
    until scope < 0
      if $variables[scope].has_key?(@var_name.evaluate()) == true
        #puts "variable found in current scope"
        return $variables[scope][@var_name.evaluate()]
      elsif scope == 0
       #puts "no variables found"
       puts "Variables #{$variables[$current_scope].keys()}."
       raise "AutoSystem :: Variable '#{@var_name.evaluate()}' does not exist in current scope'(#{$current_scope})'"
      end
      
      scope -= 1
    end
  end
end


class Parameters
  def initialize(_parameter, _parameters = nil)
    @parameters = _parameters
    @parameter = _parameter
    @parameter_list = nil
  end
  
  def evaluate()
    if @parameters != nil
      @parameter_list = @parameters.evaluate() + @parameter.evaluate()
      return @parameter_list
    else
      @parameter_list = @parameter.evaluate()
      return @parameter_list     
    end
  end
end


class Parameter
  def initialize(_parameter)
    @parameter = _parameter
  end
  
  def evaluate()
    return [@parameter.evaluate()]
  end
end


class FunctionDef
  def initialize(_func_name, _body, _parameter_list = nil)
    @func_name = _func_name
    @body = _body
    @parameter_list = _parameter_list
  end
  
  def evaluate()
    #$current_scope += 1
    #puts "Current Scope(when adding new function): #{$current_scope}"
    #Checks if another scope Array needs to be added for the $function Array.
    if $functions.length() < $current_scope+5
      $current_scope.upto($current_scope+5 - $functions.length()) {|x| $functions[x] = Hash.new()}
    end
    if $variables.length() < $current_scope+5
      $current_scope.upto($current_scope+5 - $variables.length()) {|x| $variables[x] = Hash.new()}
    end
    
    
    #Store the function body in the global function hash.
    $functions[$current_scope][@func_name.evaluate()] = @body
    
    #Creates the hash container where all the variables for this function will be stored
    #$variables[@func_name.evaluate()] = Hash.new()
    $variables[$current_scope] = Hash.new()
      
    #Creates the hash container where all the parameters for this function will be stored
    $function_parameters[@func_name.evaluate()] = Hash.new()
      
    
    if @parameter_list != nil
      @parameter_list.evaluate().each() {|parameter| $function_parameters[@func_name.evaluate()][parameter] = nil}
    end
  
    #puts "Function List in scope(#{$current_scope}): #{$functions[$current_scope].keys()}"
    #puts "Parameters for function #{@func_name.evaluate()}: #{$function_parameters[@func_name.evaluate()]}."
    #puts "Variables for function #{@func_name.evaluate()}: #{$variables[$current_scope]}."
    
    #$current_scope -= 1
    #$current_scope = old_scope
  end
end


class Argument
  def initialize(_argument)
    @argument = _argument
  end
  
  def evaluate()
    return [@argument.evaluate()]
  end
end


class Arguments
  def initialize(_argument, _arguments = nil)
    @argument = _argument
    @arguments = _arguments
  end
  
  def evaluate()
    if @arguments != nil
      return @arguments.evaluate() + @argument.evaluate()
    else
      return @argument.evaluate()
    end
  end
end
 

class FunctionCall
  def initialize(_func_name, _argument_list = nil)
    @func_name = _func_name
    @argument_list = _argument_list
  end
  
  def evaluate()
    func_name = @func_name.evaluate()
 
    #Change scope to the current function
    $current_scope += 1
    
    if @argument_list != nil
      argument_list = @argument_list.evaluate()
    else
      argument_list = []
    end
    
    #Checks if another scope Array needs to be added for the $function and $variables Array.
    if $functions.length() < $current_scope+5
    $current_scope.upto($current_scope+5 - $functions.length()) {|x| $functions[x] = Hash.new()}
    end
    if $variables.length() < $current_scope+5
      $current_scope.upto($current_scope+5 - $variables.length()) {|x| $variables[x] = Hash.new()}
    end
    
    
    
    #puts "ARGUMENT LIST: #{argument_list}."
    #puts "ARGUMENT LENGTH(): #{argument_list.length()}."
    #puts "VARIABLES IN FUNC: #{$variables[$current_scope]}."
    #puts "ARGUMENTS IN FUNC: #{$function_parameters[func_name]}."
    
    #scope = $functions.length()-1
    
    scope = $current_scope
    until scope < 0
      if $functions[scope].has_key?(func_name) == true
        #puts "Function found in scope: '#{$current_scope}'."
        if ($function_parameters[func_name].length() == argument_list.length())
          argument_keys = $function_parameters[func_name].keys()
          
          0.upto(argument_keys.length()) do |x|
            $variables[scope][argument_keys[x]] = argument_list[x]
          end
  
          #evaluate the body of the function and catch the eventual return value
          return_value = $functions[scope][func_name].evaluate()
          
          if return_value.class == Array
            if return_value[0] == "return"
              $current_scope -= 1
              
              return return_value[1]
            end
          end
          break
        else
          raise "AutoSystem :: Wrong number of arguments. Requested '#{$function_parameters[func_name].length()}' got '#{argument_list.length()}'."
        end
      elsif ($auto_it_functions.has_key?(func_name) == true)
        function_str = "$autoit."+func_name+"("
        #puts "ARGUMENT LIST: #{argument_list}"
        0.upto(argument_list.length()-1) do |elem|
          if argument_list[elem].class == String
            function_str+= '"' + argument_list[elem]  + '"'
          else
            function_str+=argument_list[elem].to_s
          end
          if argument_list.length()-1 != elem and argument_list.length() > 1
            function_str+=","
          end
        end
        function_str+=")"
        #puts "calling builtin function: "+function_str
        $current_scope -= 1
        return eval(function_str)
      elsif scope == 0
        #puts "Functions: #{$functions[$current_scope].keys()}."
        raise "AutoSystem :: Function '#{@func_name.evaluate()}' does not exist."
      end
      scope -= 1
    end
    $current_scope -= 1
  end
end


class PrintOut
  def initialize(_print)
    @print = _print
  end
  
  def evaluate()
    puts @print.evaluate()
  end
end


class PrintIn
  def initialize(_var_name)
    @var_name = _var_name
  end
  
  def evaluate()
    value = gets()
    #puts "Current Scope(when adding new variable): #{$current_scope}"
    $variables[$current_scope][@var_name.evaluate()] = value
    #puts "Variable List: #{$variables[$current_scope]}"
  end
end


class ReturnStatement
  def initialize(_value = nil)
    @value = _value
  end
  
  def evaluate()
    if @value != nil
      return ["return", @value.evaluate()]
    else
      return ["return", nil]
    end
  end
end


class BreakStatement
  def initialize()
  end
  
  def evaluate()
    return ["break"]
  end
end


class FileNew
  def initialize(fname, mode)
    @fname = fname
    @mode = mode
  end
  
  def evaluate()
    return File.new(@fname.evaluate(), @mode.evaluate())
  end
end

class FileWrite
  def initialize(var_name, data)
    @var_name = var_name
    @data = data
  end
  
  def evaluate()
    $variables[$current_scope][@var_name.evaluate()].write(@data.evaluate()+"\n")
  end
end

class FileRead
  def initialize(var_name)
    @var_name = var_name
  end
  
  def evaluate()
    return $variables[$current_scope][@var_name.evaluate()].read().split("\n")
  end
end

class FileClose
  def initialize(var_name)
    @var_name = var_name
  end
  
  def evaluate()
    $variables[$current_scope][@var_name.evaluate()].close()
  end
end

class IntToHex
  def initialize(num)
    @num = num
  end

  def evaluate()
    return "0x%x" % @num.evaluate()
  end
end

class HexToInt
  def initialize(num)
    @num = num
  end

  def evaluate()
    return @num.evaluate().to_i(16)
  end
end

#### GLOBAL VARIABLES ####

$source = File.new("source.as").read()
$current_scope = 0
$current_rep = 0


#$variables, holds variables inside scope hashes.
#Ex. 1 
#$variables["main"]["booze_count"]
#Which means, "Grab variable booze_count from the main scope, the top level/global level."
#
#Ex.2
#$variables[$current_scope]["has_access"]
#$Which means, "Grab variable has_access from the scope we're inside at THIS time."

$variables = [Hash.new()]
$functions = [Hash.new()]
$function_parameters = Hash.new()

$auto_it_functions = {}
functions_txt = File.new("AutoITFunctions.txt","r").read().split("\n")
#$auto_it_functions["Shutdown"] = 0
#add each line to auto_it_functions
for line in functions_txt
  $auto_it_functions[line.chomp] = 0
end

#### GLOBAL VARIABLES END ####


class AutoSystem
  def initialize
    
    @AutoSystem = Parser.new("auto system") do
      #String
      token(/"[^"]*"/m) {|m| m}
        
      #NEWLINE
      token(/\s*\n+/) {"\n"} #TODO <-- newlines e inte funkis atm!!!

      #Remove whitespaces
      token(/\s+/)
      token(/ /)
      
      #Comments
      token(/#.*/)      
      
      #CompareOP
      token(/==/) {|m| m}
      token(/!=/) {|m| m}
      token(/</) {|m| m}
      token(/>/) {|m| m}
      token(/<=/) {|m| m}
      token(/>=/) {|m| m}
      
      #Paranthese
      #token(/\(.*\)/) {|m| m}
                     
      #Arithmetic Operators
      token(/\*/) {|m| m}
      token(/\//) {|m| m}
      token(/\+/) {|m| m}
      token(/-/) {|m| m}
      
      #Assignment Operators
      token(/=/) {|m| m}
      token(/\+=/) {|m| m}
      token(/-=/) {|m| m}

      #Float
      token(/\d+\.\d+/) {|m| m.to_f}
      #Integer
      token(/\d+/) {|m| m.to_i }
          
      token(/\w+/) {|m| m.to_s }
      token(/./) {|m| m}

      start :program do
        match(:stmt_list) {|stmt_list| Program.new(stmt_list)}
      end

      rule :comment do
        match(/#.*/) {|a| "hej = 2"}
        #match(/#\*.*\*#/m) #{"\n"}
      end
      
      rule :stmt_list do
        match(:stmt_list, :stmt_breaker) {|stmt_list, stmt_breaker| StatementList.new(stmt_list, stmt_breaker)}
        match(:stmt_breaker) {|stmt_breaker| StatementList.new(stmt_breaker)}
      end
      
      rule :stmt_breaker do
        match(:simple_stmt, :NEWLINE) #{|stmt, newline| stmt}
        match(:comment) #{|m| m}
      end
      
      rule :simple_stmt do
        match(:file_operations) {|expr| SimpleStatement.new(expr)} 
        match(:func_def) {|block| SimpleStatement.new(block)}
        match(:func_call) {|block| SimpleStatement.new(block)}
        match(:if_stmt) {|block| SimpleStatement.new(block)}
        match(:assign_stmt) {|assign_stmt| SimpleStatement.new(assign_stmt)}
        match(:quick_assign_stmt) {|block| SimpleStatement.new(block)}
        match(:break)
        match(:rep_stmt) {|block| SimpleStatement.new(block)}
        match(:return) {|block| SimpleStatement.new(block)}
        match(:print_i) {|block| SimpleStatement.new(block)}
        match(:print_o) {|block| SimpleStatement.new(block)}
        match(:expr) {|expr| SimpleStatement.new(expr)}  
        match(:comment)
      end
      
      
      rule :return do
        match("return", :expr) {|_,return_val| ReturnStatement.new(return_val)}
        #match("return", :string) {|_,return_val| ReturnStatement.new(return_val)}
        match("return", :call_func) {|_,return_val| ReturnStatement.new(return_val)}
        match("return") {|return_val| ReturnStatement.new()}
      end
      
      rule :break do
        match("break") {|break_stmt| BreakStatement.new()}
      end
            
      rule :print_o do
        match("<", :expr) {|_,print| PrintOut.new(print)}
        #match("<", :string) {|_,print| PrintOut.new(print)}
      end
      
      rule :print_i do
        match(:identifier, "<") {|var_name, _| PrintIn.new(var_name)}
      end
      
      rule :parameter do
        match(:identifier) {|expr| Parameter.new(expr)}
      end
      
      rule :parameters do
        match(:parameters, ",", :parameter) {|parameters,_,parameter| Parameters.new(parameter, parameters)}
        match(:parameter) {|parameter| Parameters.new(parameter)}
      end

      rule :func_def do
        match("def", :identifier, "(", :parameters, ")", :NEWLINE, :body, "end_def") {|_,func_name,_,param,_,_,body,_| FunctionDef.new(func_name, body, param)}
        match("def", :identifier, "(", ")", :NEWLINE, :body, "end_def") {|_,func_name,_,_,_,body,_| FunctionDef.new(func_name, body)}
      end
      
      rule :func_call do
        match(:identifier, "(", :arguments, ")") {|func_name,_,args,_| FunctionCall.new(func_name, args)}
        match(:identifier, "(", ")") {|func_name,_,_| FunctionCall.new(func_name)}
      end
      
      rule :arguments do
        match(:arguments, ",", :argument) {|args,_,arg| Arguments.new(arg, args)}
        match(:argument) {|arg| Arguments.new(arg)}
      end
      
      rule :argument do
        match(:func_call) {|arg| Argument.new(arg)}
        match(:variable_call) {|arg| Argument.new(arg)}
        match(:expr) {|arg| Argument.new(arg)}
        match(:string) {|arg| Argument.new(arg)}
      end 
      
      rule :if_stmt do
        match("if", :expr, :NEWLINE, :body, "end_if") {|_,expr,_,body,_| IfStatement.new(expr, body)} ##funkar ej atm, ska massera de nu va
      end

      rule :rep_stmt do
        match("rep", :identifier, "in", :integer, ",", :integer, :NEWLINE, :body, "end_rep") {|_,ident,_,int_start,_,int_end,_,body,_| RepStatementIntToInt.new(ident, int_start, int_end, body)}
        match("rep", :identifier, "in", :variable_call, :NEWLINE, :body, "end_rep") {|_,ident,_,variable_list,_,body,_| RepStatementList.new(ident, body, variable_list)}
        match("rep", :identifier, "in", :list_def, :NEWLINE, :body, "end_rep") {|_,ident,_,def_list,_,body,_| RepStatementList.new(ident, body, def_list)}
        match("rep", :expr, :NEWLINE, :body, "end_rep") {|_,expr,_,body,_| RepStatementWhile.new(body, expr)}
      end

      rule :list_def do
        match("[", :elements, "]") {|_,elements,_| ListDefinition.new(elements)}
        match("[", "]") {|_,_| ListDefinition.new(nil)}
      end

      rule :elements do
        match(:elements, ",", :element) {|elements,_,element| Elements.new(element, elements)}
        match(:element) {|element| Elements.new(element, nil)}
      end

      rule :element do
        match(:expr) {|expr| Element.new(expr)}
        #match(:string) {|string| Element.new(string)}
        match(:list_def) {|list_def| Element.new(list_def)}
        match(:func_call) {|func_call| Element.new(func_call)}
      end

      #rule :list_call do
      #  match(:identifier, "[", :integer, "]") {|var_name,_,num,_| ListCall.new(var_name, num)}
      #  match(:identifier, "[", :variable_call, "]") {|var_name,_,num,_| ListCall.new(var_name, num)}
      #end

      rule :list_call do
        match(:identifier, :list_brackets) {|var_name, brackets| ListCall.new(var_name, brackets)}
      end

      rule :list_brackets do
        match(:list_brackets, :list_bracket) {|list_brackets,list_bracket| ListBrackets.new(list_brackets, list_bracket)}
        match(:list_bracket) {|list_bracket| ListBrackets.new(nil, list_bracket)}
      end

      rule :list_bracket do
        match("[", :integer, "]") {|_,bracket,_| ListBracket.new(bracket)}
        match("[", :variable_call, "]") {|_,bracket,_| ListBracket.new(bracket)}
      end

      rule :NEWLINE do
        match("\n") {"\n"}
      end
      
      rule :assign_stmt do
        match(:identifier, "=", :file_new) {|var_name,_,value| AssignStatement.new(var_name, value)}
        match(:identifier, "=", :file_read) {|var_name,_,value| AssignStatement.new(var_name, value)}
        match(:identifier, "=", :list_call) {|var_name, _, value| AssignStatement.new(var_name, value)}
        match(:identifier, "=", :list_def) {|var_name, _, value| AssignStatement.new(var_name, value)}
        match(:identifier, "=", :func_call) {|var_name, _, value| AssignStatement.new(var_name, value)} 
        match(:identifier, "=", :bool) {|var_name, _, value| AssignStatement.new(var_name, value)}
        match(:identifier, "=", :variable_call) {|var_name, _, value| AssignStatement.new(var_name, value)}
        match(:identifier, "=", :expr) {|var_name, _, value| AssignStatement.new(var_name, value)}
      end

      rule :quick_assign_stmt do
        match(:identifier, "+", "=", :calculate_expr) {|var_name,_,_,calc_expr| AddQuickAssignStatement.new(var_name, calc_expr)}
        match(:identifier, "-", "=", :calculate_expr) {|var_name,_,_,calc_expr| SubQuickAssignStatement.new(var_name, calc_expr)}
        match(:identifier, "*", "=", :calculate_expr) {|var_name,_,_,calc_expr| MultiQuickAssignStatement.new(var_name, calc_expr)}
        match(:identifier, "/", "=", :calculate_expr) {|var_name,_,_,calc_expr| DivQuickAssignStatement.new(var_name, calc_expr)}
        match(:identifier, "%", "=", :calculate_expr) {|var_name,_,_,calc_expr| ModQuickAssignStatement.new(var_name, calc_expr)}
      end

      rule :identifier do
        match(/(?!true|false|if|end_if|rep|end_rep|return|in|def|break|end_def|hex|int|File)^([a-zA-Z_][a-zA-Z_\d]*)/) {|var_name| Identifier.new(var_name)}
      end
                
      rule :variable_call do      
        match(:identifier) {|var_name| VariableCall.new(var_name)}
      end

      rule :body do
        match(:stmt_list) {|expr| expr}
      end
      
      rule :expr do
        match(:or_expr) {|expr| Expression.new(expr)}
      end
      
      rule :or_expr do
        match(:and_expr) {|expr| expr}
        match(:or_expr, "or", :and_expr) {|expr1, op, expr2| Logical_Expr.new(expr1, op, expr2)}
      end

      rule :and_expr do
        match(:not_expr) {|expr| expr}
        match(:and_expr, "and", :not_expr) {|expr1, op, expr2| Logical_Expr.new(expr1, op, expr2)}
      end      

      rule :not_expr do
        match(:relation_expr) {|m| m}
        match("not", :not_expr) {|_, expr| Not_Expr.new(expr)}
      end
      
      rule :relation_expr do
        match(:calculate_expr, :relation_operator, :calculate_expr) {|expr1, op, expr2| Relation_Expr.new(expr1, op, expr2)}
        match(:calculate_expr) {|expr| expr}
        match(:bool) {|bool| bool}
        match(:variable_call) {|var_value| var_value}
      end
      
      rule :relation_operator do
        match("<") {|op| op}
        match(">") {|op| op}
        match("<=") {|op| op}
        match(">=") {|op| op}
        match("==") {|op| op}
        match("!=") {|op| op}
      end
      
      rule :calculate_expr do
        match(:add_calculate_expr) {|m| m}
      end
      
      rule :add_calculate_expr do
        match(:multi_calculate_expr) {|m| m}
        match(:add_calculate_expr, "+", :multi_calculate_expr) {|expr1,_,expr2| AddCalculateExpr.new(expr1, expr2)}
        match(:add_calculate_expr, "-", :multi_calculate_expr) {|expr1,_,expr2| SubCalculateExpr.new(expr1, expr2)}
      end

      rule :multi_calculate_expr do
        match(:neg_expr) {|m| m}
        match(:multi_calculate_expr, "%", :multi_calculate_expr) {|expr1,_,expr2| ModCalculateExpr.new(expr1, expr2)}
        match(:multi_calculate_expr, "*", :multi_calculate_expr) {|expr1,_,expr2| MultiCalculateExpr.new(expr1, expr2)}
        match(:multi_calculate_expr, "/", :multi_calculate_expr) {|expr1,_,expr2| DivCalculateExpr.new(expr1, expr2)}
      end   
         
      rule :neg_expr do
        match(:atom) {|m| m}
        match("-", :atom) {|_,atom| NegativeAtom.new(atom)}
      end
    
      rule :atom do
        match(:paranthese) {|m| m}
        match(:integer) {|m| m}
        match(:float) {|m| m}
        match(:variable_call) {|m| m}
        match(:string) {|m| m}
        match(:hex_to_int) {|m| m}
        match(:int_to_hex) {|m| m}
      end

      rule :paranthese do
        match("(", :add_calculate_expr, ")") {|_,expr,_| expr}
      end

      rule :integer do
        match(Integer) {|integer| Integer_Type.new(integer)}
      end
      
      rule :float do
        match(Float) {|float| Float_Type.new(float)}
      end
      
      rule :string do
        match(/"[^"]*"/m) {|string| String_Type.new(string[1..-2])}
      end
      
      rule :bool do
        match(:true) {|bool| bool}
        match(:false) {|bool| bool}
      end
      
      rule :true do
        match(/true/) {Bool_Type.new(true)}
      end
      
      rule :false do
        match(/false/) {Bool_Type.new(false)}
      end

      rule :file_new do
        match("File",".","new", "(", :string, ",", :string, ")") {|_,_,_,_,fname,_,mode,_| FileNew.new(fname, mode)}
      end

      rule :file_operations do
        match(:identifier, ".", "write", "(", :string, ")") {|var_name,_,_,_,data,_| FileWrite.new(var_name, data)}
        match(:identifier, ".", "close", "(", ")") {|var_name,_,_,_,_| FileClose.new(var_name)}
      end

      rule :file_read do
        match(:identifier, ".", "read", "(", ")") {|var_name,_,_,_,_| FileRead.new(var_name)}
      end

      rule :int_to_hex do
        match("hex", "(", :integer, ")") {|_,_,num,_| IntToHex.new(num)}
        match("hex", "(", :variabel_call, ")") {|_,_,num,_| IntToHex.new(num)}
      end

      rule :hex_to_int do
        match("int", "(", :string, ")") {|_,_,string,_| HexToInt.new(string)}
        match("int", "(", :variabel_call, ")") {|_,_,string,_| HexToInt.new(string)}
      end
    end
  end
  
  def done(str)
    ["quit","exit","bye"].include?(str.chomp)
  end

  def run
    puts "=> #{@AutoSystem.parse $source + "\n"}"
  end

  def log(state = true)
    if state
      @AutoSystem.logger.level = Logger::DEBUG
    else
      @AutoSystem.logger.level = Logger::WARN
    end
  end
end

