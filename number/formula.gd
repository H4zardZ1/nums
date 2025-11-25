extends RefCounted
class_name FormulaRef
# This is ripped off from Profectus's formula handling method. https://github.com/profectus-engine/Profectus/tree/5c1152460f04a25dd4a5fbd2a09fa13b413123be/src/game/formulas
# I just stored it a bit differently so you can just substitute whatever you want (except numbers) on the formula itself
# Here be dragons. I've lost count of how many times *the godot itself crashed* trying to open this project (lmao)


static var operation_names_indices: Dictionary[String, int] = {
	"add": 0,
	"sub": 1,
}
# ## Operation Definitions. Each operation has the following properties:[br]
# ## - "evaluate" refers to how the operation is evaluated.
# ## - "inverse" refers to how to calculate the input given a targetted result.
# ## - "integrate" refers to how the operation's integral is evaluated.
# ## 
# ##
# ## [br]If the existing operations are insufficient for your needs, create a custom operation by implementing your own evaluation, inversion, and integration functions.
# ## For spending resources, the integral formula must be invertible.
# ## [br][b]Warning:[/b]
# ## Make sure that the evaluate, inverse and integration accepts the number Dictionary form, as that is what will be used.
static var operation_definitions: Array[Dictionary] = [
	# # Passthrough
	# {
	# 	"evaluate": BigNumRef.duplicate_num_only,
	# 	"inverse": BigNumRef.duplicate_num_only,
	# 	"apply_substitution": BigNumRef.duplicate_num_only
	# 	"integrate":
	# },
	# Add
	{
		"evaluate": BigNumRef.g_add,
		"inverse": invert_add,
		# "iterate": iterate_add,
		"apply_substitution": BigNumRef.duplicate_num_only_no_normalize,
		"as_str": "{0}+{1}",
		"as_rich_str": "{0} + {1}",
	},
	# Subtract
	{
		"evaluate": BigNumRef.g_sub,
		"as_str": "{0}-{1}",
		"as_rich_str": "{0} - {1}"
	},
]
## If filled, calling [method antiderivated] on constants will return the formula[code]constant * variable[/code].
## Otherwise, they will return the formula [code]0[/code].[br]
## [b]Warning:[/b] Changing this value does not reset cached constant integrals.
static var variable_name_on_constant_antiderivatives: String = "x"

static var default_direct_sum: int = 7

static func invert_add(target: Dictionary, n1: Dictionary, n2: Dictionary) -> Dictionary:
	if BigNumRef.g_is_nan(n2): # Right Side (constant+x)
		return BigNumRef.g_sub(target, n1)
	else: # x is deeper into the formula.
		return BigNumRef.g_sub(target, n2)

static func invert_sub(target: Dictionary, n1: Dictionary, n2: Dictionary) -> Dictionary:
	if BigNumRef.g_is_nan(n2): # Right Side (constant-x)
		return BigNumRef.g_add(target, n1)
	else: # x is deeper into the formula.
		return BigNumRef.g_sub(target, n2)

# ## Returns true if:[br]
# ## - [param t] does not start with a number;[br]
# ## - if [param t] starts with e, the e is not connected to a number when the repetition of e ends.[br]
# ## - if [param t] starts with e^, (e^, -(e^, f, - or |, the next character is not a number.
static func t_is_variable(t: String) -> bool:
	if ((t.length() > 1) and ((t[0] == "e") or (t[0] == "E"))):
		if ((t.length() > 1) and ((t[1] == "e") or (t[1] == "E"))):
			var i: int = 2
			while ((t.length() > i) and ((t[i] == "e") or (t[i] == "E"))):
				if ((t.unicode_at(i) >= 48) and (t.unicode_at(i) <= 57)):
					return false
				i += 1
			return true
		elif ((t.length() > 1) and (t[1] == "^")):
			return !((t.unicode_at(2) >= 48) and (t.unicode_at(2) <= 57))
		else:
			return true
	elif ((t.length() > 3) and (t.begins_with("(e^"))):
		return !((t.unicode_at(3) >= 48) and (t.unicode_at(3) <= 57))
	elif ((t.length() > 4) and (t.begins_with("-(e^"))):
		return !((t.unicode_at(4) >= 48) and (t.unicode_at(4) <= 57))
	elif ((t.length() > 1) and ((t[0] == "f") or (t[0] == "F") or t[0] == "-" or t[0] == "|")):
		return !((t.unicode_at(1) >= 48) and (t.unicode_at(1) <= 57))
	return !((t.unicode_at(0) >= 48) and (t.unicode_at(0) <= 57))

