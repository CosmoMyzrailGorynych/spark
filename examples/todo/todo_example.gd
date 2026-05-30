extends Control

@onready var input: LineEdit = %Input
@onready var add_btn: Button = %AddBtn
@onready var container: VBoxContainer = %Items
@onready var heading: Label = %Heading

# ID/Counter for new todo items. Make sure to set it before _make_todo calls!
var _next_id: int = 0

# Create an array state with prefilled items
var todos := S.array([
	_make_todo("Learn Godot"),
	_make_todo("Build something cool"),
])
# Computed variables for header's text.
var total := S.computed(func (): return todos.value.size())
var done := S.computed(func ():
	return todos.value.reduce(func (current: int, item: Dictionary) -> int:
		if item.done:
			return current + 1
		return current
	, 0)
)
# Computed values can derive from other computed values, too
var heading_text := S.computed(func (): return "To Do List (%s/%s)" % [done.value, total.value])


func _ready():
	# Create a binding context to keep the effects and other bindings in memory.
	S.declare([
		# Tells to watch the todos array and construct new nodes for the container
		# by calling the _render_todo function. _todo_key is required for S.each
		# to distinguish which items were added, or removed
		S.each(todos, container, _render_todo, _todo_key),
		# List the amount of items as well
		S.bind_label(heading_text, heading)
	]).bind(self)
	# bind(self) adds a listener to the node so that the binding context
	# self-destructs when the node leaves the tree

	add_btn.pressed.connect(_add_todo)
	input.text_submitted.connect(func(text: String): _add_todo())

func _add_todo() -> void:
	var text = input.text.strip_edges()
	if text.is_empty():
		return
	todos.append(_make_todo(text))
	input.clear()

func _make_todo(text: String) -> Dictionary:
	_next_id += 1
	return {"id": _next_id, "text": text, "done": false}


#region Making repeatable UI components
static func _todo_key(item: Dictionary, _idx: int) -> int:
	return item.get("id")

# Usually you will create a scene and instanciate it instead of manual node creation.
# For the example, we do it through code.
# In any way, the S.each method requires a factory function that returns a new node
# for a given value.
func _render_todo(item: Dictionary) -> Control:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var check = CheckBox.new()
	check.text = item.text
	check.button_pressed = item.done
	check.toggled.connect(func(pressed: bool): _toggle_done(item, pressed))
	hbox.add_child(check)

	var del = Button.new()
	del.text = "X"
	del.pressed.connect(func(): _remove_todo(item))
	hbox.add_child(del)

	return hbox
#endregion

func _toggle_done(item: Dictionary, pressed: bool) -> void:
	var key = _todo_key(item, 0)
	for i in todos.value.size():
		if _todo_key(todos.value[i], i) == key:
			var updated = todos.value[i].duplicate()
			updated.done = pressed
			todos.set_at(i, updated)
			return
func _remove_todo(item: Dictionary) -> void:
	# Note how the method above replaces entries;
	# We can't just use todos.erase(item) because of it.
	# But we can delete by a key!
	var key = _todo_key(item, 0)
	for i in todos.value.size():
		if _todo_key(todos.value[i], i) == key:
			todos.remove_at(i)
			return

func _on_nuke_btn_pressed() -> void:
	if todos.value.is_empty():
		return
	todos.remove_at(randi_range(0, todos.value.size() - 1))

func _on_filter_btn_pressed() -> void:
	todos.filter(func (item: Dictionary) -> bool:
		return !item.done
	)
