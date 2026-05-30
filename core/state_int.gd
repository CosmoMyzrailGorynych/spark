class_name SparkInt
extends SparkReactiveBase

## The current [int] value. Reading inside a tracked context (computed/effect)
## automatically registers this state as a dependency.
var value: int:
	get = _get_value,
	set = _set_value
var _value: int


func _init(default_value: int = 0):
	_value = default_value


func _get_value() -> int:
	if S._tracking_context != null and S._tracking_context != self:
		S._tracking_context._add_dependency(self)
	return _value


func _set_value(new_value: int) -> void:
	if _value == new_value:
		return
	_value = new_value
	_notify()


## Returns the current value without creating a dependency subscription.
func peek() -> int:
	return _value
