extends Area2D
class_name Platform

@export var boost: float = Player.BOOST_DEFAULT

@onready var _boost_animation: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var _sprite: Sprite2D = get_node_or_null("Visual/Platform") as Sprite2D

var _normal_texture: Texture2D
var _ghost_texture: Texture2D


func _ready() -> void:
	_cache_textures()
	_apply_world(GameData.world)
	GameData.world_changed.connect(_apply_world)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and body.jump(boost):
		if _boost_animation:
			_boost_animation.play(&"boost")


func _cache_textures() -> void:
	if _sprite == null or _sprite.texture == null:
		return
	_normal_texture = _sprite.texture
	_ghost_texture = _resolve_ghost(_normal_texture)


func _apply_world(world: GameData.World) -> void:
	if _sprite == null or _normal_texture == null:
		return
	_sprite.texture = _ghost_texture if world == GameData.World.GHOST else _normal_texture


func _resolve_ghost(normal: Texture2D) -> Texture2D:
	var path := normal.resource_path
	if path.is_empty() or "/ghost_world/" in path:
		return normal
	var ghost_path := path.get_base_dir().path_join("ghost_world").path_join(path.get_file())
	if not ResourceLoader.exists(ghost_path):
		return normal
	return load(ghost_path)
