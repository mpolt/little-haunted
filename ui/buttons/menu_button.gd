@tool
extends CanvasLayer

const ScreenStyle := preload("res://ui/screen_style.gd")
const MAIN_SCENE := "res://main/main.tscn"

## Szene, die der Button öffnet. Leer fällt auf das Hauptmenü zurück.
@export_file("*.tscn") var target_scene: String = MAIN_SCENE

@onready var _button: Button = $Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ScreenStyle.paint_secondary(_button)
	if Engine.is_editor_hint():
		return

	_button.pressed.connect(_open_target)


func _open_target() -> void:
	var path := target_scene if not target_scene.is_empty() else MAIN_SCENE
	# Der Pause-Zustand bleibt über den Szenenwechsel hinweg erhalten.
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Menü ließ sich nicht öffnen: %s" % error_string(err))
