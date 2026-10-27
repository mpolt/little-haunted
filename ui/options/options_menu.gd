extends CanvasLayer
class_name OptionsMenu

const ScreenStyle := preload("res://ui/screen_style.gd")

const _HINTS := {
	Settings.Scheme.KEYBOARD: "A, D oder Pfeiltasten zum Bewegen",
	Settings.Scheme.JOYSTICK: "Stick nach links und rechts neigen",
	Settings.Scheme.TOUCH: "Links und rechts tippen zum Bewegen",
}

signal closed

@onready var _root: Control = $Root
@onready var _dim: ColorRect = $Root/Dim
@onready var _panel: PanelContainer = $Root/Center/Panel
@onready var _title: Label = $Root/Center/Panel/Body/Header/Title
@onready var _hint: Label = $Root/Center/Panel/Body/HintRow/Hint
@onready var _keyboard: Button = %KeyboardButton
@onready var _joystick: Button = %JoystickButton
@onready var _touch: Button = %TouchButton
@onready var _close: Button = %CloseButton

var _pause_tree := false
var _was_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_style()
	if Engine.is_editor_hint():
		return

	_root.hide()
	_keyboard.pressed.connect(func() -> void: _select(Settings.Scheme.KEYBOARD))
	_joystick.pressed.connect(func() -> void: _select(Settings.Scheme.JOYSTICK))
	_touch.pressed.connect(func() -> void: _select(Settings.Scheme.TOUCH))
	_close.pressed.connect(close)
	_dim.gui_input.connect(_on_dim_input)
	for choice in [_keyboard, _joystick, _touch]:
		_watch_choice(choice)


func open(pause_tree: bool = false) -> void:
	_pause_tree = pause_tree
	Settings.virtual_axis = 0.0
	if _pause_tree:
		_was_paused = get_tree().paused
		get_tree().paused = true
	_refresh()
	_root.show()
	_close.grab_focus()


func close() -> void:
	if not _root.visible:
		return
	_root.hide()
	if _pause_tree:
		get_tree().paused = _was_paused
		_pause_tree = false
	closed.emit()


func _on_dim_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		pressed = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if not pressed:
		return
	close()
	_dim.accept_event()


func _select(next: Settings.Scheme) -> void:
	Settings.set_scheme(next)
	_refresh()


func _refresh() -> void:
	var scheme := Settings.scheme
	_paint_choice(_keyboard, scheme == Settings.Scheme.KEYBOARD)
	_paint_choice(_joystick, scheme == Settings.Scheme.JOYSTICK)
	_paint_choice(_touch, scheme == Settings.Scheme.TOUCH)
	_hint.text = _HINTS[scheme]


func _paint_choice(button: Button, selected: bool) -> void:
	var held := button.button_pressed
	var hovered := button.is_hovered()
	var focused := button.has_focus()
	var border := Color(0.42, 0.34, 0.58, 0.85)
	var fill := Color(0.13, 0.07, 0.2, 0.94)
	var border_width := 2
	var glow := 0
	if selected:
		border = Color(0.75, 0.46, 1.0)
		fill = Color(0.28, 0.12, 0.42, 0.96)
		border_width = 3
		glow = 12
	if hovered and not held:
		border = border.lightened(0.16)
	if held:
		fill = fill.darkened(0.12)
	if focused and not selected:
		border = ScreenStyle.CREAM
	var box := _choice_box(fill, border, border_width, glow)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, box)
	var caption := button.get_node(^"Column/Caption") as Label
	caption.add_theme_color_override("font_color", ScreenStyle.CREAM)
	var badge := button.get_node(^"Check") as CanvasItem
	badge.visible = selected


func _choice_box(fill: Color, border: Color, border_width: int, glow: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(14)
	box.content_margin_left = 6.0
	box.content_margin_right = 6.0
	box.content_margin_top = 6.0
	box.content_margin_bottom = 4.0
	if glow > 0:
		box.shadow_color = Color(0.55, 0.22, 1.0, 0.55)
		box.shadow_size = glow
	return box


func _watch_choice(button: Button) -> void:
	var refresh := func() -> void: _refresh()
	button.mouse_entered.connect(refresh)
	button.mouse_exited.connect(refresh)
	button.focus_entered.connect(refresh)
	button.focus_exited.connect(refresh)
	button.button_down.connect(refresh)
	button.button_up.connect(func() -> void: _refresh.call_deferred())


func _apply_style() -> void:
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = Color(0.09, 0.045, 0.15, 0.96)
	panel_box.set_border_width_all(0)
	panel_box.set_corner_radius_all(22)
	panel_box.content_margin_left = 18.0
	panel_box.content_margin_right = 12.0
	panel_box.content_margin_top = 12.0
	panel_box.content_margin_bottom = 16.0
	panel_box.shadow_color = Color(0, 0, 0, 0.5)
	panel_box.shadow_size = 18
	panel_box.shadow_offset = Vector2(0, 8)
	_panel.add_theme_stylebox_override("panel", panel_box)
	ScreenStyle.paint_title(_title)
	ScreenStyle.paint_hint(_hint)
	_paint_close(_close)
	for choice in [_keyboard, _joystick, _touch]:
		_paint_badge(choice.get_node(^"Check") as Panel)
	_refresh()


func _paint_badge(badge: Panel) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.48, 0.28, 0.95)
	box.border_color = Color(0.92, 0.86, 1.0)
	box.set_border_width_all(1)
	box.set_corner_radius_all(14)
	badge.add_theme_stylebox_override("panel", box)


func _paint_close(button: Button) -> void:
	var font := ScreenStyle.CREAM
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_focus_color", font)
	button.add_theme_stylebox_override("normal", _circle_box(Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.38)))
	button.add_theme_stylebox_override("hover", _circle_box(Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.72)))
	button.add_theme_stylebox_override("pressed", _circle_box(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.5)))
	button.add_theme_stylebox_override("focus", _circle_box(Color(1, 1, 1, 0.16), ScreenStyle.CREAM))


func _circle_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.anti_aliasing = false
	box.set_border_width_all(1)
	box.set_corner_radius_all(20)
	box.content_margin_left = 0.0
	box.content_margin_right = 0.0
	box.content_margin_top = 0.0
	box.content_margin_bottom = 0.0
	return box