# ## Returns the id of the operation [param t] represents. A return value of -1 means that [param t] will be used as an operand.
# static func op_id(t: String) -> int:
# 	if (t.length() > 2) and (t[0] == "|"):
# 		var regex = RegEx.new()
# 		regex.compile("([0-9])+")
# 		var result := regex.search(t).get_string()
# 		if result.is_valid_int():
# 			return result.to_int()
# 	return -1



var numbers: Array[String] = []
var operations: Array[int] = []
# var step_source: Array[Dictionary] = []
# var step_operation_cuts: Array[int] = []
# type formula_content_allowed: String | Dictionary | int
# var content: Array = []
var internal_antiderivative: FormulaRef = null
# func _init(starting_value = null) -> void:
# 	if starting_value is Dictionary or starting_value is String or starting_value is int:
# 		content.push_back(starting_value)
# ## Returns the amount of [member numbers] that went unused. If negative, that means there are enough consuming operations for extra [member numbers] to be put in the formula.
func get_leftover() -> int:
	var result: int = numbers.size()
	for op in operations:
		result -= (operation_definitions[op].evaluate as Callable).get_argument_count() - 1
	return result
	
#func get_leftover() -> int:
	#var result: int = 0
	#for n in content:
		#if n is not int
			#result =+ 1
		#else:
			#result -= (operation_definitions[n].evaluate as Callable).get_argument_count() - 1
	#return result

#func get_numbers() -> Array[String]:
	#for n in content:
		#return content.filter(func(n): return FormulaRef.t_op_id(n) == -1)

#func get_operations() -> Array[int]:
	#for n in content:
		#return content.reduce(FormulaRef._get_operations_accum, [])

#static func _get_operations_accum(accum: Array, s: String):
	#var n := FormulaRef.t_op_id(s)
	#if n != -1:
		#accum.append(n)
	#return accum




func is_variable(at: int) -> bool:
	return FormulaRef.t_is_variable(numbers[at])

#func op_at(at: int) -> int:
	#return FormulaRef.op_id(content[at])

func has_variable() -> bool:
	return numbers.any(FormulaRef.t_is_variable)

