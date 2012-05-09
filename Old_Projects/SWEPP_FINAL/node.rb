@@variable_hash = {} #<-- här alla variabler spars ner och med ett värde
@@func = {}         #<-- här sparas alla funktioner ner
@@string_vars = []   #<-- här spars variabelnamnen på alla variabler av typen sträng
@@number_vars = []  #<-- här spars variabelnamnen på alla variabler av typen tal
@@bool_vars = []     #<-- här spars variabelnamnen på alla variabler av typen bool

def look_up(var, hash) #<-- till får att slå upp värden i variable_hash
  hash[var]
end

class Look_up_var
	attr_accessor :value
	def initialize (var)
		@value = var
	end
	def seval()
		@@variable_hash.each_key  do |key|
			if key == @value then
				return @@variable_hash[key]
			else
				return nil
			end
		end
	end
end

class Print_node         
  attr_accessor :print
  def initialize (var)
    @print = var
  end
  def seval()
	if @print.class == Function_call_node then
		temp = @print.seval
		p temp["_-_Return_node_-_"]
	else
		p @print.seval
	end
    return nil
  end
end

class While_node               
  attr_accessor :bool,:statements
  def initialize (bool,satser)
    @bool = bool
    @satser = satser
  end
  def seval()
	  break_found = false
	  check = @bool.seval 
	  while @bool.seval == true
      @satser.each do |elm|
        value = elm.seval()
        if value == "break_node" then
          check = false
          break_found = true
        elsif value.class() == Hash and value.has_key?("_-_Return_node_-_")
          return value
        end
      end
      if break_found == true then
        break
      end
    end
    return @satser
  end
end

class For_node      
  attr_accessor :bool,:assign,:statements
  def initialize (bool,assign,satser)
    @bool = bool
    @satser = satser
    @assign = assign
  end
  def seval()
	  break_found = false
	  while @bool.seval == true
      @satser.each do |elm|
        value = elm.seval()
        if value == "break_node" then
          break_found = true
        elsif value.class() == Hash and value.has_key?("_-_Return_node_-_")
          return value
        end
      end
      if break_found == true then
        break
      end
      assign.seval()
    end
    return @satser
  end
end

class Break_node                
  def initialize()
  end
  def seval()
	  return "break_node"
  end
end

class Atom_node              
  attr_accessor :val
  def initialize (int)
    @val = int
  end
  def seval()
    return @val
  end
end

class Aritm_node                     
  attr_accessor :aritm_uttr
  def initialize(aritm_uttr)
    @aritm_uttr = aritm_uttr
  end
  def seval()
    return aritm_uttr.seval
  end
end

class Variable_node              
  attr_accessor :name
  def initialize(id)
    @name = id
  end
  def seval()
    return look_up(@name, @@variable_hash)
  end
end

class Function_node              
  attr_accessor :type,:func_name,:parameters,:statements
  def initialize(type,name,para,satser)
    @type = type
    @func_name = name
    @parameters = para
    @satser = satser
    if not @@func.has_key?(@func_name)
      @@func[func_name] = self
    else
      abort("Error funktionen \"#{@func_name}\" finns redan ")
    end
  end
  def get_values()
	  return @satser,@parameters,@type
  end
  
  def seval()
	  return nil
  end
end

