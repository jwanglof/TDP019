# -*- coding: utf-8 -*-
require "rdparser"
require "tree"
require "library"

class Gandalf
  attr_accessor :parser
  def initialize
    @code = ""
    @parser = Parser.new("Gandalf") do
      token(/\n+/){ |m| "\n" }
      token(/\t+/)
      token(/class\s/){ |m| "class" }
      token(/return\s/){ |m| "return" }
      token(/print\s/){ |m| "print" }
			token(/"[^"]*"/){|m| m}
      token(/\s+/)
      
      
      token(/true/){ |m| m }
      token(/false/){ |m| m }
      token(/if/){ |m| m }
			token(/for/){|m| m}
      token(/else/){ |m| m }
      token(/while/){ |m| m }
      token(/\&\&/){ |m| m }
      token(/\|\|/){ |m| m }
      token(/./){ |m| m }
      
      
      start :program do
        match(:statement_list){ |a| a.eval }
      end

      rule :suite do
        match("\n", "→", :statement_list, "←"){ |_,_,a,_| a }
      end

      rule :statement_list do #this is our statement+
        match(:statement,:statement_list){ |a,b| Compound_statement_list_node.new(a,b) }
        match(:statement)
      end
      
      rule :statement do
        match(:complex_stmt)
        match(:simple_stmt, "\n"){ |a,_| a }
      end
     
      rule :complex_stmt do
        match(:class_def)
        match(:function_def)
				match(:for_stmt)
        match(:while_stmt)
        match(:if_stmt)
      end

      rule :simple_stmt do
        match(:return_stmt)
        match(:function_call)
        match(:print_stmt)
        match(:assignment_stmt)
        match(:expr)
      end
      
      rule :print_stmt do
        match("print",:expr){ |_,a| Print_stmt_node.new(a) }
      end

      rule :class_def do
        match("class", :identifier,"\n", "→", :class_body, "←"){ |_,a,_,_,b,_| Class_node.new(a,b) }
      end

      rule :class_body do
        match(:function_def, :class_body) { |a,b| Compound_statement_list_node.new(a,b) }
        match(:function_def)
      end

      rule :function_def do 
        match(:function_part, :suite){ |a,b| a.function_body = b
          a
        }
        match(:function_name,:suite){ |a,b| c =Function_node.new(a)
          c.function_body = b
          c
        }
      end

      rule :function_part do
        match(:function_name, ":", :identifier, "," , :function_part){ |a,_,b,_,c|
          c.function_name = a + "_" + c.function_name
          c.variable_names.insert(0,b)
          c
        }
        match(:function_name, ":", :identifier){ |a,_,b| Function_node.new(a,b) }
      end

      rule :function_name do
        match(:identifier)
      end

      rule :function_call do
        match("[", :identifier, ",", :function_call_part,"]"){ |_,a,_,b,_|
          b.type = a
	        b
	      }
        match("[", :identifier, ",", :function_name,"]"){ |_,a,_,b,_|
          c = Function_call_node.new(b)
          c.type=a
          c
        }
      end

      rule :function_call_part do
        match(:function_name, ":", :expr, ",", :function_call_part){ |a,_,b,_,c|
          c.name = a + "_" +c.name
          c.variable_values.insert(0,b)
          c
        }
        match(:function_name, ":", :expr) { |a,_,b| Function_call_node.new(a,b) }
      end
      
      rule :return_stmt do
        match("return", :expr){ |_,a| Return_statement_node.new(a) }
      end

      rule :while_stmt do
        match("while", "(", :expr, ")", :suite){ |_,_,a,_,b,| While_node.new(a,b) }
      end

			rule :for_stmt do
				match("for", "(", :identifier, "<","<", :expr, ")", :suite){|_,_,a,_,_,b,_,c|For_node.new(a,b,c)}
			end
      
      rule :if_stmt do
        match("if","(", :expr, ")", :suite, "else", :suite){ |_,_,a,_,b,_,c| If_else_node.new(a,b,c) }
        match("if","(", :expr, ")", :suite, "else", :if_stmt){ |_,_,a,_,b,_,c| If_else_node.new(a,b,c) }
        match("if","(", :expr, ")", :suite){ |_,_,a,_,b| If_node.new(a,b) }
      end

      rule :assignment_stmt do
        match(:identifier, "=", :expr){ |a,_,b| Assignment_node.new((Variable_node.new(a)),b) }
        match(:identifier, "=", :function_call){ |a,_,b| Assignment_node.new((Variable_node.new(a)),b)}
        match("@", :identifier, "=", :expr){|_,a,_,b| Instance_assignment_node.new((Instance_variable_node.new(a)),b)}
        match("@", :identifier, "=", :function_call){|_,a,_,b| Instance_assignment_node.new((Instance_variable_node.new(a)),b)}
      end

      rule :expr do
        match(:or_test)
				match(:function_call)
      end
      
      rule :or_test do
        match(:and_test)
        match(:or_test, "||", :and_test){ |a,b,c| Compound_logical_node.new(a,b,c) }
      end

      rule :and_test do
        match(:not_test)
        match(:and_test, "&&", :not_test){ |a,b,c| Compound_logical_node.new(a,b,c) }
      end

      rule :not_test do
        match(:comparison)
        match("!", :not_test){ |_,a| Not_node.new(a) }
      end

      rule :comparison do
        match(:a_expr, :logical_operator, :a_expr){ |a,b,c| Compound_logical_node.new(a,b,c) }
        match(:a_expr){ |a| Arithmetic_node.new(a) }
      end
      
      rule :logical_operator do
        match(/<|>|=|!/,/=/){ |a,b| a+b }
        match(/<|>|=/)
      end

      rule :a_expr do
        match(:m_expr)
        match(:a_expr, "+", :m_expr) { |a,b,c| Compound_arithmetic_node.new(a,b,c) }
        match(:a_expr, "-", :m_expr) { |a,b,c| Compound_arithmetic_node.new(a,b,c) }
      end

      rule :m_expr do
        match(:u_expr)
        match(:m_expr, "*", :u_expr){ |a,b,c| Compound_arithmetic_node.new(a,b,c) }
        match(:m_expr, "/", :u_expr){ |a,b,c| Compound_arithmetic_node.new(a,b,c) }
        match(:m_expr, "%", :u_expr){ |a,b,c| Compound_arithmetic_node.new(a,b,c) }
      end

      rule :u_expr do
        match(:atom)
        match("-", :u_expr){ |_,a| a * -1 }
      end
      
      rule :atom do
        match("(", :comparison, ")"){ |_,a,_| a }
        match(:boolean)
        match(:number)
				match(:list_access)
				match(:string)
        match(:identifier){ |a| Variable_node.new(a) }
				match("@", :identifier){|_,a| Instance_variable_node.new(a)}
				match(:list)
      end
      
      rule :identifier do
        match(:identifier_chars, :identifier_part){ |a,b| a+b }
        match(:identifier_chars)
      end
      
      rule :identifier_part do
        match(:identifier_chars, :identifier_part) { |a,b| a+b }
        match(:digit, :identifier_part) { |a,b| a+b }
        match(:identifier_chars)
        match(:digit)
      end

			rule :list_access do
				match(:identifier, "{", :number, "}"){|a,_,b,_|List_access_node.new(b, Variable_node.new(a))}
			end

			rule :list do
				match("{",:list_body,"}"){|_,a,_|a}
				match("{", :expr, ".", ".", :expr, "}"){|_,a,_,_,b,_|c = List_type.new(a.eval)
				c.range_value = b.eval
				c
				}
			end
			
			rule :list_body do
				match(:expr, ",", :list_body){|a,_,b|b.list_values.insert(0,a.eval)
				b}
				
				match(:expr) {|a|List_type.new(a.eval)}
			end

			rule :string do
				match(/"[^"]*"/){|a|String_type.new(a)}
			end

			rule :string_body do
				match(/[^"]/, :string_body){|a,b|a+b}
				match(/[^"]/){|a|a}
			end

      rule :boolean do
        match("true") { |a| Constant_node.new(true) }
        match("false") { |a| Constant_node.new(false) }
      end

      rule :number do
        match(:float){ |a| Constant_node.new(a.to_f) }
        match(:integer){ |a| Constant_node.new(a.to_i) }
      end

      rule :float do
        match(:integer,".",:integer){ |a,_,b| a+"."+b }
      end
      
      rule :integer do
        match(:digit, :integer) { |a,b| a+b }
        match(:digit){ |a| a }
      end
      
      rule :identifier_chars do
        match(/[A-Za-z_]/)
      end

      rule :digit do
        match(/[0-9]/)
      end


    end
  end
end


