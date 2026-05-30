class_name SparkResource
extends SparkReactiveBase

## The current [Resource] value. Reading inside a tracked context (computed/effect)
## automatically registers this state as a dependency.
var value: Resource:
	get = _get_value,
	set = _set_value
var _value: Resource


func _init(default_value: Resource = null):
	_value = default_value


func _get_value() -> Resource:
	if S._tracking_context != null and S._tracking_context != self:
		S._tracking_context._add_dependency(self)
	return _value


func _set_value(new_value: Resource) -> void:
	if _value == new_value:
		return
	_value = new_value
	_notify()


## Returns the current value without creating a dependency subscription.
func peek() -> Resource:
	return _value