## Calculates what value the variable inside the formula would have to be for it to be equal to [param target]. Only works if there's a single variable and if the formula is invertible.
## Additionally you can substitute other variables so that there is one variable left.
## Returns [code]NAN[/code] on failure.
func invert(target: Dictionary, substitutions: Dictionary[String, Dictionary] = {}) -> Dictionary:
	if operations.is_empty() and is_variable(0): # if f(x) = x then x = f(x)
		return BigNumRef.duplicate_num_only(target)
	
	if BigNumRef.g_is_nan(target):
		push_warning("Cannot invert NAN")
		return BigNumRef.from_float(NAN)


	var first_variable: bool = false
	var used_numbers: int = numbers.size() - max(get_leftover(), 0)
	for i in range(used_numbers):
		if is_variable(i) and (not substitutions.keys().has(numbers[i])) and first_variable == false:
			first_variable = true
		elif is_variable(i) and (not substitutions.keys().has(numbers[i])) and first_variable == true:
			assert(false, "'{0}'(which can be written as '{1}'): Failed to invert, returning NAN\n\
			Reason of failure: '{0}' has more than 1 variables".format([self, formula_as_str()]))
			return BigNumRef.from_float(NAN)
	if not first_variable:
		assert(false, "'{0}'(which can be written as '{1}'): Failed to invert, returning NAN\n\
		Reason of failure: '{0}' has 0 variables".format([self, formula_as_str()]))
		return BigNumRef.from_float(NAN)
	var target_held := BigNumRef.duplicate_num_only(target)


	
	var number_head: int = numbers.size() - 1
	var true_first_num: Dictionary = _constify(substitutions)
	var has_hit_variable: bool = false
	for op_index in range(operations.size(), -1, -1):
		if BigNumRef.g_is_nan(target_held):
			push_error("'{0}'(which can be written as '{1}'): Failed to invert '{2}' (written as '{3}'), returning NAN\n\
			Reason of failure: Unknown".format([self, formula_as_str(), target, BigNumRef.g_to_str(target)]))	
			return target_held
		var op_type: int = operations[op_index]
		var op: Dictionary = operation_definitions[op_type]
		var to_invert: Callable = op.inverse
		if not is_instance_valid(to_invert):
			assert("'{0}'(which can be written as '{1}'): Failed to invert, returning NAN\n\
			Reason of failure: Uninvertible operation '{2}'".format([self, formula_as_str(), op.as_str]))
			return BigNumRef.from_float(NAN)
		var inv_args: int = to_invert.get_argument_count()
		if inv_args == 1:
			target_held = to_invert.call(target_held)
			continue
		var num_args: Array[String] = [BigNumRef.g_to_str(target_held)]
		for arg_index in range(inv_args - 1):
			if (t_is_variable(numbers[number_head])) and (number_head != 0) and (arg_index < (inv_args - 1)):
				# We need to evaluate the left side of the formula!
				num_args.push_front(BigNumRef.g_to_str(true_first_num))
				has_hit_variable = true
			else:
				num_args.push_front(numbers[number_head])
			number_head -= 1
		to_invert.bindv(num_args).call(target_held)
		if has_hit_variable:
			break
	if BigNumRef.g_is_nan(target_held):
		push_error("'{0}'(which can be written as '{1}'): Failed to invert, returning NAN\n\
		Reason of failure: Unknown".format([self, formula_as_str()]))	
	return target_held

# func invert(target: Dictionary, substitutions: Dictionary[String, Dictionary] = {}) -> Dictionary:
# 	if get_operations().is_empty() and is_variable(0): # if f(x) = x then x = f(x)
# 		return BigNumRef.duplicate_num_only(target)
	
# 	if BigNumRef.g_is_nan(target):
# 		push_warning("Cannot invert NAN")
# 		return BigNumRef.from_float(NAN)

