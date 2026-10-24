extends CharacterBody2D
class_name Player

const SPEED = 300.0
const BOOST_DEFAULT = -800.0

## Stärkster Boost, der in diesem Physikschritt schon vergeben wurde.
var _boost_this_step := 0.0


func _physics_process(delta: float) -> void:
	_boost_this_step = 0.0
	velocity += get_gravity() * delta
	
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 5 * delta)

	move_and_slide()


func jump(boost: float = BOOST_DEFAULT) -> bool:
	var already_boosted := _boost_this_step < 0.0
	if velocity.y <= 0.0 and not already_boosted:
		return false
	if already_boosted and boost >= _boost_this_step:
		return false
	_boost_this_step = boost
	velocity.y = boost
	return true
