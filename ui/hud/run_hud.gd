extends CanvasLayer

const ScreenStyle := preload("res://ui/screen_style.gd")
const NEGATIVE := Color(0.95, 0.45, 0.4)
const SOUL := Color(0.55, 0.9, 1.0)

@onready var _points: Label = %PointsLabel
@onready var _souls: Label = %SoulsLabel
@onready var _options_button: Button = %OptionsButton
@onready var _options_menu: OptionsMenu = $OptionsMenu


func _ready() -> void:
	ScreenStyle.paint_secondary(_options_button)
	_options_button.pressed.connect(_open_options)
	GameData.run_changed.connect(_refresh)
	GameData.reset_run()


func _refresh() -> void:
	_points.text = "Punkte  %d" % GameData.points
	_souls.text = "Seelen  %d" % GameData.souls
	var point_color := ScreenStyle.CREAM if GameData.points >= 0 else NEGATIVE
	_points.add_theme_color_override("font_color", point_color)
	_souls.add_theme_color_override("font_color", SOUL)


func _open_options() -> void:
	_options_menu.open(true)
