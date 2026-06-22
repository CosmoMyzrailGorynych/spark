# 🎇 Spark — Reactive state for Godot 4

Reactive state management for Godot 4, inspired by Svelte's runes. Declare state, derive computed values, create side effects, and bind everything to your UI (or gameplay-related nodes!) — all with minimal boilerplate.

**Features:**

* Typed reactive properties through short constructors (`S.int`, `S.str`, `S.bool`, etc.)
* Reactive computed values and effects
* Reactive bindings, including two-way bindings, too!
* `S.array` and `S.dict` for reactive collections
* `S.each` and `S.each_key` to automagically manage lists of nodes from arrays and dictionaries!

## 📥 Installation

Download through [Godot Store](https://store.godotengine.org/asset/comigo-games/spark/) or [Github](https://github.com/CosmoMyzrailGorynych/spark/archive/refs/heads/main.zip), unzip, and copy the `spark` folder into your project's `addons/` folder. Enable the plugin in **Project > Project Settings > Plugins**.

## 🙌 Need help? Found a bug?

Feel free to [start a discussion](https://github.com/CosmoMyzrailGorynych/spark/discussions) and [report issues](https://github.com/CosmoMyzrailGorynych/spark/issues) in the Github repo of this project.

## 🐇 Quick start

```gdscript
extends Control

@onready var label: Label = %Label

var count := S.int(0) # Declare a reactive property

func _ready():
	# Creates a binding context
	# (Helps to keep bindings and effects in memory and with cleanup)
	S.declare([
		# Automatically updates the label's text when `count` changes
		S.bind_label(count, label),
		# Runs each time `count` changes
		S.effect(func(): print("Count is: ", count.value)),
	]).bind(self) # Bind the context to the current node
				  # so everything is freed when a node leaves the scene.

	# Get/change values with `your_reactive_prop.value`
	count.value += 1
```

## 🧑‍🏫 Examples

See `addons/spark/examples/`:

| Example | Demonstrates |
|---------|-------------|
| **counter** | `S.computed`, `S.effect`, bindings (two-way and one-way) |
| **todo** | `S.array`, creating UI elements with `S.each`; `S.computed`, one-way bindings |
| **keyvalue** | `S.dict`, creating UI elements with `S.each_key`; `S.computed`, one-way bindings |

## ☝️🤓 A short introduction to Spark and reactive programming

Reactive programming is a coding pattern that revolves around **reactive properties**:
data containers that automatically subscribe dependencies that need to update when
the value inside the data container changes. The data can be simple atomic values
like ints or strings, or complex nested structures, or just references to Resources and such.

To make use of these reactive properties, you use ***effects***. Effects are predicates (Callables)
that re-run each time a reactive property it uses changes. For example, you can
run a bouncy animation on a "money" label every time a player spends or earns money.
Or you can simply log values with them to see what's going on.

There are additional handy tools for making reactive UI and other game entities
that can be seen in many UI libraries for web:

* **Bindings** are similar to effects as they update values of other objects (Controls, for example)
  when the value in a reactive property changes. Additionally, some bindings
  are bidirectional — meaning that they change the reactive property when a player
  inputs a new value in a Control.
* **Computed** (or derived) values: these calculate their values based on other reactive
  properties (through a Callable). They are reactive as well and can be used in effects
  an in one-way bindings.

Besides that, Spark provides additional helpers tailored for Godot:

* **Scopes**: small objects that keep state, effects and bindings in memory
  and that can be torn down either manually or when its bound node leaves a scene.
* **S.each** and **S.each_key** to automatically create and remove nodes (like UI cards)
  for each entry in a reactive Dictionary or Array.

## 📑 API Reference

Every method for creating scopes, reactive properties, and effects, can be accessed
through the `S` namespace ⤵️

### 📔 State factories

The first step is creating a reactive property. `S` has methods to create typed containers,
as well as `S.state(value)` for automatic type inference.

| Method | Returns | Description |
|--------|---------|-------------|
| `S.state(value)` | `SparkReactiveBase` | Infers the typed state class from `typeof(value)` |
| `S.bool(v)` | `SparkBool` | Reactive `bool` |
| `S.int(v)` | `SparkInt` | Reactive `int` |
| `S.float(v)` | `SparkFloat` | Reactive `float` |
| `S.string(v)` | `SparkString` | Reactive `String` |
| `S.array(v)` | `SparkArray` | Reactive `Array` with mutation helpers |
| `S.dict(v)` | `SparkDict` | Reactive `Dictionary` with mutation helpers |
| `S.variant(v)` | `SparkVariant` | Reactive untyped `Variant` |

Every state type exposes:
- `value` — get/set the current value. Reading inside a tracked context (computed / effect)
automatically registers as a dependency.
- `peek()` — returns the value without registering a dependency.


#### 🧬 Additional mutation methods

State is not deeply reactive. To simplify writing to `SparkArray` and `SparkDict`,
use their instance methods instead of mutating the encapsulated values:

* `SparkArray`: `set_at`, `append`, `remove_at`, `insert`, `pop_back`, `pop_front`, `erase`, `clear`, `shuffle`, `filter`
* `SparkDict`: `set_key`, `erase`, `clear`, `merge`

Most mutation methods of `SparkArray` and `SparkDict` match the methods of Array
and Dictionary types, with few differences:

* `set_at` and `set_key` are replacements for `my_prop.value[index] = new_value`.
  This ensures the changes are propagated.
* The `filter` method of `SparkArray`, contrary to Array's `filter`, does not return
  a new array but changes the encapsulated array in-place.

#### 🛎️ Manual updates for arrays and dictionaries (`poke()`)

Sometimes you need to insert a large group of rows into a `SparkArray`,
or set many key-value pairs into `SparkDict`. Doing that through the mutator methods
will cause updates for each inserted value, thus sometimes it is better to use
the encapsulated array's/dictionary's methods directly through, say, `my_array.value.append(row)`,
and notify the subscribers at the end with `my_array.poke()`. This method does nothing besides
notifying its subscribers about a change.

### 🧮 Computed (or derived) values

```gdscript
S.computed(fn: Callable) -> SparkComputed
```

Creates a derived value that *re-evaluates lazily* when its dependencies change.
These are read-only.

```gdscript
var doubled := S.computed(func(): return count.value * 2)
var label_text := S.computed(func (): return "x × 2 = %s" % doubled.value)
```

The passed Callable will run only if its state is dirty (meaning that the state
it was subscribed to was changed) and if something requests this computed value.
Thanks to that, computed values can be safely used for heavy calculations
that are not requested often.

The exception for this rule is when something is bound to this computed property,
for example when using `S.bind_label(my_computed, my_label)` to display its value
in UI.

### ✨ Effect

```gdscript
S.effect(fn: Callable) -> Callable
```

Runs `fn` immediately, and then re-runs it whenever its reactive dependencies change.
Returns a disposer `Callable` to stop the effect.

```gdscript
var dispose = S.effect(func(): print(count.value))
dispose.call()
```

### 🫣 Using reactive values without subscribing to them

Sometimes you may need to run an effect or create a computed value but don't necessarily need
to rerun it when certain values change. For that, instead of using `reactive_prop.value`,
you can use `reactive_prop.peek()` — this will return the encapsulated value
without registering this action as a dependency.

### 🔗 Property binding

Bindings are helper methods that subscribe to a reactive property and change the passed
object's property, and optionally to write data back from the object to the reactive state.
This frees you from creating effects and signal handlers.

Bindings are usually used to automatically update UI to reflect current values.
Two-way bindings also allow users to write new values directly to state.
For example, you can create one-way binding to display current HP as a text label
and a healthbar's value, and two-way binding for an input field of hero's name.

```gdscript
S.bind(reactive_prop, target_node, property_name, signal_name = "") -> Callable
```

Binds any `SparkReactiveBase` to any `Object` property. Provide a `signal_name` for two-way binding.

### 💆 Convenience bindings

Several methods simplify binding to common UI elements:

| Method | What for | Automatic value transform |
|--------|----------|---------------------------|
| `S.bind_label(src, target)` | One-way binding for Label and RichTextLabel | `str(v)` |
| `S.bind_text(src, target)` | **Two-way** binding for LineEdit, TextEdit, and other Controls with `text` as their value (listens to `text_changed`) | `str(v)` |
| `S.bind_valuef(src, target)` | **Two-way** binding for float value-based Controls. (Range subclasses like HSlider. Listens to `value_changed`.) | `float(v)` |
| `S.bind_visible(src, target, invert)` | One-way binding for `visible`. Works with any CanvasItem. | to `bool` w/ optional invert |
| `S.bind_disabled(src, target, invert)` | One-way binding for `disabled` value. Works with most Controls. | to `bool` w/ optional invert |
| `S.bind_color(src, target)` | One-way binding for `modulate` value. Works with any CanvasItem. | — |

### 📚 Iteration

These two methods simplify the creation of lists of items in your UI (or other nodes):

```gdscript
S.each(source: SparkArray, container: Node, factory: Callable, key_fn := Callable()) -> Callable
```

Watches a `SparkArray` and creates/destroys/reorders child nodes in `container` to match array contents.
`factory` receives `(item)` and must return a `Node`. An optional `key_fn(item, index)`
provides stable identity across re-renders (defaults to index).

💡 **Use `S.eachc`** if you need to pass a `SparkComputed` instead of a `SparkArray`.

```gdscript
S.each_key(source: SparkDict, container: Node, factory: Callable) -> Callable
```

Same as `S.each` but for `SparkDict`. Dictionary keys serve as stable identities. `factory` receives `(key, value)`.

💡 **Use `S.each_keyc`** if you need to pass a `SparkComputed` instead of a `SparkDict`.

### 🔍 Scope

```gdscript
S.declare(initial: Array[Callable]) -> SparkScope
```

Groups disposers for batch cleanup. This also keeps effects and bindings in memory,
so that they won't get cleaned up when you don't intend them to. Usually you will use them this way inside your `_ready` function:

```gdscript
S.declare([
	S.bind_label(count, label),
	S.effect(func(): print(count.value)),
	# Other bindings and effects…
]).bind(self)
```

`SparkScope` methods:
- `add(disposable)` — register another disposer
- `bind(node)` — connects an auto-cleanup action on node's `tree_exiting` signal.
  Also returns its `SparkScope`.
- `teardown()` — call all disposers immediately

### 👇 Manual memory management

`S.declare` is a very simple object with an array that holds all the references
to effects' and bindings' teardown Callables, thus keeping them in memory together.
Using `S.declare([...]).bind(self)` is usually enough for most UI components;
sometimes, you will need more granular approach: for example, when a group of Controls
exists only in a particular case. (E.g. a resource bar shows stored energy only if you
have batteries built.)

For that, you can use one of two methods:

#### 1) Store a reference to a `SparkScope` instance and call its `.teardown()` manually
```gdscript
@onready var battery_bar: Control = %BatteryBar
@onready var battery_stored: Label = %BatteryStorec
@onready var battery_max: Label = %BatteryMax

var scope_battery: SparkScope;
#...

func _ready():
	_create_battery_bindings()

func _on_building_destroyed():
	if GameBuildingsManager.by_type['Battery'].size() == 0:
		scope_battery.teardown()
		scope_battery = null
		battery_bar.visible = false
	elif !scope_battery:
		_create_battery_bindings()

func _create_battery_bindings():
	# Bindings create hard references to the used state variables,
	# so it's safe to declare them in a function and not as class members
	var energy_current = S.computed(...)
	var energy_max = S.computed(...)
	scope_battery = S.declare([
		# ...bindings to display a nice energy bar
	]).bind(self)
	battery_bar.visible = true
```

#### 2) Store references to disposers of effects / bindings instead
```gdscript
@onready var battery_bar: Control = %BatteryBar
@onready var battery_stored: Label = %BatteryStorec
@onready var battery_max: Label = %BatteryMax

var battery_disposers: Array[Callable] = []
# Can also store them individually

func _create_battery_bindings():
	# Bindings create hard references to the used state variables,
	# so it's safe to declare them in a function and not as class members
	var energy_current = S.computed(...)
	var energy_max = S.computed(...)
	battery_disposers = [
		S.bind_label(energy_current, battery_stored),
		S.bind_label(energy_max, battery_max),
	 	# ...other bindings to display a nice energy bar
	]

func _on_building_destroyed():
	if GameBuildingsManager.by_type['Battery'].size() == 0:
		for disposer in battery_disposers:
			disposer()
		battery_disposers = []
		battery_bar.visible = false
	elif battery_disposers.is_empty():
		_create_battery_bindings()
```

## 📜 License

MIT
