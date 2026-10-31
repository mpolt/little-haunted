extends Node2D

## Richtet Patrouille-/Fluggrenzen ein und lädt bei Tod neu.

const EDGE_MARGIN := 16.0
const PATROL_INSET := 24.0


func _ready() -> void:
	get_tree().paused = false
	_setup_enemy($Enemies/Zombie as Enemy, $Platforms/ZombiePlatform as Platform)
	_setup_flyer($Enemies/Bat as Enemy)
	_setup_flyer($Enemies/Spook as Enemy)

	var player := $Player as Player
	if player:
		player.died.connect(_on_player_died)


func _setup_enemy(enemy: Enemy, platform: Platform) -> void:
	if enemy == null or platform == null:
		return
	var half := _half_width(platform)
	var x := platform.global_position.x
	enemy.setup_bounds(x - half + PATROL_INSET, x + half - PATROL_INSET)


func _setup_flyer(enemy: Enemy) -> void:
	if enemy == null:
		return
	var width := get_viewport().get_visible_rect().size.x
	if width < 1.0:
		width = float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	enemy.setup_bounds(EDGE_MARGIN, width - EDGE_MARGIN)


func _half_width(platform: Platform) -> float:
	var shape_node := platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is RectangleShape2D:
		var rect := shape_node.shape as RectangleShape2D
		return rect.size.x * 0.5 * absf(platform.global_scale.x)
	return 100.0


func _on_player_died() -> void:
	var player := $Player as Player
	if player:
		player.reset_after_death()
	get_tree().reload_current_scene()