# 	var first_variable: bool = false
# 	for i in range(content.size()):
# 		if content is String and first_variable == false:
# 			first_variable = true
# 		elif content is String and first_variable == true:
# 			assert(false, "'{0}'(which can be written as '{1}'): Failed to invert, returning NAN\n\
# 			Reason of failure: '{0}' has more than 1 variables".format([self, formula_as_str()]))
# 			return BigNumRef.from_float(NAN)
# 	if not first_variable:
# 		assert(false, "'{0}'(which can be written as '{1}'): Failed to invert, returning NAN\n\
# 		Reason of failure: '{0}' has 0 variables".format([self, formula_as_str()]))
# 		return BigNumRef.from_float(NAN)
# 	var target_held := BigNumRef.duplicate_num_only(target)
#	
#	var head : int = 0
#	var num_stack: Array = []
#	var content_to_invert: Array = []
#	
#	# first we evaluate all the numbers that don't need to be inverted. (constantification phase)
#	while head < content.size():
#		if op_at(content[head]) == -1:
#			num_stack.push_back(content[head])
#		else:
#			var num_stack_to_evaluate: Array = []
#			var eval_result = null
#			
#			for i in range(operation_definitions(op_at(content[head])).evaluate.get_argument_count()):
#				num_stack_to_evaluate.push_back(num_stack.pop_back())
#				# only lunatics do it this way, I am a lunatic
#				if num_stack_to_evaluate[-1] is String:
#					eval_result = num_stack_to_evaluate[-1]
#			if eval_result: # We can't invert at this stage yet, we're just evaluating evaluatable stuff
#				var start_copy: int = head - operation_definitions(content[head])).evaluate.get_argument_count() - 1
#				for copy_head in range(start_copy, head):
#					content_to_invert.push_back(content[copy_head])
#			else:
#				var num_stack_to_evaluate_converted: Array[Dictionary] = num_stack_to_evaluate.duplicate()
#				eval_result = BigNumRef.g_to_str(operation_definitions(content[head])).evaluate.callv(num_stack_to_evaluate_converted))
#			num_stack.push_back(eval_result)
#		head += 1
#	# moving to the actual inversion
#	# we're working backwards from the outermost operation to the innermost operation
#	# this means we read it right(end)-to-left(start), with left-to-right prefix reading
#	# unfortunately there is no Callable().bind_left!
#	# so we need second_stack to store both the operators and the numbers.
#	# We except the variable to be in the innermost operation,
#	# as all other branches has been evaluated into a constant number by the first pass.
#	var second_stack: Array = []
#	var prev_op: Dictionary
#	var num_amount: int = 0
#	var has_hit_variable: bool = false
#	var innermost_op: bool = false
#	var target_held: Dictionary = BigNumRef.duplicate_num_only_no_normalize()
#	while not content_to_invert.is_empty():
	# var invert_pop = content_to_invert.pop_back()
	#if invert_pop is int:
		#prev_op = operation_definitions(invert_pop)
		#innermost_op = prev_op.evaluate.get_argument_count() <= content_to_invert.size() # If this is false then we're in the innermost operation.
		#num_stack = []
	#elif invert_pop is Dictionary:
		#num_amount += 1
		#num_stack.push_back(invert_pop)
	#else: # We hit the variable!
		#num_stack.push_back(BigNumRef.from_float(NAN))
	#second_stack.append(invert_pop)
	#if num_amount >= (prev_op.evaluate.get_argument_count() + (1 if not innermost_op else 0)):
		# Clean up the stack of previous operations that can be completed.
		#var continue_cascade: bool = true
		#while continue_cascade and head >= 0:
			#if not has_hit_variable:
				#num_stack.append(BigNumRef.from_float(NAN))
			#num_stack.reverse()
			#if not prev_op.has("inverse"):
				#assert("'{0}'(which can be written as '{1}'): Failed to invert, returning NAN\n\
				#Reason of failure: Uninvertible operation '{2}'".format([self, formula_as_str(), op.as_str]))
				#return BigNumRef.from_float(NAN)
			#target_held = prev_op.inverse.bindv(num_stack).call(target_held)
			#if BigNumRef.g_is_nan(target_held): 
				# We hit a special case where there are no(or in some cases, multiple) solutions for the given target
				#return target_held
			#for i in range(previous_eval_count + 1):
				#second_stack.pop_back()
			#head = second_stack.size() - 1
			#num_amount = 1
			#while true:
				#if second_stack[head] is int:
					#prev_op = operation_definitions(second_stack[head])
					#if prev_op.evaluate.get_argument_count() > num_amount:
						#continue_cascade = false
						#break
				#elif second_stack[head] is Dictionary:
					#num_stack.push_back(second_stack[head])
				#else:
					#num_stack.push_back(BigNumRef.from_float(NAN))
#	return target_held

# ## Get the formula's indefinite integral (also known as antiderivative, as shown in the function name). May also be invertible.
# ## Additionally you can substitute other variables so that there is one variable left.
#func antiderivated(substitutions: Dictionary[String, Dictionary] = {}) -> FormulaRef:
	#push_error("'{0}' (which can be written as '{1}'): failed to evaluate the formula's antiderivative, returning a constant NAN\n\
	#Reason of failure: Unknown".format([self, formula.as_str()]))
	#return FormulaRef.new(BigNumRef.from_float(NAN))

# ## 
#func invert_integral

# ## Evaluates the function, substituting all variables that is equal to the dictionary's key to the number's value.
func evaluate(substitutions: Dictionary[String, Dictionary] = {}) -> Dictionary:

	var true_numbers: Array[Dictionary] = _substitute_numbers(substitutions)
	var number_head: int = 0
	var number_held: Dictionary = true_numbers[0].duplicate()

	for op in operations:
		if BigNumRef.g_is_nan(number_held):
			push_error("'{0}'(which can be written as '{1}'): Failed to evaluate, returning NAN\n\
			Reason of failure: Unknown".format([self, formula_as_str()]))	
			return BigNumRef.duplicate_num_only(number_held)
		var to_evaluate: Callable = FormulaRef.operation_definitions[op].evaluate
		var eval_args: int = to_evaluate.get_argument_count()
		var num_args: Array[Dictionary] = [number_held.duplicate()]

		for arg in range(eval_args - 1):
			num_args.push_back(true_numbers[number_head + arg + 1])
		number_held = to_evaluate.callv(num_args)
		number_head += eval_args - 1

	return number_held

