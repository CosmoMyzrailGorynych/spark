extends Control

@onready var label: Label = %Label
@onready var doubled_label: Label = %DoubledLabel
@onready var increment_btn: Button = %IncrementBtn
@onready var decrement_btn: Button = %DecrementBtn
@onready var reset_btn: Button = %ResetBtn
@onready var slider: HSlider = %Slider

var count := S.int(0)
var doubled := S.computed(func(): return count.value * 2)

func _ready():
	S.declare([
		S.bind_label(count, label),
		S.bind_label(doubled, doubled_label),
		S.bind_disabled(count, reset_btn, true),
		S.bind_valuef(count, slider),
		S.effect(func (): print(count.value)),
	]).bind(self)

	increment_btn.pressed.connect(func(): count.value += 1)
	decrement_btn.pressed.connect(func(): count.value -= 1)
	reset_btn.pressed.connect(func(): count.value = 0)
