class_name SparkBool
extends SparkReactiveBase

## The current [bool] value. Reading inside a tracked context (computed/effect)
## automatically registers this state as a dependency.
var value: bool:
	get = _get_value,
	set = _set_value
var _value: bool


func _init(default_value: bool = false):
	_value = default_value


func _get_value() -> bool:
	if S._tracking_context != null and S._tracking_context != self:
		S._tracking_context._add_dependency(self)
	return _value


func _set_value(new_value: bool) -> void:
	if _value == new_value:
		return
	_value = new_value
	_notify()


## Returns the current value without creating a dependency subscription.
func peek() -> bool:
	return _value
