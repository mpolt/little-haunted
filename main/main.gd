extends Node2D

const ScreenStyle := preload("res://ui/screen_style.gd")
const TOWER_SCENE := "res://tower/tower.tscn"
const OPTIONS_SCENE := preload("res://ui/options/options_menu.tscn")

@onready var _background: ColorRect = $UI/Background
@onready var _panel: PanelContainer = $UI/Center/VSplitContainer/Panel
@onready var _title: Label = $UI/Center/VSplitContainer/Panel/Body/Title
@onready var _play: Button = %PlayButton
@onready var _tower: TextureButton = %TowerButton
@onready var _options: Button = %OptionsButton
@onready var _test_platforms: Button = %TestPlatformsButton
@onready var _test_items: Button = %TestItemsButton
@onready var _flight: AnimationPlayer = $CanvasLayer/AnimationPlayer

var _options_menu: OptionsMenu
var _flying := false


func _ready() -> void:
	_background.color = ScreenStyle.BACKDROP
	ScreenStyle.paint_panel(_panel)
	ScreenStyle.paint_title(_title)
	ScreenStyle.paint_primary(_play)
	ScreenStyle.paint_secondary(_options)
	ScreenStyle.paint_secondary(_test_platforms)
	ScreenStyle.paint_secondary(_test_items)
	if Engine.is_editor_hint():
		return

	get_tree().paused = false
	_options_menu = OPTIONS_SCENE.instantiate()
	$UI.add_child(_options_menu)
	_play.pressed.connect(_fly_to_tower)
	_tower.pressed.connect(_fly_to_tower)
	_flight.animation_finished.connect(_on_arrived_at_tower)
	_options.pressed.connect(_open_options)
	_test_platforms.pressed.connect(func() -> void: _open_scene("res://tests/test_platforms.tscn"))
	_test_items.pressed.connect(func() -> void: _open_scene("res://tests/test_items.tscn"))
	_play.grab_focus()


func _fly_to_tower() -> void:
	if _flying:
		return
	_flying = true
	_tower.disabled = true
	_play.disabled = true
	_flight.play(&"to_tower")


func _on_arrived_at_tower(anim_name: StringName) -> void:
	if anim_name != &"to_tower":
		return
	var err := get_tree().change_scene_to_file(TOWER_SCENE)
	if err != OK:
		_flying = false
		_tower.disabled = false
		_play.disabled = false
		push_error("Turm ließ sich nicht laden: %s" % error_string(err))


func _open_options() -> void:
	_options_menu.open(false)


func _open_scene(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Szene ließ sich nicht laden: %s" % error_string(err))
