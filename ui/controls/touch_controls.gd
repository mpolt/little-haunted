extends Control

const _JOY_RADIUS := 72.0
const _KNOB_RADIUS := 28.0

@onready var _joystick: Control = %Joystick
@onready var _base: Panel = %JoystickBase
@onready var _knob: Panel = %JoystickKnob
@onready var _pads: Control = %Pads
@onready var _left_pad: Button = %LeftPad
@onready var _right_pad: Button = %RightPad

var _joy_pointer: int = -1
var _left_held := false
var _right_held := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_pads()
	_style_joystick()
	_joystick.gui_input.connect(_on_joystick_gui_input)
	_left_pad.button_down.connect(func() -> void: _left_held = true; _update_pad_axis())
	_left_pad.button_up.connect(func() -> void: _left_held = false; _update_pad_axis())
	_right_pad.button_down.connect(func() -> void: _right_held = true; _update_pad_axis())
	_right_pad.button_up.connect(func() -> void: _right_held = false; _update_pad_axis())
	Settings.scheme_changed.connect(_on_scheme_changed)
	visibility_changed.connect(_on_visibility_changed)
	resized.connect(_place_joystick)
	_on_scheme_changed(Settings.scheme)
	call_deferred("_place_joystick")


func _exit_tree() -> void:
	_clear_axis()


func _input(event: InputEvent) -> void:
	if _joy_pointer < 0 or not _joystick.visible:
		return
	if event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _joy_pointer:
		_set_knob_from_local(_joystick_local((event as InputEventScreenDrag).position))
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed and touch.index == _joy_pointer:
			_release_joystick()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _joy_pointer == 0:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_set_knob_from_local(_joystick_local(motion.position))
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and _joy_pointer == 0:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
			_release_joystick()
			get_viewport().set_input_as_handled()


func _on_scheme_changed(scheme: Settings.Scheme) -> void:
	_clear_axis()
	match scheme:
		Settings.Scheme.JOYSTICK:
			show()
			_joystick.show()
			_pads.hide()
		Settings.Scheme.TOUCH:
			show()
			_joystick.hide()
			_pads.show()
		_:
			hide()


func _on_visibility_changed() -> void:
	if not visible:
		_clear_axis()


func _on_joystick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _joy_pointer >= 0:
			return
		if not _point_in_base(event.position):
			return
		_joy_pointer = event.index
		_set_knob_from_local(event.position)
		_joystick.accept_event()
	elif event.index == _joy_pointer:
		_release_joystick()
		_joystick.accept_event()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if _joy_pointer >= 0:
		return
	if not _point_in_base(event.position):
		return
	_joy_pointer = 0
	_set_knob_from_local(event.position)
	_joystick.accept_event()


func _update_pad_axis() -> void:
	var axis := 0.0
	if _left_held:
		axis -= 1.0
	if _right_held:
		axis += 1.0
	Settings.virtual_axis = axis


func _set_knob_from_local(local_pos: Vector2) -> void:
	var center := _base_center_in_joystick()
	var offset := local_pos - center
	offset.y = 0.0
	if offset.length() > _JOY_RADIUS:
		offset = offset.normalized() * _JOY_RADIUS
	_knob.position = center + offset - Vector2(_KNOB_RADIUS, _KNOB_RADIUS)
	Settings.virtual_axis = clampf(offset.x / _JOY_RADIUS, -1.0, 1.0)


func _release_joystick() -> void:
	_joy_pointer = -1
	_reset_knob()
	Settings.virtual_axis = 0.0


func _clear_axis() -> void:
	_joy_pointer = -1
	_left_held = false
	_right_held = false
	_reset_knob()
	Settings.virtual_axis = 0.0


func _reset_knob() -> void:
	if not is_instance_valid(_knob) or not is_instance_valid(_base):
		return
	var center := _base_center_in_joystick()
	_knob.position = center - Vector2(_KNOB_RADIUS, _KNOB_RADIUS)


func _base_center_in_joystick() -> Vector2:
	return _base.position + Vector2(_JOY_RADIUS, _JOY_RADIUS)


func _point_in_base(local_pos: Vector2) -> bool:
	return local_pos.distance_to(_base_center_in_joystick()) <= _JOY_RADIUS * 1.35


func _joystick_local(viewport_pos: Vector2) -> Vector2:
	return _joystick.get_global_transform_with_canvas().affine_inverse() * viewport_pos


func _style_pads() -> void:
	for pad: Button in [_left_pad, _right_pad]:
		pad.focus_mode = Control.FOCUS_NONE
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.17, 0.13, 0.24, 0.45)
		normal.border_color = Color(0.45, 0.39, 0.56, 0.7)
		normal.set_border_width_all(2)
		normal.set_corner_radius_all(18)
		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = Color(0.88, 0.46, 0.22, 0.55)
		pressed.border_color = Color(0.96, 0.93, 0.88, 0.85)
		pad.add_theme_stylebox_override("normal", normal)
		pad.add_theme_stylebox_override("hover", normal)
		pad.add_theme_stylebox_override("pressed", pressed)
		pad.add_theme_stylebox_override("focus", pressed)
		pad.add_theme_color_override("font_color", Color(0.96, 0.93, 0.88, 0.85))
		pad.add_theme_color_override("font_pressed_color", Color(0.96, 0.93, 0.88, 1.0))
		pad.add_theme_font_size_override("font_size", 36)


func _style_joystick() -> void:
	var base_box := StyleBoxFlat.new()
	base_box.bg_color = Color(0.17, 0.13, 0.24, 0.4)
	base_box.border_color = Color(0.45, 0.39, 0.56, 0.75)
	base_box.set_border_width_all(3)
	base_box.set_corner_radius_all(int(_JOY_RADIUS))
	_base.add_theme_stylebox_override("panel", base_box)
	_base.custom_minimum_size = Vector2(_JOY_RADIUS * 2.0, _JOY_RADIUS * 2.0)
	_base.size = _base.custom_minimum_size
	_base.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var knob_box := StyleBoxFlat.new()
	knob_box.bg_color = Color(0.88, 0.46, 0.22, 0.85)
	knob_box.border_color = Color(0.96, 0.93, 0.88, 0.9)
	knob_box.set_border_width_all(2)
	knob_box.set_corner_radius_all(int(_KNOB_RADIUS))
	_knob.add_theme_stylebox_override("panel", knob_box)
	_knob.custom_minimum_size = Vector2(_KNOB_RADIUS * 2.0, _KNOB_RADIUS * 2.0)
	_knob.size = _knob.custom_minimum_size
	_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	_joystick.focus_mode = Control.FOCUS_NONE


func _place_joystick() -> void:
	if not is_instance_valid(_joystick):
		return
	var area_size := Vector2(_JOY_RADIUS * 2.0 + 48.0, _JOY_RADIUS * 2.0 + 48.0)
	_joystick.size = area_size
	_joystick.position = Vector2(
		(size.x - area_size.x) * 0.5,
		size.y - area_size.y - 24.0
	)
	_base.position = Vector2(24.0, 24.0)
	if _joy_pointer < 0:
		_reset_knob()
