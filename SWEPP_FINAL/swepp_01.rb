require 'rdparse'
require 'node'


class Swepp
  attr_accessor  :assign_hash, :result
  def initialize

    @diceParser = Parser.new("dice roller") do
      #-----------Lexer----------------------
      token(/\/\*(.|\n)*\*\//)#<--flerradskommentar matchas
      token(/\/\/(.)*$/) #<--enradskommentar matchas
      token(/\s+/) #<-- blanksteg matchas
      token(/-(\d+)/) {|m| m.to_i} #<-- negativa heltal matchas
      token(/-(\d+[.]\d+)/) {|m|m.to_f} #<-- negativa floattal matchas
      token(/\d+[.]\d+/) {|m| m.to_f} #<-- positiva floattal matchas
      token(/\d+/) {|m| m.to_i } #<-- poitiva heltal matchas
      token(/"[^\"]*"/) {|m| m } #<-- strängar i form av "innehåll" matchas
      token(/'[^\']*'/) {|m| m } #<-- strängar i form av 'innehåll' matchas
      token(/(\+|\-|\*|\/|!=|\.|%|&|\(|\)|\[|\]|\:|;|<=|!|>=|<|>|==|=|\,|<<,>>)/) {|m| m} #<-- enstaka specialtecken matchas
      token(/[a-zA-ZåäöÅÄÖ]+[a-zA-ZåäöÅÄÖ0-9_]*/) {|m| m} #<-- variabler matchas
      #----------------------------------------

      #-----------programdefinition--------------------
      start :program do
        match('start',:statements,'slut') {|_,satser,_,_| satser}
      end
	
      rule :statements do
        match(:statement){|sats| sats }
        match(:statements,:statement){|satser,sats|
          satser += sats
          satser}
      end

      rule :statement do
        match(:array_add_element){|array_add|[array_add]}
        match(:array_remove_by_index){|array_remove_ele|[array_remove_ele]}
        match(:array_remove_by_value){|array_remove_value|[array_remove_value]}
        match(:return){|re|[re]}
        match(:function){|func|[func]}
        match(:function_call){|func|[func]}
        match(:break) {|b| [b]}
        match(:print) {|print| [print]}
        match(:if_block) {|if_rule| [if_rule]}
        match(:while_loop) {|while_loop| [while_loop]}
        match(:for_loop) {|for_loop| [for_loop]}
        match(:assign) {|assign| [assign]}
        match(:start_assign) {|start_assign| [start_assign]}
      end
      #-------------------------------------------------
	
      rule :print do
        match('skriv', :array_indexing){|_,print|
          Print_node.new(print)}
        match('skriv', :string_adding){|_,print|
          Print_node.new(print)}
        match('skriv', :string){|_,print|
          Print_node.new(print)}
        match('skriv', :expr) {|_,print|
          Print_node.new(print)}
      end

      rule :identifier do
        match(/[a-zA-ZåäöÅÄÖ]+[a-zA-ZåäöÅÄÖ0-9_]*/)  {|var|
          Variable_node.new(var)
        }
      end
      
      #--------------------Funktionersrelaterade regler---------------
      rule :function do
        match('inget','funktion',/[a-zA-ZåäöÅÄÖ]+[a-zA-ZåäöÅÄÖ0-9_]*/,'(',:parameters,')',:statements,'slut'){|type,_,func_name,_,para,_,satser,_|
          Function_node.new(type,func_name,para,satser)}
        match('inget','funktion',/[a-zA-ZåäöÅÄÖ]+[a-zA-ZåäöÅÄÖ0-9_]*/,'(',')',:statements,'slut'){|type,_,func_name,_,_,satser,_|
          Function_node.new(type,func_name,[],satser)}		
        match('tal','funktion',/[a-zA-ZåäöÅÄÖ]+[a-zA-ZåäöÅÄÖ0-9_]*/,'(',')',:statements,'slut'){|type,_,func_name,_,_,satser,_|
          Function_node.new(type,func_name,[],satser)}
        match('tal','funktion',/[a-zA-ZåäöÅÄÖ]+[a-zA-ZåäöÅÄÖ0-9_]*/,'(',:parameters,')',:statements,'slut'){|type,_,func_name,_,para,_,satser,_|
          Function_node.new(type,func_name,para,satser)}
        match('sträng','funktion',/[a-zA-ZåäöÅÄÖ]+[a-zA-ZåäöÅÄÖ0-9_]*/,'(',')',:statements,'slut'){|type,_,func_name,_,_,satser,_|
          Function_node.new(type,func_name,[],satser)}
        match('sträng','funktion',/[a-zA-ZåäöÅÄÖ]+[a-zA-ZåäöÅÄÖ0-9_]*/,'(',:parameters,')',:statements,'slut'){|type,_,func_name,_,para,_,satser,_|
          Function_node.new(type,func_name,para,satser)}
      end

      rule :function_call do
        match(:identifier ,'(',')'){|name,_,_|
          Function_call_node.new(name,[])}		
        match(:identifier ,'(',:parameters,')'){|name,_,para,_|
          Function_call_node.new(name,para)}
      end

      rule :return do
	match('returnera',:string){|_,expr|
          Return_node.new(expr)}
        match('returnera',:expr){|_,expr|
          Return_node.new(expr)}

      end

      rule :parameters do
        match(:parameter){|para|
          [para]}
        match(:parameters,',',:parameter){|paras,_,para|
          paras+ [para]}
      end
	
      rule :parameter  do
	match(:string){|assign|
          assign}
        match(:expr){|assign|
          assign}
      end
      #--------------------------------------------------

      #-------------Loopar-------------------------------
      rule :while_loop do
        match("medans",'(',:boolean_expression,')',:statements,'slut'){|_,_,bool,_,satser,_|
          While_node.new(bool,satser)}
      end
	
      rule :for_loop do
        match("får",'(',:boolean_expression,:assign,')',:statements,'slut'){|_,_,bool,assign,_,satser,_|
          For_node.new(bool,assign,satser) }
      end
	
	
      rule :break do
        match("avbryt"){|_|
          Break_node.new() }
      end
      #----------------------------------------------------
	    
      #-------If-statement regler-------------------------------
      rule :if_block do
        match(:if_rule){|if_stms|
          If_node.new(if_stms)}
      end


      rule :if_rule do
        match(:if,:else_if,:else_,'slut'){|ifstmt,elsestmt,else_,_|
          [ifstmt]+elsestmt+[else_]}
        match(:if,:else_,'slut'){|ifstmt,else_,_|
          [ifstmt]+[else_]}

        match(:if,:else_if,'slut'){|ifstmt,elsestmt,_|
          [ifstmt]+elsestmt}

        match(:if,'slut'){|ifstmt,_|
          [ifstmt]}
      end

      rule :if do
        match('om','(',:boolean_expression ,')',:statements) {|_,_,bool,_,satser|
          If_block_handler.new(bool,satser)}
      end

      rule :else_if do
        match('annars_om','(',:boolean_expression ,')',:statements){|_,_,bool,_,satser|
          [If_block_handler.new(bool,satser)]}
        match(:else_if,:else_if){|else_if,else_if2|
          else_if+= else_if2}
      end

      rule :else_ do
        match('annars',:statements) {|_,satser|
          a = Expr_node.new("<", Atom_node.new(1),Atom_node.new(2) )
          If_block_handler.new(a,satser) }
      end
      #--------------------------------------------------------

      #-----------------Boolenska uttryck ---------------------
      rule :boolean_expression do
        match(:expr, '<', :expr) {|num1, _, num2|
          Expr_node.new("<", num1,num2 )}
        match(:expr, '>', :expr) {|num1, _, num2|
          Expr_node.new(">", num1,num2 )}
        match(:expr, '<=', :expr) {|num1, _, num2|
          Expr_node.new("<=", num1,num2 )}
        match(:expr, '>=', :expr) {|num1, _, num2|
          Expr_node.new(">=", num1,num2 )}
        match(:expr, '!=', :expr) {|num1, _, num2|
          Expr_node.new("!=", num1,num2 )}
        match(:expr, '==', :expr) {|num1, _, num2|
          Expr_node.new("==", num1,num2 )}
        match(:boolean_expression, 'och', :boolean_expression) {|num1, _, num2|
          Expr_node.new("and", num1,num2 )}
        match('inte', :boolean_expression) {|_, num2|
          Expr_node.new("not",num2,num2 )}
        match(:boolean_expression, 'eller', :boolean_expression) {|num1, _, num2|
          Expr_node.new("or", num1,num2 )}
        match(:boolean_expression, 'antingen_eller', :boolean_expression) {|num1, _, num2|
          Expr_node.new("xor", num1,num2 )}
      end
      #-------------------------------------------------

      #-----------Arrayrelaterade regler----------------
      rule :array_size do
        match('storlek_på',:identifier){|_,array|
          Array_size_node.new(array)}
      end

      rule :array_indexing do
        match(:identifier ,'[',:expr,']'){|array,_,index,_|
          Array_index_node.new(array,index)}
      end

      rule :array_add_element do
	match(:identifier ,'lägg_till',:string){|array,_,string|
          Array_add_node.new(array,string)}
        match(:identifier ,'lägg_till',:expr){|array,_,expr|
          Array_add_node.new(array,expr)}
      end

      rule :array_remove_by_index do
        match(:identifier ,'ta_bort_index',:expr){|array,_,index|
          Array_remove_index_node.new(array,index)}
      end

      rule :array_remove_by_value do
	match(:identifier ,'ta_bort_värde',:string){|array,_,value|
          Array_remove_value_node.new(array,value)}
        match(:identifier ,'ta_bort_värde',:expr){|array,_,value|
          Array_remove_value_node.new(array,value)}
      end

      rule :array do
        match('[',:array_values,']'){|_,array,_|
          Array_node.new(array)}
      end

      rule :array_values do
        match(:string){|expr|
          [expr]}
        match(:array_values,',',:string){|exprs,_,string|
          exprs+[string]}
        match(:expr){|expr|
          [expr]}
        match(:array_values,',',:expr){|exprs,_,expr|
          exprs+[expr]}
      end
      #--------------------------------------------------------

      #----------Tilldelningsregler---------------------------
      rule :start_assign do
        match('sträng',:identifier ,'=',:string_adding){|_,var, _, string|
          AssignStart_node.new(var,string)}
        match('tal',:identifier ,'=',:expr){|_,var, _, expr|
          AssignStart_node.new(var,expr)}
        match('bool',:identifier ,'=',:boolean_expression){|_,var, _, string|
          AssignStart_node.new(var,string)}
        match('sträng',:identifier ,'=',:string){|_,var, _, string|
          AssignStart_node.new(var,string)}
        match('lista',:identifier ,'=',:array){|_,var,_,array|
          AssignStart_node.new(var,array)}
      end
	
      rule :assign do
        match(:identifier ,'=',:string_adding){|var,_,string|
          Assign_node.new(var,string)}
        match(:identifier ,'=',:expr){|var, _, expr|
          Assign_node.new(var,expr)}
        match(:identifier ,'=',:boolean_expression){|var, _, string|
          Assign_node.new(var,string)}
        match(:identifier ,'=',:string){|var, _, string|
          Assign_node.new(var,string)}
        match(:identifier ,'=',:array){|var,_,array|
          Assign_node.new(var,array)}
      end
      #------------------------------------------
	
      #----------relgler får strängar och addering av strängar---
      rule :string do
        match(:function_call)
        match(/"[^\"]*"/) {|str|
          string = Atom_node.new(str.slice(1,str.length-2))}
        match(/'[^\']*'/) {|str|
          string = Atom_node.new(str.slice(1,str.length-2))}
        match(:identifier ){|var|
          var}
      end

      rule :string_adding do
        match(:string, '&', :string) {|str1, _, str2|
          Expr_node.new("&", str1, str2)}
	match(:string_adding, '&', :string) {|str1, _, str2|
          Expr_node.new("&", str1, str2)}
      end
      #---------------------------------------------------------

      #----------regler får matematiska uträkningar-------------
      rule :term do
        match(:term, '*', :atom) {|term, _, atom|
          Expr_node.new('*', term,atom)}
        match(:term, '/', :atom) {|term, _, atom|
          Expr_node.new('/', term,atom)}
        match(:term, '%', :atom) {|term, _, atom|
          Expr_node.new("%", term, atom)}
        match(:function_call)
        match(:atom)
      end

      rule :expr do
        match(:expr, '+', :term) {|expr, _, term|
          Expr_node.new("+", expr, term)}
        match(:expr, '-', :term) {|expr, _, term|
          Expr_node.new("-", expr, term)}
        match(:term)
      end
      #-------------------------------------------------------

      #-----------regel får datatypen tal---------------------
      rule :atom do
        match(:array_indexing)
        match(:array_size)
        match(:array_size)
        match(:function_call)
        match(Float) {|float| 
          Atom_node.new(float.to_f)}
        match(Integer) {|int|
          Atom_node.new(int.to_i)}
        match('(',:expr,')'){|_,expr,_|
          expr}
        match(:identifier ){|var|
          var}
      end
      #--------------------------------------------------------
    end

  end

  def done(str)
    ["quit","exit","bye",""].include?(str.chomp)
  end


  def run(file)
    @result = Array.new()
    file = File.read(file)
    @result = @diceParser.parse(file)
    @result
  end

  def log(state = true)
    if state
      @diceParser.logger.level = Logger::DEBUG
    else
      @diceParser.logger.level = Logger::WARN
    end
  end

end

test = Swepp.new
test.run("swepp_01.swepp")

test.result.each do |elm|
	if elm.class != Function_node and elm.class != Function_call_node
		value = elm.seval()
		if value.class() == Hash and value.has_key?("_-_Return_node_-_")
			abort("ERROR: Man kan inte returnera utanför funktioner.")
		end
	elsif elm.class == Function_call_node
		elm.seval
	end
end