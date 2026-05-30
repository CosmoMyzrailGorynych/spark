class_name SparkDictWatcher
extends RefCounted

var _state: Variant
var _container_ref: WeakRef
var _factory: Callable
var _node_map: Dictionary = {}
var _ordered_keys: Array = []
var _ordered_nodes: Array = []
var _disposed: bool = false
var _state_sub: Callable
var _node_exited_sub: Callable


func _init(
	state: Variant,
	container: Node,
	factory: Callable,
):
	_state = state
	_container_ref = weakref(container)
	_factory = factory

	_state_sub = _on_state_changed
	state.subscribe(_state_sub)

	_node_exited_sub = _dispose
	container.tree_exited.connect(_node_exited_sub)

	_rebuild()


func _on_state_changed() -> void:
	if _disposed:
		return
	_rebuild()


func _rebuild() -> void:
	var container = _container_ref.get_ref()
	if container == null:
		_dispose()
		return

	var new_dict = _state.value
	if not new_dict is Dictionary:
		new_dict = {}

	var new_keys = new_dict.keys()
	var new_node_map = {}
	var new_ordered_nodes = []

	for key in new_keys:
		var val = new_dict[key]

		if _node_map.has(key):
			var node = _node_map[key]
			_node_map.erase(key)
			new_node_map[key] = node
			new_ordered_nodes.append(node)
		else:
			var node = _factory.call(key, val)
			if node == null:
				push_error("Spark: S.each_key factory returned null")
				continue
			new_node_map[key] = node
			new_ordered_nodes.append(node)
			container.add_child(node)

	for key in _node_map:
		var node = _node_map[key]
		if is_instance_valid(node):
			container.remove_child(node)
			node.queue_free()

	_node_map = new_node_map
	_ordered_keys = new_keys
	_ordered_nodes = new_ordered_nodes

	for i in range(1, _ordered_nodes.size()):
		var prev = _ordered_nodes[i - 1]
		var curr = _ordered_nodes[i]
		if curr.get_index() <= prev.get_index():
			container.move_child(curr, prev.get_index() + 1)


func _dispose() -> void:
	if _disposed:
		return
	_disposed = true

	_state.unsubscribe(_state_sub)

	if _node_exited_sub.is_valid():
		var container = _container_ref.get_ref()
		if container != null:
			if container.is_connected("tree_exited", _node_exited_sub):
				container.disconnect("tree_exited", _node_exited_sub)

	for key in _node_map:
		var node = _node_map[key]
		if is_instance_valid(node):
			if _container_ref.get_ref() != null:
				_container_ref.get_ref().remove_child(node)
			node.queue_free()

	_node_map.clear()
	_ordered_keys.clear()
	_ordered_nodes.clear()


## Returns the [method _dispose] method as a [Callable] disposer.
func get_disposer() -> Callable:
	return _dispose
