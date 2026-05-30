class_name SparkEffect
extends RefCounted

var _fn: Callable
var _dependencies: Array[SparkReactiveBase] = []
var _active: bool = true


func _init(fn: Callable):
	_fn = fn
	_run()


func _add_dependency(dep: SparkReactiveBase) -> void:
	if not _dependencies.has(dep):
		_dependencies.append(dep)
		dep.subscribe(_on_dependency_changed)


func _on_dependency_changed() -> void:
	if not _active:
		return

	for dep in _dependencies:
		dep.unsubscribe(_on_dependency_changed)
	_dependencies.clear()

	_run()


func _run() -> void:
	if not _active or not _fn.is_valid():
		return

	var prev_context = S._tracking_context
	S._tracking_context = self
	_fn.call()
	S._tracking_context = prev_context


## Stops the effect, unsubscribes from all dependencies, and clears internal state.
func stop() -> void:
	_active = false
	for dep in _dependencies:
		dep.unsubscribe(_on_dependency_changed)
	_dependencies.clear()


## Returns the [member stop] method as a [Callable] disposer.
func get_disposer() -> Callable:
	return stop
