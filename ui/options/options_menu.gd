extends CanvasLayer
class_name OptionsMenu

const ScreenStyle := preload("res://ui/screen_style.gd")

signal closed

@onready var _root: Control = $Root
@onready var _panel: PanelContainer = $Root/Center/Panel
@onready var _title: Label = $Root/Center/Panel/Body/Title
@onready var _hint: Label = $Root/Center/Panel/Body/Hint
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
	Settings.scheme_changed.connect(_refresh_selection)


func open(pause_tree: bool = false) -> void:
	_pause_tree = pause_tree
	Settings.virtual_axis = 0.0
	if _pause_tree:
		_was_paused = get_tree().paused
		get_tree().paused = true
	_refresh_selection(Settings.scheme)
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


func _select(next: Settings.Scheme) -> void:
	Settings.set_scheme(next)
	_refresh_selection(next)


func _refresh_selection(scheme: Settings.Scheme) -> void:
	_paint_choice(_keyboard, scheme == Settings.Scheme.KEYBOARD)
	_paint_choice(_joystick, scheme == Settings.Scheme.JOYSTICK)
	_paint_choice(_touch, scheme == Settings.Scheme.TOUCH)


func _paint_choice(button: Button, selected: bool) -> void:
	if selected:
		ScreenStyle.paint_primary(button)
	else:
		ScreenStyle.paint_secondary(button)


func _apply_style() -> void:
	ScreenStyle.paint_panel(_panel)
	ScreenStyle.paint_title(_title)
	ScreenStyle.paint_hint(_hint)
	ScreenStyle.paint_secondary(_close)
	_refresh_selection(Settings.scheme)