# func evaluate(substitutions: Dictionary[String, Dictionary] = {}) -> Dictionary:
# 

# Evaluates the function, substituting all variables that is equal to the dictionary's key to the number's value.
func _constify(substitutions: Dictionary[String, Dictionary] = {}) -> Dictionary:

	var true_numbers: Array[Dictionary] = _substitute_numbers(substitutions)
	var number_head: int = 0
	var number_held: Dictionary = true_numbers[0].duplicate()

	for op in operations:
		var to_evaluate: Callable = operation_definitions[op].evaluate
		var eval_args: int = to_evaluate.get_argument_count()
		var num_args: Array[Dictionary] = [number_held.duplicate()]

		for arg in range(eval_args - 1):
			num_args.push_back(true_numbers[number_head])
			number_head += 1
			if BigNumRef.g_is_nan(true_numbers[number_head]):
				return number_held
		number_held = to_evaluate.callv(num_args)
	return number_held

#Evaluates all values that are not relevant for a given remaining 

func _substitute_numbers(substitutions: Dictionary[String, Dictionary]) -> Array[Dictionary]:
	for key in substitutions.keys():
		if t_is_variable(key):
			substitutions.erase(key)
	var result: Array[Dictionary] = []
	for n in numbers:
		if n in substitutions.keys():
			result.push_back(substitutions[n])
		elif not t_is_variable(n):
			result.push_back(BigNumRef.from_str(n))
		else: # undefined variable.
			result.push_back(BigNumRef.from_float(NAN))
	return result

func _substitute_numbers_keep_variables(substitutions: Dictionary[String, Dictionary]) -> Array[String]:
	for key in substitutions.keys():
		if t_is_variable(key):
			substitutions.erase(key)
	var result: Array[String] = []
	for n in numbers:
		if n in substitutions.keys():
			result.push_back(BigNumRef.g_to_str(substitutions[n]))
		else:
			result.push_back(n)
	return result

# Return the number of [param n](as a Dictionary instead of a String), or if it is in subtitutions, the number that substitutes it.
# func _get_number_or_substitute(n: String, substitutions: Dictionary[String, Dictionary]) -> Dictionary:


func formula_as_str(rich: bool = false) -> String:
	if numbers.is_empty():
		return ""
	var result: String = numbers[0]
	var number_head: int = 0
	for op in operations:
		var to_format: String = operation_definitions[op].as_rich_str if (rich and operation_definitions[op].has("as_rich_str")) else operation_definitions[op].as_str
		var eval_args: int = operation_definitions[op].evaluate.get_argument_count()
		var num_args: Array[String] = [result]
		for arg in range(eval_args - 1):
			number_head += 1
			num_args.push_back(numbers[number_head])
		result = to_format.format(num_args)
	return result

# ## Adds [param variable_name] to the number content if it is a valid variable name.[br]
# ## [b]Warning[/b]: Variable name MUST not start with a number or:[br]
# ## -If [param variable_name] starts with e, the e is not connected to a number when the repetition of e ends.[br]
# ## -If [param variable_name] starts with e^, (e^, -(e^, f, - or |, the next character is not a number.
# ## (see [method t_is_variable]) [br]
# ## [b]Warning[/b]: The variable may be unused. Use [method get_leftover] to see if it is.
func insert_variable(variable_name: String) -> void:
	if (not variable_name.is_empty()) and (t_is_variable(variable_name)):
		numbers.push_back(variable_name)

func insert_variable_or_number(n: String) -> void:
	if (not n.is_empty()):
		numbers.push_back(n)

func insert_constant(number: Dictionary) -> void:
	numbers.push_back(BigNumRef.g_to_str(number))

func add(n: String = "") -> void:
	insert_variable_or_number(n)
	operations.push_back(0)
	
func custom_op(op: int, vars: Array[String] = []) -> void:
	for v in vars:
		insert_variable(v)
	operations.push_back(op)
	
