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
var _squash_tween: Tween

@onready var _visual: Node2D = $Visual
@onready var _sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D


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
	var duration := lerpf(0.24, 0.5, blend)
	var squash := Vector2(lerpf(1.12, 1.4, blend), lerpf(0.82, 0.5, blend))
	var stretch := Vector2(lerpf(0.94, 0.78, blend), lerpf(1.1, 1.36, blend))
	var settle := Vector2(lerpf(1.03, 1.08, blend), lerpf(0.97, 0.92, blend))

	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()

	_squash_tween = create_tween()
	_squash_tween.tween_property(_visual, "scale", squash, duration * 0.16)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_squash_tween.tween_property(_visual, "scale", stretch, duration * 0.28)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_squash_tween.tween_property(_visual, "scale", settle, duration * 0.22)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_squash_tween.tween_property(_visual, "scale", Vector2.ONE, duration * 0.34)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
