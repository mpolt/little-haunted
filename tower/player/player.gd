extends CharacterBody2D
class_name Player

const SPEED = 300.0
const BOOST_DEFAULT = -800.0


func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 5 * delta)

	move_and_slide()


func jump()->void:
	velocity.y = BOOST_DEFAULT