class Function_call_node
	attr_accessor :name, :parameters
	def initialize(name,para)
		@name = name
		@para = para
		if not @@func.has_key?(@name.name) then
			abort("Funktionen #{@name.name} finns inte.")
		end
		
		@satser , @parameters, @type = @@func[@name.name].get_values()
		if @para.size() != @parameters.size() then
			abort("Antal parametrar stämmer inte överens. (#{@para.size} av #{@parameters.size})")
		end
  end
	def seval()
		i = 0
		size = @para.size()
		while i < size
			@@variable_hash[@parameters[i].name] = @para[i].seval
			i +=1
		end
		@satser.each do |sats|
			value = sats.seval()
			if value.class() == Hash and value.has_key?("_-_Return_node_-_")
				if value["_-_Return_node_-_"].class == Fixnum and @type == "tal"
					return sats.seval
				elsif value["_-_Return_node_-_"].class == Float and @type == "tal"
					return sats.seval
				elsif value["_-_Return_node_-_"].class == Bignum and @type == "tal"
					return sats.seval
				elsif value["_-_Return_node_-_"].class == String and @type == "sträng"
					return sats.seval
				elsif (value["_-_Return_node_-_"].class == TrueClass or value["_-_Return_node_-_"].class == FalseClass) and @type == "bool"
					return sats.seval
				elsif value["_-_Return_node_-_"].class == Array and @type == "lista"
					return sats.seval
				elsif  @type == "inget"
					abort("ERROR:	Du kan inte returnera i en inget-funktion.")
					return nil
				else
					abort( "ERROR: Fel returtyp-värde på #{value["_-_Return_node_-_"]}  #{@type}.")
					return nil
				end
			end
		end
	end
end

class Return_node
  attr_accessor :return_value
  def initialize (var)
    @var = var
  end
  def seval()
	  return_value = {}
	  return_value["_-_Return_node_-_"] = @var.seval()
    return return_value
  end
end

class If_block_handler       
	attr_accessor :bool_value, :statements
	def initialize(bool_test,satser)
		@bool_value = bool_test
		@satser = satser
	end
	def seval()
		return nil
	end
end

class If_node    
	attr_accessor :satser2
	def initialize(satser2)
		@satser2 = satser2
	end
	def seval()
		@satser2.each do |elm|
			if elm.bool_value.seval == true then
				elm.statements.each do |sats|
					value = sats.seval
					if value == "break_node"
						return "break_node"
					elsif value.class() == Hash and value.has_key?("_-_Return_node_-_")
						return value
					end
				end
			end
		end
	end
end

class Expr_node
  attr_accessor :operator, :operand1, :operand2
  def initialize(op, op1, op2)
    @operator = op
    @operand1 = op1
    @operand2 = op2
  end
  def seval()
    case operator
		when '+'
			return operand1.seval + operand2.seval 
		when '-'
			return operand1.seval - operand2.seval
		when '*'
			return operand1.seval * operand2.seval 
		when '/'
			return operand1.seval  / operand2.seval
		when '%'
			return operand1.seval  % operand2.seval
		when '&'
			return operand1.seval  + operand2.seval
		when '<'
			return operand1.seval  < operand2.seval 
		when '>'
			return operand1.seval  > operand2.seval 
		when '<='
			return operand1.seval  <= operand2.seval 
		when '>='
			return operand1.seval  >= operand2.seval 
		when '!='
			return operand1.seval  != operand2.seval
		when '=='
			return operand1.seval  == operand2.seval
		when 'and'
			return operand1.seval  && operand2.seval
		when 'not'
			return  (not operand2.seval)
		when 'or'
			return operand1.seval  || operand2.seval
		when 'xor'
			return operand1.seval  ^ operand2.seval
		else nil
    end
  end
end

class Array_node
	def initialize(array)
		@array = array
	end
	def seval
		i = 0
		size = @array.size
		while(i<size)
			@array[i] = @array[i].seval
			i += 1
		end
		return @array
	end
end

class Array_index_node 
  def initialize(array_name, index)
    @array_name  = array_name
    @index = index
  end
  def seval
    var = look_up(@array_name.name,@@variable_hash)
    value = var[@index.seval]
    return value
  end
	 
end
 
class Array_add_node
  def initialize(array_name,item)
		@array_name = array_name
		@item = item
	end
	def seval
		array = look_up(@array_name.name,@@variable_hash)
		array << @item.seval
		@@variable_hash[@array_name.name] = array
	end
end

class Array_size_node
	def initialize(array_name)
		@array_name  = array_name
	end
	def seval
		array = look_up(@array_name.name,@@variable_hash)
		return array.size
	end
end

