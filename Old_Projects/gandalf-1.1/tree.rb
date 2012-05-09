@@identifiers =[{}] #This is used to handle our scope, the lists index indicates what scope to access
@@classes = {} #We wanted to be able to access classes everywhere, so we created a new hashtable for handeling classes
@@scope = 0 #Indicates which index we should use in @@identifiers
@@base_scope = [0] #Is used when a new function or class is created to hinder access to variables outside of them
@@instance_stack = [] #Is used to associate instance variables with the right instance
@@instance_variables = {} #Is used for handeling instance variables

def look_up(variable)
  i = @@scope
  while(i>=@@base_scope.last)
    if @@identifiers[i][variable] != nil
      return @@identifiers[i][variable]
    end
    i -= 1
  end
  if variable.match(/^0/)
    raise(NameError, "Function '#{variable}' does not exist. Your code shall not pass!")
  else
    raise(NameError, "Variable '#{variable}' does not exist. Your code shall not pass!")
  end
end

def new_scope
  @@scope +=1
  @@identifiers << {}
end

def new_base_scope(move_functions_to_new_base_scope = false)
  #This ensures that we cannot access variables that were created outside of this scope. 
  #For example, functions use this.  
  
  functions = {}
  if (move_functions_to_new_base_scope)
    # Enter this loop if functions should be moved into the new base scope
    i = @@scope
    while(i>=@@base_scope.last)
      @@identifiers[i].each_pair do | key, value |
        if (key.match(/^0_/))
          functions[key] = value
        end
      end
      i -= 1
    end
  end
  
  new_scope()
  @@base_scope << @@scope
  
  # Add every function that should be moved to new scope
  functions.each_pair do | key, value |
    @@identifiers[@@scope][key] = value
  end
end

def close_scope
  @@identifiers.pop
  @@scope-=1
  if @@scope < 0
    raise("Scope is now less then 0, check your code Mr Frodo")
  end
end

def close_base_scope
  close_scope
  @@base_scope.pop
end

class Compound_statement_list_node
  attr_accessor :statement1, :statement2
  def initialize(stmt1, stmt2) #stmt2 can either be a statement or another compound_statement_list_node
    @statement1 = stmt1
    @statement2 = stmt2
  end

  def eval
    return_val = @statement1.eval
    if @statement1.class != Return_statement_node #If statement1 is a return statement we do not run the rest of the code 
      @statement2.eval
    else
      return return_val
    end
  end

	def find_functions
    if @statement2.respond_to? :find_functions
      # statement2 seems to be another compound statement list
      function_list = @statement2.find_functions()
      if @statement1.function_name
        function_list << @statement1
      end
      return function_list
    else
      # Quite messy, but this is the collecting part of all functions
      function_list = []
      if @statement1.function_name
        function_list << @statement1
      end
      if @statement2.function_name
        function_list << @statement2
      end
      return function_list
    end
  end
end

class Function_node
  attr_accessor :function_name, :variable_names, :function_body
  def initialize(name_part, variable = nil)
    @function_name = name_part
    @variable_names = []
    @variable_names << variable if variable
    #@function_body = function_body
  end
  def eval
    @@identifiers[@@scope]["0_#{@function_name}"] = self
  end
end

class Function_call_node
  attr_accessor :name, :variable_values, :type
  def initialize(name_part, value= nil)
    @name = name_part
    @type = "self"
    @variable_values = []
    @variable_values << value if value != nil
  end

	def instance_name(name) #checks which instance(if any) we are currently using
		if @@classes[@type]
			@is_instance = true
			@@instance_stack << name
		elsif @type != "self"
			@is_instance = true
			@@instance_stack << @type
		end
	end

  def run_function(function)
		eval_values = []
		(0..@variable_values.length-1).each do |j|
			eval_values[j] = @variable_values[j].eval # we evaluate our values before we enter the new scope
		end

    new_base_scope(true)
    (0..function.variable_names.length-1).each do |i|
      @@identifiers[@@scope][function.variable_names[i]] = eval_values[i]
    end
    return_val = function.function_body.eval
    close_base_scope()

		if @is_instance
			@@instance_stack.pop
		end
    return return_val
  end

  def eval
    if @type == "self"
      # Function call on self
      function = look_up("0_#{@name}")
      return run_function(function)
    elsif @@classes[@type] and @name.match(/^init/)
      # Init call on class
      if @@classes[@type].class_body.respond_to? :find_functions
        function_list = @@classes[@type].class_body.find_functions
			  for function in function_list
          if function.function_name == @name
            run_function(function)
            return @@classes[@type]
          end
        end
      elsif @@classes[@type].class_body.function_name.match(/^init/) 
        #we only do this if there is only one function in the class
        run_function(@@classes[@type].class_body)
        return @@classes[@type]
      elsif @name == "init"
        return @@classes[@type]
      end
      raise(NameError, "Undefined function '#{@name}' for class '#{@type}'. You fool of a Took!")
    else
      # Function call on instance
			instance_name(@type)
      class_node = look_up(@type)
      # Open new base scope so that functions defined outside class can't be called from inside of class
      new_base_scope()
      class_node.class_body.eval
      function = look_up("0_#{@name}")
      return_val = run_function(function)
      close_base_scope()
      return return_val
    end
  end
