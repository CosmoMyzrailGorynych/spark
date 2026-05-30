extends Control

@onready var kv_container: VBoxContainer = %KvContainer
@onready var key_input: LineEdit = %KeyInput
@onready var value_input: LineEdit = %ValueInput
@onready var heading: Label = %Heading
@onready var add_btn: Button = %AddBtn

var entries := S.dict({
	"name": "Alice",
	"role": "Engineer",
	"city": "Tokyo",
})
var new_key := S.string()
var new_value := S.string()
var count := S.computed(func(): return "Key/Value List (%s entries)" % entries.value.size())

func _ready():
	S.declare([
		S.each_key(entries, kv_container, _make_keyval_row),
		S.bind_label(count, heading),
		S.bind_text(new_key, key_input),
		S.bind_text(new_value, value_input)
	]).bind(self)

func _add_entry() -> void:
	if new_key.value.is_empty() or new_value.value.is_empty():
		return
	entries.set_key(new_key.value, new_value.value)
	new_key.value = ''
	new_value.value = ''

	key_input.grab_focus()


func _on_clear_btn_pressed() -> void:
	entries.clear()

func _on_destroy_city_btn_pressed() -> void:
	entries.erase('city')

# Usually you will create a scene and instanciate it instead of manual node creation.
# For the example, we do it through code.
# In any way, the S.each_key method requires a factory function that returns a new node
# for a given value.
func _make_keyval_row(key, value):
	var hbox = HBoxContainer.new()

	var key_label = Label.new()
	key_label.text = str(key) + ":"
	key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(key_label)

	var val_label = Label.new()
	val_label.text = str(value)
	val_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(val_label)

	var del = Button.new()
	del.text = "×"
	del.pressed.connect(func(): entries.erase(key))
	hbox.add_child(del)

	return hbox
