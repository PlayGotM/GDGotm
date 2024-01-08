
static func are_resources_equal(lhs, rhs) -> bool:
	if lhs == rhs: 
		return true
	if !lhs || !rhs:
		return false
	if typeof(lhs) != typeof(rhs):
		return false
	if lhs is Array:
		if lhs.size() != rhs.size():
			return false
		for i in range(0, lhs.size()):
			if !are_resources_equal(lhs[i], rhs[i]):
				return false
		return true
	if lhs.get("id") && rhs.get("id"):
		return lhs.id == rhs.id
	return false


static func are_equal(lhs, rhs) -> bool:
	if typeof(lhs) != typeof(rhs):
		if lhs is int && rhs is float || lhs is float && rhs is int:
			return float(lhs) == float(rhs)
		return false
	if lhs is Array:
		if lhs.size() != rhs.size():
			return false
		for i in range(0, lhs.size()):
			if !are_equal(lhs[i], rhs[i]):
				return false
		return true
	return lhs == rhs



static func print_assertion(message: String, tag: String):
	if tag:
		tag = "[" + tag + "] "
	var stack = get_stack()
	printerr("ASSERTION FAILED: " + tag + message)
	while stack.size() > 1 && stack[0].source.ends_with("TestUtility.gd"):
		stack.pop_front()
	print("\tat")
	for frame in stack:
		print("\t", frame.source, ":", frame.line, " in function '" + frame.function + "'")


static func assert_resource_equality(resources, expected_resources, message: String = ""):
	if are_resources_equal(resources, expected_resources):
		return
	print_assertion("\nGot\n" + resource_to_string(resources) + "\nbut expected\n" + resource_to_string(expected_resources), message)

static func assert_equality(lhs, rhs, message: String = ""):
	if are_equal(lhs, rhs):
		return
	print_assertion("Got " + _GotmUtility.to_stable_json(lhs) + " but expected " + _GotmUtility.to_stable_json(rhs), message)

static func resource_to_string(resource) -> String:
	if resource is Array:
		var parts := []
		for res in resource:
			parts.append(resource_to_string(res))
		return "[" + _GotmUtility.join(parts, ",") + "]"
	if resource is Object:
		if resource.get("id"):
			return resource.id
		return resource.to_string()
	if resource == null:
		return "null"
	return String(resource)
