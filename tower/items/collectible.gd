extends Area2D
class_name Collectible

## Einsammelbares Item. Die Grafik liegt unter Visual, die Collision bleibt außen,
## damit Flackern die Trefferfläche nicht mitbewegt.

## project.godot: 2d_physics/layer_3 = items
const PHYSICS_LAYER := 4

enum VanishStyle { PARTICLES, ASCEND }

@export var vanish_style: VanishStyle = VanishStyle.PARTICLES
@export var _particles: GPUParticles2D
@export var points: int = 0
@export var souls: int = 0
@export var glow: Color = Color(1.45, 1.12, 0.45)
@export var flicker_strength: float = 0.0
@export var pulse_speed: float = 2.2
@export_group("Halo")
@export var show_halo: bool = true
@export var halo_offset: Vector2 = Vector2.ZERO
@export var halo_scale: Vector2 = Vector2(1.2, 1.1)
@export var halo_color: Color = Color(1.0, 0.62, 0.16, 0.65)

@onready var _visual: Node2D = $Visual
@onready var _sprite: CanvasItem = $Visual/Sprite

var _halo: Sprite2D
var _halo_alpha: float
var _taken: bool = false
var _time: float = 0.0


func _ready() -> void:
	collision_layer = PHYSICS_LAYER
	collision_mask = Player.PHYSICS_LAYER
	z_index = 1
	_particles = get_node_or_null("GPUParticles2D") as GPUParticles2D
	_time = randf() * TAU
	_ensure_halo()
	if _sprite is AnimatedSprite2D:
		(_sprite as AnimatedSprite2D).play()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	var pulse := 0.5 + 0.5 * sin(_time * pulse_speed)
	_sprite.modulate = Color.WHITE.lerp(glow, 0.22 + 0.5 * pulse)
	if _halo:
		_halo.modulate.a = _halo_alpha * (0.45 + 0.55 * pulse)
	_visual.scale = _idle_scale()
	_visual.rotation = _idle_rotation()


func _on_body_entered(body: Node2D) -> void:
	if _taken or not (body is Player):
		return
	_taken = true
	set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	GameData.collect(points, souls)
	if vanish_style == VanishStyle.PARTICLES:
		_burst()
	else:
		_ascend()


func _idle_scale() -> Vector2:
	var breathe := 1.0 + sin(_time * pulse_speed) * 0.02
	if flicker_strength <= 0.0:
		return Vector2(breathe, breathe)
	var fast := sin(_time * 15.0) * 0.65 + sin(_time * 27.0 + 1.3) * 0.35
	var side := sin(_time * 11.0 + 0.6)
	return Vector2(
		breathe + side * flicker_strength * 0.55,
		breathe + fast * flicker_strength
	)


func _idle_rotation() -> float:
	if flicker_strength <= 0.0:
		return 0.0
	return sin(_time * 9.5) * flicker_strength * 0.9


func _burst() -> void:
	print('burst')
	if _particles == null:
		print('no particles')
		_ascend()
		return
	_sprite.modulate = glow
	if _halo:
		_halo.modulate.a = 1.0
	var pop := create_tween()
	pop.tween_property(_visual, "scale", _visual.scale * 1.14, 0.07)
	pop.tween_property(_visual, "modulate:a", 0.0, 0.12)
	_particles.restart()
	await get_tree().create_timer(_particles.lifetime + 0.1).timeout
	if is_inside_tree():
		queue_free()


func _ascend() -> void:
	_sprite.modulate = glow
	if _halo:
		_halo.modulate.a = 1.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_visual, "position:y", _visual.position.y - 84.0, 0.46) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "scale", Vector2(1.12, 1.34), 0.46) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "rotation", randf_range(-0.4, 0.4), 0.46)
	tween.tween_property(_visual, "modulate:a", 0.0, 0.4).set_delay(0.06)
	tween.chain().tween_callback(queue_free)


func _ensure_halo() -> void:
	if not show_halo:
		var existing := _visual.get_node_or_null("Halo")
		if existing:
			existing.visible = false
		return
	var found := _visual.get_node_or_null("Halo") as Sprite2D
	if found:
		_halo = found
	else:
		_halo = Sprite2D.new()
		_halo.name = "Halo"
		_halo.texture = _radial_texture(128)
		var halo_material := CanvasItemMaterial.new()
		halo_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_halo.material = halo_material
		_halo.z_index = -1
		_visual.add_child(_halo)
		_visual.move_child(_halo, 0)
	_halo.position = halo_offset
	_halo.scale = halo_scale
	_halo.modulate = halo_color
	_halo_alpha = halo_color.a


static func _radial_texture(size: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = size
	texture.height = size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
