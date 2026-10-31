extends Area2D
class_name Enemy

## Gegner auf Plattformen. Einzelbilder werden über Bewegung und Scale animiert.

## project.godot: 2d_physics/layer_4 = enemies
const PHYSICS_LAYER := 8

enum MoveMode { PATROL, FLY }

@export var move_mode: MoveMode = MoveMode.PATROL
@export var speed: float = 60.0
@export var bob_amplitude: float = 0.0
@export var bob_speed: float = 3.0
@export var flap_strength: float = 0.0
@export var flap_speed: float = 10.0
@export var pulse_strength: float = 0.0
@export var sway_rotation: float = 0.0
## Basis-Skalierung des Sprites (ohne Flügel-/Lauf-Animation).
@export var sprite_scale: float = 0.09
## Sprite zeigt standardmäßig nach links; bei Laufrichtung rechts wird gespiegelt.
@export var faces_left: bool = true

@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = $Visual/Sprite

var _direction := 1.0
var _left_bound := 0.0
var _right_bound := 0.0
var _base_y := 0.0
var _time := 0.0
var _bounds_ready := false
var _dead := false


func _ready() -> void:
	collision_layer = PHYSICS_LAYER
	collision_mask = Player.PHYSICS_LAYER
	z_index = 1
	_base_y = global_position.y
	_sprite.scale = Vector2(sprite_scale, sprite_scale)
	_apply_facing()
	body_entered.connect(_on_body_entered)


func setup_bounds(left_x: float, right_x: float) -> void:
	_left_bound = minf(left_x, right_x)
	_right_bound = maxf(left_x, right_x)
	_bounds_ready = true
	if global_position.x < _left_bound:
		global_position.x = _left_bound
	elif global_position.x > _right_bound:
		global_position.x = _right_bound
	_base_y = global_position.y
	if randf() < 0.5:
		_direction = -1.0
	# setup_bounds läuft oft vor _ready; Sprite erst danach spiegeln.
	if is_node_ready():
		_apply_facing()


func _process(delta: float) -> void:
	if _dead:
		return
	_time += delta
	if _bounds_ready:
		_move(delta)
	_animate(delta)


func _move(delta: float) -> void:
	global_position.x += _direction * speed * delta
	if global_position.x >= _right_bound:
		global_position.x = _right_bound
		_direction = -1.0
		_apply_facing()
	elif global_position.x <= _left_bound:
		global_position.x = _left_bound
		_direction = 1.0
		_apply_facing()

	if bob_amplitude > 0.0:
		global_position.y = _base_y + sin(_time * bob_speed) * bob_amplitude
	else:
		global_position.y = _base_y


func _animate(_delta: float) -> void:
	var sx := sprite_scale
	var sy := sprite_scale

	if move_mode == MoveMode.PATROL:
		# Leichtes Hüpfen und Stauchen beim Laufen.
		var step := sin(_time * speed * 0.18)
		_visual.position.y = absf(step) * -4.0
		sx *= 1.0 + step * 0.04
		sy *= 1.0 - step * 0.06
	else:
		_visual.position.y = 0.0
		if flap_strength > 0.0:
			var flap := sin(_time * flap_speed)
			sx *= 1.0 + flap * flap_strength * 0.35
			sy *= 1.0 - flap * flap_strength
		if pulse_strength > 0.0:
			var pulse := 0.5 + 0.5 * sin(_time * bob_speed)
			sx *= 1.0 + pulse * pulse_strength
			sy *= 1.0 + pulse * pulse_strength
		if sway_rotation > 0.0:
			_visual.rotation = sin(_time * bob_speed * 0.7) * sway_rotation

	_sprite.scale = Vector2(sx, sy)


func _apply_facing() -> void:
	# faces_left: Sprite zeigt nach links bei scale.x > 0 ohne flip.
	var facing_right := _direction > 0.0
	_sprite.flip_h = facing_right == faces_left


func _on_body_entered(body: Node2D) -> void:
	if _dead or not (body is Player):
		return
	var player := body as Player
	if player.take_hit():
		_pop()


func _pop() -> void:
	_dead = true
	set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_visual, "scale", _visual.scale * 1.35, 0.12)
	tween.tween_property(_visual, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)
