extends CharacterBody2D
class_name Player

const SPEED = 300.0
const BOOST_DEFAULT = -800.0

## Gleiche sichtbare Höhe und gleiche Bildmitte für jede Pose.
const _FRAME_SCALE := {
	&"default": 0.120109186,
	&"jump_left": 0.132842824,
	&"jump_right": 0.134643211,
	&"fall": 0.131959618,
}
const _FRAME_OFFSET := {
	&"default": Vector2(5.5, -1.0),
	&"jump_left": Vector2(43.0, 4.0),
	&"jump_right": Vector2(-28.0, 16.0),
	&"fall": Vector2(-4.0, -2.5),
}
const _HALO_COLOR := Color(0.55, 0.88, 1.0, 0.38)
const _HALO_SCALE := Vector2(1.7, 2.05)
const _BREATH_SECONDS := 2.1

## Stärkster Boost, der in diesem Physikschritt schon vergeben wurde.
var _boost_this_step := 0.0
var _facing_left := false
var _halo: Sprite2D
var _glow_time := 0.0

@onready var _sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var _visual: Node2D = $Visual
@onready var _squash_animation: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_apply_frame(&"default")
	_ensure_halo()


func _physics_process(delta: float) -> void:
	_boost_this_step = 0.0
	velocity += get_gravity() * delta

	var direction := Settings.steer()
	if direction:
		velocity.x = direction * SPEED
		_facing_left = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 5 * delta)

	move_and_slide()


func _process(delta: float) -> void:
	_update_animation()
	_update_glow(delta)


func jump(boost: float = BOOST_DEFAULT) -> bool:
	var already_boosted := _boost_this_step < 0.0
	if velocity.y <= 0.0 and not already_boosted:
		return false
	if already_boosted and boost >= _boost_this_step:
		return false
	_boost_this_step = boost
	velocity.y = boost
	_play_squash(boost)
	return true


func _update_animation() -> void:
	var direction := Settings.steer()
	var next_animation: StringName = &"default"

	if is_on_floor():
		next_animation = &"default"
	elif velocity.y < 0.0:
		if direction > 0.0:
			next_animation = &"jump_right"
		elif direction < 0.0:
			next_animation = &"jump_left"
	else:
		next_animation = &"fall"

	_sprite.flip_h = next_animation == &"fall" and _facing_left
	if _sprite.animation != next_animation:
		_apply_frame(next_animation)
		_sprite.play(next_animation)


func _apply_frame(animation_name: StringName) -> void:
	var frame_scale: float = _FRAME_SCALE[animation_name]
	_sprite.scale = Vector2(frame_scale, frame_scale)
	_sprite.offset = _FRAME_OFFSET[animation_name]


func _update_glow(delta: float) -> void:
	_glow_time += delta
	var breath := 0.5 + 0.5 * sin(_glow_time * TAU / _BREATH_SECONDS)
	var wobble := 0.5 + 0.5 * sin(_glow_time * 5.1 + 1.3)
	var presence := lerpf(breath, wobble, 0.18)
	_halo.modulate.a = _HALO_COLOR.a * lerpf(0.62, 1.0, presence)
	var cool := Color(0.84, 0.94, 1.0)
	_sprite.modulate = Color.WHITE.lerp(cool, lerpf(0.04, 0.1, breath))


func _ensure_halo() -> void:
	_halo = Sprite2D.new()
	_halo.name = "Halo"
	_halo.texture = _radial_texture(128)
	_halo.position = _sprite.position
	_halo.scale = _HALO_SCALE
	_halo.modulate = _HALO_COLOR
	var halo_material := CanvasItemMaterial.new()
	halo_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_halo.material = halo_material
	_halo.z_index = -1
	_visual.add_child(_halo)
	_visual.move_child(_halo, 0)


static func _radial_texture(size: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 0.85),
		Color(1, 1, 1, 0.28),
		Color(1, 1, 1, 0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = size
	texture.height = size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _play_squash(boost: float) -> void:
	var amount := clampf(absf(boost) / absf(BOOST_DEFAULT), 0.7, 1.9)
	var blend := inverse_lerp(0.7, 1.9, amount)
	# 1.0 entspricht der Länge im AnimationPlayer. Stärkere Boosts laufen langsamer.
	_squash_animation.speed_scale = lerpf(1.15, 0.55, blend)
	_squash_animation.play(&"squash")
