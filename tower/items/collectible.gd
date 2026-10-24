extends Node
class_name Collectible

@export_range(0.0, 3.0) var light_energy_factor: float = 1.0:
	set(value):
		print('set')
		light_energy_factor = value
		_update_light()
		
@onready var light: PointLight2D = get_node_or_null("Visual/PointLight2D")
var base_energy: float

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

func _ready() -> void:
	if light:
		print('light.ready')
		base_energy = light.energy
		_update_light()


func _update_light() -> void:
	if not is_node_ready() or not light:
		return
	print('_update_light')
	light.energy = base_energy * light_energy_factor


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print('player')
		if animation_player:
			print('ap')
			animation_player.play("collect")
