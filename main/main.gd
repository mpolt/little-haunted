extends Node2D

const ScreenStyle := preload("res://ui/screen_style.gd")
const TOWER_SCENE := "res://tower/tower.tscn"
const OPTIONS_SCENE := preload("res://ui/options/options_menu.tscn")

@onready var _background: ColorRect = $UI/Background
@onready var _panel: PanelContainer = $UI/Center/VSplitContainer/Panel
@onready var _title: Label = $UI/Center/VSplitContainer/Panel/Body/Title
@onready var _play: Button = %PlayButton
@onready var _options: Button = %OptionsButton

@onready var t_platforms_button: Button = $UI/Center/VSplitContainer/PanelContainer/VBoxContainer/TPlatformsButton
@onready var t_items_button: Button = $UI/Center/VSplitContainer/PanelContainer/VBoxContainer/TItemsButton

var _options_menu: OptionsMenu


func _ready() -> void:
	_background.color = ScreenStyle.BACKDROP
	ScreenStyle.paint_panel(_panel)
	ScreenStyle.paint_title(_title)
	ScreenStyle.paint_primary(_play)
	ScreenStyle.paint_secondary(_options)
	if Engine.is_editor_hint():
		return

	get_tree().paused = false
	_options_menu = OPTIONS_SCENE.instantiate()
	$UI.add_child(_options_menu)
	_play.pressed.connect(_start)
	_options.pressed.connect(_open_options)
	_play.grab_focus()


func _start() -> void:
	var err := get_tree().change_scene_to_file(TOWER_SCENE)
	if err != OK:
		push_error("Turm ließ sich nicht laden: %s" % error_string(err))


func _open_options() -> void:
	_options_menu.open(false)


func _on_t_items_button_pressed() -> void:
	get_tree().change_scene_to_file("res://tests/test_items.tscn")


func _on_t_platforms_button_pressed() -> void:
	get_tree().change_scene_to_file("res://tests/test_platforms.tscn")