class Array_remove_index_node
	def initialize(array_name,index)
		@array_name  = array_name
		@index = index
	end
	def seval
		array = look_up(@array_name.name,@@variable_hash)
		array.delete_at(@index.seval)
		@@variable_hash[@array_name.name] = array
	end
end

class Array_remove_value_node
	def initialize(array_name,value)
		@array_name  = array_name
		@value = value
	end
	def seval
		array = look_up(@array_name.name,@@variable_hash)
		array.delete(@value.seval)
		@@variable_hash[@array_name.name] = array
	end
end

class AssignStart_node
  attr_accessor :var, :tilldelnings_uttryck
  def initialize(var, uttr)
    @var=var
    @tilldelnings_uttryck = uttr
  end
  def seval()
    varde = @tilldelnings_uttryck.seval
    
    if varde.class == Hash then
      if  (not @@string_vars.include?(var.name)) and varde["_-_Return_node_-_"].class == String  then
        @@string_vars << var.name
        @@variable_hash[var.name] = varde["_-_Return_node_-_"]
      elsif  (not @@number_vars.include?(var.name)) and varde["_-_Return_node_-_"].class == Fixnum  then
        @@number_vars << var.name
        @@variable_hash[var.name] = varde["_-_Return_node_-_"]
      elsif  (not @@number_vars.include?(var.name)) and varde["_-_Return_node_-_"].class == Float  then
        @@number_vars << var.name
        @@variable_hash[var.name] = varde["_-_Return_node_-_"]
      elsif  (not @@bool_vars.include?(var.name)) and (varde["_-_Return_node_-_"].class == TrueClass or varde.class == FalseClass) then
        @@bool_vars << var.name
        @@variable_hash[var.name] = varde["_-_Return_node_-_"]
      elsif  (not @@number_vars.include?(var.name)) and varde["_-_Return_node_-_"].class == Bignum  then
        @@number_vars << var.name
        @@variable_hash[var.name] = varde["_-_Return_node_-_"]
      elsif  varde["_-_Return_node_-_"].class == Array  then
        temp  = []
        varde["_-_Return_node_-_"].each do |ele|
          if ele.class == Variable_node then
            temp << ele.name
          else
            temp << ele.seval
          end
        end	  
        @@variable_hash[var.name] = temp
      else
        abort("ERROR: variabeln #{var.name} finns redan eller är av fel typ. (#{varde.class})")
      end
    
    elsif  (not @@string_vars.include?(var.name)) and varde.class == String  then
      @@string_vars << var.name
      @@variable_hash[var.name] = varde
    elsif  (not @@number_vars.include?(var.name)) and varde.class == Fixnum  then
	    @@number_vars << var.name
      @@variable_hash[var.name] = varde
    elsif  (not @@number_vars.include?(var.name)) and varde.class == Float  then
      @@number_vars << var.name
      @@variable_hash[var.name] = varde
    elsif  (not @@bool_vars.include?(var.name)) and (varde.class == TrueClass or varde.class == FalseClass) then
      @@bool_vars << var.name
      @@variable_hash[var.name] = varde
    elsif  (not @@number_vars.include?(var.name)) and varde.class == Bignum  then
	    @@number_vars << var.name
      @@variable_hash[var.name] = varde
    elsif  varde.class == Array  then
      @@variable_hash[var.name] = varde
    else
      abort( "ERROR: variabeln #{varde.name} finns redan eller är av fel typ. (#{varde.class})")
    end
  end
end

class Assign_node
  attr_accessor :var, :tilldelnings_uttryck
  def initialize(var, uttr)
    @var=var
    @tilldelnings_uttryck = uttr
  end
  def seval()
    varde = tilldelnings_uttryck.seval
    if  (@@string_vars.include?(var.name)) and varde.class == String  then
      @@variable_hash[var.name] = varde
    elsif  (@@number_vars.include?(var.name)) and varde.class == Fixnum  then
      @@variable_hash[var.name] = varde
    else
      abort( "ERROR: variabeln #{varde.name} finns inte eller är fel typ. (#{varde.class})")
    end
  end
end