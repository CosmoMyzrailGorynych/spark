class_name SparkBind
extends RefCounted

var _state: SparkReactiveBase
var _target_ref: WeakRef
var _property: String
var _signal_name: String
var _invert: bool
var _transform: Callable
var _disposed: bool = false
var _state_sub: Callable
var _signal_sub: Callable
var _node_exited_sub: Callable


func _init(
	state: SparkReactiveBase,
	target: Object,
	property: String,
	signal_name: String = "",
	invert: bool = false,
	transform: Callable = Callable()
):
	_state = state
	_target_ref = weakref(target)
	_property = property
	_signal_name = signal_name
	_invert = invert
	_transform = transform

	_state_sub = _on_state_changed
	state.subscribe(_state_sub)

	if target is Node:
		_node_exited_sub = _dispose
		target.tree_exited.connect(_node_exited_sub)

	_update_target()

	if signal_name != "" and target.has_signal(signal_name):
		_signal_sub = _on_target_changed
		target.connect(signal_name, _signal_sub)


func _on_state_changed() -> void:
	if _disposed:
		return
	_update_target()


func _on_target_changed(..._ignore) -> void:
	if _disposed:
		return
	_update_state()


func _update_target() -> void:
	var target = _target_ref.get_ref()
	if target == null:
		_dispose()
		return

	var val = _state.value
	if _invert:
		val = not val
	if _transform.is_valid():
		val = _transform.call(val)
	if val == target.get(_property):
		return
	target.set(_property, val)


func _update_state() -> void:
	var target = _target_ref.get_ref()
	if target == null:
		_dispose()
		return

	var val = target.get(_property)
	if _invert:
		val = not val

	_state.value = val


func _dispose() -> void:
	if _disposed:
		return
	_disposed = true

	_state.unsubscribe(_state_sub)

	if _signal_sub.is_valid():
		var target = _target_ref.get_ref()
		if target != null:
			if _signal_name != "" and target.has_signal(_signal_name):
				if target.is_connected(_signal_name, _signal_sub):
					target.disconnect(_signal_name, _signal_sub)

	if _node_exited_sub.is_valid():
		var target = _target_ref.get_ref()
		if target != null and target is Node:
			if target.is_connected("tree_exited", _node_exited_sub):
				target.disconnect("tree_exited", _node_exited_sub)


## Returns the [method _dispose] method as a [Callable] disposer.
func get_disposer() -> Callable:
	return _dispose
