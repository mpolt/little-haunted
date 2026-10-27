extends CanvasLayer

const ScreenStyle := preload("res://ui/screen_style.gd")
const NEGATIVE := Color(0.95, 0.45, 0.4)
const SOUL := Color(0.55, 0.9, 1.0)

@onready var _points: Label = %PointsLabel
@onready var _souls: Label = %SoulsLabel
@onready var _world_button: Button = %WorldButton


func _ready() -> void:
	ScreenStyle.paint_secondary(_world_button)
	_world_button.pressed.connect(GameData.toggle_world)
	GameData.run_changed.connect(_refresh)
	GameData.world_changed.connect(_refresh_world)
	GameData.reset_run()
	_refresh_world(GameData.world)


func _refresh() -> void:
	_points.text = "Punkte  %d" % GameData.points
	_souls.text = "Seelen  %d" % GameData.souls
	var point_color := ScreenStyle.CREAM if GameData.points >= 0 else NEGATIVE
	_points.add_theme_color_override("font_color", point_color)
	_souls.add_theme_color_override("font_color", SOUL)


func _refresh_world(_world: GameData.World) -> void:
	_world_button.text = "Normal" if _world == GameData.World.GHOST else "Geisterwelt"
