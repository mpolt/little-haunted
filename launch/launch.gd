extends Node2D

const OPTIONS_SCENE := preload("res://ui/options/options_menu.tscn")
const MAIN_SCENE := "res://main/main.tscn"

@onready var _play: BaseButton = $CanvasLayer/Screen/PlayButton
@onready var _settings: BaseButton = $CanvasLayer/Screen/SettingsButton

var _options_menu: OptionsMenu
var _changing_scene := false


func _ready() -> void:
	_options_menu = OPTIONS_SCENE.instantiate()
	$CanvasLayer.add_child(_options_menu)
	_play.pressed.connect(_on_play_pressed)
	_settings.pressed.connect(_on_settings_pressed)


func _on_play_pressed() -> void:
	if _changing_scene:
		return
	_changing_scene = true
	_play.disabled = true
	_settings.disabled = true
	var err := get_tree().change_scene_to_file(MAIN_SCENE)
	if err != OK:
		_changing_scene = false
		_play.disabled = false
		_settings.disabled = false
		push_error("Zielszene ließ sich nicht öffnen: %s" % error_string(err))


func _on_settings_pressed() -> void:
	if _changing_scene:
		return
	_options_menu.open(false)
