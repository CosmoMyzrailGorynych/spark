class_name SparkComputed
extends SparkReactiveBase

## The current computed value. Re-evaluates lazily when dependencies change.
var value:
	get = _get_value
var _compute_fn: Callable
var _cached_value
var _dirty: bool = true
var _dependencies: Array[SparkReactiveBase] = []
var _evaluating: bool = false


func _init(compute_fn: Callable):
	_compute_fn = compute_fn


func _get_value():
	if _dirty:
		_evaluate()
	if S._tracking_context != null and S._tracking_context != self:
		S._tracking_context._add_dependency(self)
	return _cached_value


func _evaluate() -> void:
	if _evaluating:
		push_error("Spark: Circular dependency detected in SparkComputed")
		return
	_evaluating = true

	for dep in _dependencies:
		dep.unsubscribe(_on_dependency_changed)
	_dependencies.clear()

	var prev_context = S._tracking_context
	S._tracking_context = self
	_cached_value = _compute_fn.call()
	S._tracking_context = prev_context

	_dirty = false
	_evaluating = false


func _on_dependency_changed() -> void:
	_dirty = true
	_notify()


func _add_dependency(dep: SparkReactiveBase) -> void:
	if not _dependencies.has(dep):
		_dependencies.append(dep)
		dep.subscribe(_on_dependency_changed)


## Returns the current cached value without creating a dependency tracking
## subscription or re-evaluating if dirty.
func peek():
	if _dirty:
		_evaluate()
	return _cached_value
