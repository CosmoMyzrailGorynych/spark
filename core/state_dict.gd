class_name SparkDict
extends SparkReactiveBase

## The current [Dictionary] value. Reading inside a tracked context (computed/effect)
## automatically registers this state as a dependency.
var value: Dictionary:
	get = _get_value,
	set = _set_value
var _value: Dictionary


func _init(default_value: Dictionary = {}):
	_value = default_value


func _get_value() -> Dictionary:
	if S._tracking_context != null and S._tracking_context != self:
		S._tracking_context._add_dependency(self)
	return _value


func _set_value(new_value: Dictionary) -> void:
	if _value == new_value:
		return
	_value = new_value
	_notify()


## Returns the current value without creating a dependency subscription.
func peek() -> Dictionary:
	return _value


## Sets [param key] to [param value] and notifies subscribers.
func set_key(key, value) -> void:
	_value[key] = value
	_notify()


## Removes the entry at [param key] and notifies subscribers.
## Returns [code]true[/code] if the key existed.
func erase(key) -> bool:
	if not _value.has(key):
		return false
	_value.erase(key)
	_notify()
	return true


## Clears the dictionary and notifies subscribers.
func clear() -> void:
	_value.clear()
	_notify()


## Merges a [Dictionary] [param other] into the current dictionary, and notifies subscribers.
## If [param overwrite] is [code]true[/code], existing keys are overwritten.
func merge(other: Dictionary, overwrite: bool = true) -> void:
	_value.merge(other, overwrite)
	_notify()

## Notifies the subscribers that there was an update of the value.
## Use it carefully and only if you work with complex nested structures,
## or set lots of keys in one go.
## [br][br]
## Also note that there are methods that mutate and automatically notify
## the subscribers without having to use [member value]:
## [method set_key], [method clear], [method merge], and [method erase].
func poke() -> void:
	_notify()
