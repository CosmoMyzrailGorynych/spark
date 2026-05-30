class_name SparkArray
extends SparkReactiveBase

## The current [Array] value. Reading inside a tracked context (computed/effect)
## automatically registers this state as a dependency.
var value: Array:
	get = _get_value,
	set = _set_value
var _value: Array


func _init(default_value: Array = []):
	_value = default_value


func _get_value() -> Array:
	if S._tracking_context != null and S._tracking_context != self:
		S._tracking_context._add_dependency(self)
	return _value


func _set_value(new_value: Array) -> void:
	if _value == new_value:
		return
	_value = new_value
	_notify()


## Returns the current value without creating a dependency subscription.
func peek() -> Array:
	return _value


## Appends [param value] to the end of the array and notifies subscribers.
func append(value) -> void:
	_value.append(value)
	_notify()


## Removes the element at [param index] and notifies subscribers.
func remove_at(index: int) -> void:
	_value.remove_at(index)
	_notify()


## Inserts [param value] at [param index] and notifies subscribers.
func insert(index: int, value) -> void:
	_value.insert(index, value)
	_notify()


## Removes and returns the last element, then notifies subscribers.
## Returns [code]null[/code] if the array is empty.
func pop_back():
	if _value.is_empty():
		return null
	var result = _value.pop_back()
	_notify()
	return result


## Removes and returns the first element, then notifies subscribers.
## Returns [code]null[/code] if the array is empty.
func pop_front():
	if _value.is_empty():
		return null
	var result = _value.pop_front()
	_notify()
	return result


## Removes the first occurrence of [param value] and notifies subscribers.
func erase(value) -> void:
	if _value.has(value):
		_value.erase(value)
		_notify()


## Clears the array and notifies subscribers.
func clear() -> void:
	_value.clear()
	_notify()


## Sets the element at [param index] to [param value] and notifies subscribers.
func set_at(index: int, value) -> void:
	_value[index] = value
	_notify()


## Shuffles the array in-place and notifies subscribers.
func shuffle() -> void:
	_value.shuffle()
	_notify()


## Replaces the array with elements matching [param filter_fn] and notifies
## subscribers. See [method Array.filter] for details.
func filter(filter_fn: Callable) -> void:
	_value = _value.filter(filter_fn)
	_notify()

## Notifies the subscribers that there was an update of the value.
## Use it carefully and only if you work with complex nested structures,
## or push lots of items in one go.
## [br]
## Most of the time, you can use parallel reactive arrays instead of one reactive array
## of non-reactive objects, or you can create a reactive array of [i]reactive values[/i]
## that each notify its own subscribers.
## [br][br]
## Also note that there are many methods that mutate and automatically notify
## the subscribers without having to use [member value]:
## [method set_at], [method insert], [method append], [method erase] and so on.
func poke() -> void:
	_notify()
