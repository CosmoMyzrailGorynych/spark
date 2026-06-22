class_name S
extends RefCounted


# --- Tracking context (used by SparkComputed / Effect for dependency tracking) ---
static var _tracking_context = null

## Holds strong references to all active [SparkEffect] instances so they
## are not garbage collected while running. Effects are removed when their
## disposer is called.
static var _effects: Array[SparkEffect] = []

## Registers a group of disposers into a [SparkScope] for batch cleanup.
## Call [method SparkScope.teardown] on the returned object to dispose
## all registered callables at once.
static func declare(initial: Array[Callable]) -> SparkScope:
	return SparkScope.new(initial)

# --- State factories ---

## Creates a reactive state variable inferring the type from the given value.
static func state(value = null) -> SparkReactiveBase:
	match typeof(value):
		TYPE_BOOL:
			return S.bool(value)
		TYPE_INT:
			return S.int(value)
		TYPE_FLOAT:
			return S.float(value)
		TYPE_STRING:
			return S.string(value)
		TYPE_DICTIONARY:
			return S.dict(value)
		TYPE_ARRAY:
			return S.array(value)
		TYPE_OBJECT:
			if is_instance_of(value, Resource):
				return S.resource(value)
			return S.variant(value)
		_:
			return S.variant(value)


## Creates a reactive [bool] state.
static func bool(default_value := false) -> SparkBool:
	return SparkBool.new(default_value)

## Creates a reactive [int] state.
static func int(default_value := 0) -> SparkInt:
	return SparkInt.new(default_value)

## Creates a reactive [float] state.
static func float(default_value := 0.0) -> SparkFloat:
	return SparkFloat.new(default_value)

## Creates a reactive [String] state.
static func string(default_value := "") -> SparkString:
	return SparkString.new(default_value)

## Creates a reactive [String] state.
static func resource(default_value: Resource = null) -> SparkResource:
	return SparkResource.new(default_value)

## Creates a reactive [Dictionary] state.
static func dict(default_value := {}) -> SparkDict:
	return SparkDict.new(default_value)

## Creates a reactive [Array] state.
static func array(default_value := []) -> SparkArray:
	return SparkArray.new(default_value)

## Creates a reactive untyped [Variant] state.
static func variant(default_value = null) -> SparkVariant:
	return SparkVariant.new(default_value)


# --- Computed ---

## Creates a derived reactive value that re-evaluates lazily when its
## dependencies change. The returned [SparkComputed] is read-only.
static func computed(compute_fn: Callable) -> SparkComputed:
	return SparkComputed.new(compute_fn)


# --- Effect ---

## Runs a function immediately and automatically re-runs it whenever its
## reactive dependencies change. Returns a disposer [Callable] to stop the effect.
static func effect(fn: Callable) -> Callable:
	var e = SparkEffect.new(fn)
	_effects.append(e)
	return func():
		e.stop()
		_effects.erase(e)


# --- Universal binding ---

## Binds a reactive state to any [Object] property. Optionally provide a
## [param signal_name] for two-way binding. Returns a disposer [Callable].
static func bind(
	source: SparkReactiveBase,
	target: Object,
	property: String,
	signal_name: String = ""
) -> Callable:
	var binder = SparkBind.new(source, target, property, signal_name)
	return func(): binder._dispose()


# --- Convenience bindings ---

## Binds state to a [Label] or [RichTextLabel] [code]text[/code] property.
## One-way: state → target.
static func bind_label(source: SparkReactiveBase, target: Object) -> Callable:
	var binder = SparkBind.new(source, target, "text", "", false, func(v): return str(v))
	return func(): binder._dispose()

## Binds state to a [LineInput] or another control's [code]text[/code] property
## of a [String] type with two-way sync.
## Connects to the [code]text_changed[/code] signal for target to update
## the bound state.
static func bind_text(source: SparkReactiveBase, target: Object) -> Callable:
	var binder = SparkBind.new(source, target, "text", "text_changed", false, func(v): return str(v))
	return func(): binder._dispose()

## Binds state to a [Range] or another control's [code]value[/code] property
## of a [float] type with two-way sync.
## Connects to the [code]value_changed[/code] signal for target to update
## the bound state.
static func bind_valuef(source: SparkReactiveBase, target: Object) -> Callable:
	var binder = SparkBind.new(source, target, "value", "value_changed", false, func(v): return float(v))
	return func(): binder._dispose()

## Binds state to a [Control]'s [code]visible[/code] property.
## If [param invert] is [code]true[/code], the visibility is inverted.
## One-way: state → target.
static func bind_visible(
	source: SparkReactiveBase,
	target: Object,
	invert: bool = false
) -> Callable:
	var binder = SparkBind.new(source, target, "visible", "", invert, func(v): return !!v)
	return func(): binder._dispose()


## Binds state to a [Control] [code]disabled[/code] property.
## If [param invert] is [code]true[/code], the disabled state is inverted.
## One-way: state → target.
static func bind_disabled(
	source: SparkReactiveBase,
	target: Object,
	invert: bool = false
) -> Callable:
	var binder = SparkBind.new(source, target, "disabled", "", invert, func(v): return !!v)
	return func(): binder._dispose()


## Binds state to a [CanvasItem]'s [code]modulate[/code] color property.
## One-way: state → target.
static func bind_color(source: SparkReactiveBase, target: Object) -> Callable:
	return bind(source, target, "modulate")


# --- Each (keyed array iteration) ---

## Watches a [SparkArray] and creates or destroys child nodes in the
## [param container] to match the array contents. The [param factory] is called
## for each new item and must return a [Node]. An optional [param key_fn]
## provides stable identity across re-renders. Returns a disposer [Callable].
static func each(
	source: SparkArray,
	container: Node,
	factory: Callable,
	key_fn: Callable = Callable()
) -> Callable:
	var watcher = SparkArrayWatcher.new(source, container, factory, key_fn)
	return func(): watcher._dispose()

## Watches a [SparkComputed] and creates or destroys child nodes in the
## [param container] to match its array's contents. The [param factory] is called
## for each new item and must return a [Node]. An optional [param key_fn]
## provides stable identity across re-renders. Returns a disposer [Callable].
static func eachc(
	source: SparkComputed,
	container: Node,
	factory: Callable,
	key_fn: Callable = Callable()
) -> Callable:
	var watcher = SparkArrayWatcher.new(source, container, factory, key_fn)
	return func(): watcher._dispose()

## Watches a [SparkDict] and creates or destroys child nodes in the
## [param container] to match the dictionary contents. The [param factory]
## is called for each new entry and receives [code](key, value)[/code].
## Dictionary keys serve as stable identities across re-renders.
## Returns a disposer [Callable].
static func each_key(
	source: SparkDict,
	container: Node,
	factory: Callable,
) -> Callable:
	var watcher = SparkDictWatcher.new(source, container, factory)
	return func(): watcher._dispose()

## Watches a [SparkComputed] with a dictionary and creates or destroys child nodes
## in the [param container] to match the dictionary contents. The [param factory]
## is called for each new entry and receives [code](key, value)[/code].
## Dictionary keys serve as stable identities across re-renders.
## Returns a disposer [Callable].
static func each_keyc(
	source: SparkComputed,
	container: Node,
	factory: Callable,
) -> Callable:
	var watcher = SparkDictWatcher.new(source, container, factory)
	return func(): watcher._dispose()
