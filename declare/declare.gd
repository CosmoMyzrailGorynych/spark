class_name SparkScope
extends RefCounted

## The list of disposer callables managed by this declaration.
var disposers: Array[Callable] = []
var _valid := true
var _exiting_tree := false
var _bind_listener: Callable
var _bind_node: WeakRef

func _init(initial: Array[Callable]) -> void:
	disposers.assign(initial)

## Registers an additional disposer callable to be called during teardown.
func add(disposable: Callable) -> void:
	if !_valid:
		push_error("Spark: Attempt to add a disposable to an already teardowned declaration")
		return
	disposers.append(disposable)

## Auto-teardown when [param node] exits the scene tree.
func bind(node: Node) -> SparkScope:
	if !_valid:
		push_error("Spark: Attempt to bind an already torndown declaration")
		return
	if _bind_node and _bind_node.get_ref():
		push_error("Spark: Attempt to bind a SparkScope to a node when the SparkScope is already bound to some node")
		return
	_bind_listener = func () -> void:
		_exiting_tree = true
		teardown()
	node.tree_exiting.connect(_bind_listener)
	_bind_node = weakref(node)
	return self

## Calls all registered disposers and marks the declaration as invalid.
func teardown() -> void:
	if !_valid and !_exiting_tree:
		push_error("Spark: Attempt to teardown an already torn down declaration. Reset your references!")
		return
	for d in disposers:
		d.call()
	disposers.clear()
	if _bind_node and _bind_node.get_ref():
		_bind_node.get_ref().tree_exiting.disconnect(_bind_listener)
		_bind_node = null
	_valid = false
