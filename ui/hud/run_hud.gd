extends CanvasLayer

const ScreenStyle := preload("res://ui/screen_style.gd")
const NEGATIVE := Color(0.95, 0.45, 0.4)
const SOUL := Color(0.55, 0.9, 1.0)
const SHIELD := Color(1.0, 0.82, 0.28)

@onready var _points: Label = %PointsLabel
@onready var _souls: Label = %SoulsLabel
@onready var _shield: Label = %ShieldLabel
@onready var _world_button: Button = %WorldButton
@onready var _options_button: Button = %OptionsButton
@onready var _options_menu: OptionsMenu = $OptionsMenu


func _ready() -> void:
	ScreenStyle.paint_secondary(_world_button)
	ScreenStyle.paint_secondary(_options_button)
	_world_button.pressed.connect(GameData.toggle_world)
	_options_button.pressed.connect(_open_options)
	GameData.run_changed.connect(_refresh)
	GameData.world_changed.connect(_refresh_world)
	GameData.reset_run()
	_refresh_world(GameData.world)
	_bind_player_shield()
	_refresh_shield(0)


func _refresh() -> void:
	_points.text = "Punkte  %d" % GameData.points
	_souls.text = "Seelen  %d" % GameData.souls
	var point_color := ScreenStyle.CREAM if GameData.points >= 0 else NEGATIVE
	_points.add_theme_color_override("font_color", point_color)
	_souls.add_theme_color_override("font_color", SOUL)


func _refresh_world(_world: GameData.World) -> void:
	_world_button.text = "Normal" if _world == GameData.World.GHOST else "Geisterwelt"


func _refresh_shield(charges: int) -> void:
	_shield.text = "Schild  %d" % charges
	_shield.add_theme_color_override("font_color", SHIELD if charges > 0 else ScreenStyle.CREAM)


func _bind_player_shield() -> void:
	var player := _find_player()
	if player == null:
		return
	if not player.shield_changed.is_connected(_refresh_shield):
		player.shield_changed.connect(_refresh_shield)
	_refresh_shield(player.shield_charges)


func _find_player() -> Player:
	var root := get_tree().current_scene
	if root == null:
		root = get_parent()
	if root == null:
		return null
	if root is Player:
		return root as Player
	var named := root.find_child("Player", true, false)
	if named is Player:
		return named as Player
	var players := root.find_children("*", "Player", true, false)
	if players.is_empty():
		return null
	return players[0] as Player


func _open_options() -> void:
	_options_menu.open(true)
