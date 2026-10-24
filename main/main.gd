extends Node2D

const ScreenStyle := preload("res://ui/screen_style.gd")
const TOWER_SCENE := "res://tower/tower.tscn"

@onready var _background: ColorRect = $UI/Background
@onready var _panel: PanelContainer = $UI/Center/Panel
@onready var _title: Label = $UI/Center/Panel/Body/Title
@onready var _play: Button = %PlayButton


func _ready() -> void:
	_background.color = ScreenStyle.BACKDROP
	ScreenStyle.paint_panel(_panel)
	ScreenStyle.paint_title(_title)
	ScreenStyle.paint_primary(_play)
	if Engine.is_editor_hint():
		return

	get_tree().paused = false
	_play.pressed.connect(_start)
	_play.grab_focus()


func _start() -> void:
	var err := get_tree().change_scene_to_file(TOWER_SCENE)
	if err != OK:
		push_error("Turm ließ sich nicht laden: %s" % error_string(err))
