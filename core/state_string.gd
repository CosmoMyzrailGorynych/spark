class_name SparkString
extends SparkReactiveBase

## The current [String] value. Reading inside a tracked context (computed/effect)
## automatically registers this state as a dependency.
var value: String:
	get = _get_value,
	set = _set_value
var _value: String


func _init(default_value: String = ""):
	_value = default_value


func _get_value() -> String:
	if S._tracking_context != null and S._tracking_context != self:
		S._tracking_context._add_dependency(self)
	return _value


func _set_value(new_value: String) -> void:
	if _value == new_value:
		return
	_value = new_value
	_notify()


## Returns the current value without creating a dependency subscription.
func peek() -> String:
	return _value
