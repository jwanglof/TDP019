class String_type
	attr_accessor :value	
	def initialize(data)
		@value = data
	end
	def eval
		return @value
	end
end

class List_type
	attr_accessor :list_values, :range_value
	def initialize(first_value)
		@list_values = [first_value]
	end
	def eval
		if range_value
			@list_values = (@list_values[0]..@range_value).to_a
		end
		return @list_values
	end
end
