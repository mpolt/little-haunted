extends Node

enum Scheme { KEYBOARD, JOYSTICK, TOUCH }

const _CONFIG_PATH := "user://settings.cfg"
const _SECTION := "input"
const _KEY_SCHEME := "scheme"

signal scheme_changed(scheme: Scheme)

## Von Touch-Steuerung geschrieben (−1 … 1). Bei Tastatur-Modus immer 0.
var virtual_axis: float = 0.0

var scheme: Scheme = Scheme.KEYBOARD


func _ready() -> void:
	_load_or_default()


func steer() -> float:
	var keys := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(keys):
		return keys
	return virtual_axis


func set_scheme(value: Scheme) -> void:
	if scheme == value:
		return
	scheme = value
	if scheme == Scheme.KEYBOARD:
		virtual_axis = 0.0
	scheme_changed.emit(scheme)
	save()


func save() -> void:
	var config := ConfigFile.new()
	config.load(_CONFIG_PATH)
	config.set_value(_SECTION, _KEY_SCHEME, int(scheme))
	config.save(_CONFIG_PATH)


func _load_or_default() -> void:
	var config := ConfigFile.new()
	var err := config.load(_CONFIG_PATH)
	if err == OK and config.has_section_key(_SECTION, _KEY_SCHEME):
		var stored: Variant = config.get_value(_SECTION, _KEY_SCHEME)
		if typeof(stored) == TYPE_INT and int(stored) >= 0 and int(stored) <= int(Scheme.TOUCH):
			scheme = int(stored) as Scheme
			return
	scheme = (
		Scheme.JOYSTICK
		if DisplayServer.is_touchscreen_available()
		else Scheme.KEYBOARD
	)
	save()
