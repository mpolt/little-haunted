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

## Stärkster Boost, der in diesem Physikschritt schon vergeben wurde.
var _boost_this_step := 0.0
var _facing_left := false

@onready var _sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var _squash_animation: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_apply_frame(&"default")


func _physics_process(delta: float) -> void:
	_boost_this_step = 0.0
	velocity += get_gravity() * delta

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		_facing_left = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 5 * delta)

	move_and_slide()


func _process(_delta: float) -> void:
	_update_animation()


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
	var direction := Input.get_axis("move_left", "move_right")
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


func _play_squash(boost: float) -> void:
	var amount := clampf(absf(boost) / absf(BOOST_DEFAULT), 0.7, 1.9)
	var blend := inverse_lerp(0.7, 1.9, amount)
	# 1.0 entspricht der Länge im AnimationPlayer. Stärkere Boosts laufen langsamer.
	_squash_animation.speed_scale = lerpf(1.15, 0.55, blend)
	_squash_animation.play(&"squash")
