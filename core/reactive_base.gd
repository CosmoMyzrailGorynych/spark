@abstract
class_name SparkReactiveBase
extends RefCounted

var _subscribers: Array[Callable] = []


## Registers a [Callable] that will be called whenever this reactive value changes.
func subscribe(callable: Callable) -> void:
	if not _subscribers.has(callable):
		_subscribers.append(callable)


## Removes a previously subscribed [Callable].
func unsubscribe(callable: Callable) -> void:
	_subscribers.erase(callable)


func _notify() -> void:
	var subs = _subscribers.duplicate()
	for sub in subs:
		if sub.is_valid():
			sub.call()
	var i = 0
	while i < _subscribers.size():
		if not _subscribers[i].is_valid():
			_subscribers.remove_at(i)
		else:
			i += 1

func _add_dependency(_dep: SparkReactiveBase):
	pass