end

class Return_statement_node
  attr_accessor :expression
  def initialize(expr)
    @expression = expr
  end
  def eval
    return @expression.eval
  end
end

  
  
class Class_node 
  attr_accessor :name, :class_body
  def initialize(name, functions, inheritance=nil)
    @name = name
    @class_body = functions 
    @inheritance = inheritance
  end
  def eval
    @@classes[@name] = self
  end
end

class If_else_node
  attr_accessor :condition, :statement1, :statement2
  def initialize(cond, stmt1, stmt2)
    @condition = cond
    @statement1 = stmt1
    @statement2 = stmt2
  end
  def eval
    new_scope()
    if @condition.eval
      return_value = @statement1.eval
    else
      return_value = @statement2.eval
    end
		close_scope()
    return return_value
  end
end

class Print_stmt_node
  attr_accessor :expression
  def initialize(expr)
    @expression = expr
  end
  def eval
    puts @expression.eval
  end
end

class If_node
  attr_accessor :condition, :statement
  def initialize(cond, stmt)
    @condition = cond
    @statement = stmt
  end
  def eval
    new_scope()
    if @condition.eval
      return_value =@statement.eval
      close_scope()
      return return_value
    end
    close_scope()
  end
end

class For_node
	def initialize(variable, list, loop_body)
		@iterator_var = variable
		@iteration_values = list
		@loop_body = loop_body
	end
	def eval
		new_scope()
		@iteration_values.eval.each do |i|
			Assignment_node.new(Variable_node.new(@iterator_var), Constant_node.new(i)).eval
			@loop_body.eval
		end
		close_scope()
		nil
	end
end

class While_node
  attr_accessor :condition, :statement
  def initialize(cond, stmt)
    @condition = cond
    @statement = stmt
  end
  def eval
    new_scope()
    while @condition.eval do
      @statement.eval
    end
    close_scope()
    nil
  end
end

class Compound_node
  attr_accessor :operator, :operand1, :operand2
  def initialize(op1, op, op2)
    @operator = op
    @operand1 = op1
    @operand2 = op2
  end
  def eval
		if @operand1.class == String_type and @operand2.class == String_type
			return instance_eval("'#{@operand1.eval}' #{operator} '#{@operand2.eval}'")
		end
    return instance_eval("#{@operand1.eval} #{operator} #{@operand2.eval}")
  end
end

class Not_node
  attr_accessor :operand
  def initialize(op)
    @operand = op
  end
  def eval
    return (not @operand.eval)
  end
end

class Compound_logical_node < Compound_node
end

class Assignment_node
  attr_accessor :identifier, :expr
  def initialize(id, expression)
    @identifier = id
    @expr = expression
  end
  def eval
		if @expr.respond_to? :instance_name
			@expr.instance_name(@identifier.name)
		end

    i = @@base_scope.last
    add_variable = true
    while(i<=@@scope)
      if @@identifiers[i][@identifier.name] != nil
        @@identifiers[i][@identifier.name] = @expr.eval
        add_variable = false
      end
      i+=1
    end
    if add_variable
      @@identifiers[@@scope][@identifier.name] = @expr.eval
    end
  end
end

class Instance_assignment_node
	attr_accessor :identifier, :expr
  def initialize(id, expression)
    @identifier = id
    @expr = expression
  end
	
	def eval
		if @@instance_stack.last
			if @@instance_variables[@@instance_stack.last]
				@@instance_variables[@@instance_stack.last][@identifier.name] = @expr.eval
			else
				@@instance_variables[@@instance_stack.last] = {@identifier.name => @expr.eval}
			end
		end
	end
end


class Constant_node
  attr_accessor :value
  def initialize(data)
    @value = data
  end
  def eval
    return @value
  end
end

class Variable_node
  attr_accessor :name
  def initialize(identifier)
    @name = identifier
  end
  def eval
    return look_up(@name)
  end
end

class Instance_variable_node
	attr_accessor :name
	def initialize(identifier)
		@name = identifier
	end
	def eval
		if @@instance_variables[@@instance_stack.last]
			return @@instance_variables[@@instance_stack.last][@name]
		else
			raise(NameError, "Instance variable '#{@name}' does not exist. Your code shall not pass!")
		end
	end
end

class Compound_arithmetic_node < Compound_node
end

class Arithmetic_node
  attr_accessor :arithmetic_expr
  def initialize(arithmetic)
    @arithmetic_expr = arithmetic
  end
  def eval
    return @arithmetic_expr.eval
  end
end

class List_access_node
	attr_accessor :list_variable
	def initialize(index, variable)
		@index = index
		@list_variable = variable
		
	end
	def eval
		return @list_variable.eval[@index.eval]
	end
end

