extends Control

@onready var title_bar = $TitleBar
@onready var slots_container = $SlotsContainer

var slot_buttons = []
var is_horizontal = true

const SLOT_SIZE = 50
const SLOT_SPACING = 5

func _ready():
	for i in range(9):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_slot_pressed.bind(i))
		slots_container.add_child(btn)
		slot_buttons.append(btn)

	var toggle_btn = Button.new()
	toggle_btn.text = "⇄"
	toggle_btn.custom_minimum_size = Vector2(24, 24)
	toggle_btn.focus_mode = Control.FOCUS_NONE
	toggle_btn.position = Vector2(220, -2)
	toggle_btn.pressed.connect(_on_toggle_pressed)
	title_bar.add_child(toggle_btn)

	SkillBar.bar_changed.connect(_update_slots)
	_update_slots()
	_layout_slots()

func _on_toggle_pressed():
	is_horizontal = not is_horizontal
	_layout_slots()

func _layout_slots():
	for i in range(9):
		if is_horizontal:
			slot_buttons[i].position = Vector2(i * (SLOT_SIZE + SLOT_SPACING), 0)
		else:
			slot_buttons[i].position = Vector2(0, i * (SLOT_SIZE + SLOT_SPACING))

func _on_slot_pressed(index):
	SkillBar.use_slot(index)

func _update_slots():
	for i in range(9):
		var skill = SkillBar.slots[i]
		slot_buttons[i].text = (str(i + 1) + "\n" + skill["name"]) if skill != null else str(i + 1)

func _unhandled_key_input(event):
	if event.pressed and not event.echo:
		match event.keycode:
			KEY_1: SkillBar.use_slot(0)
			KEY_2: SkillBar.use_slot(1)
			KEY_3: SkillBar.use_slot(2)
			KEY_4: SkillBar.use_slot(3)
			KEY_5: SkillBar.use_slot(4)
			KEY_6: SkillBar.use_slot(5)
			KEY_7: SkillBar.use_slot(6)
			KEY_8: SkillBar.use_slot(7)
			KEY_9: SkillBar.use_slot(8)
