extends Area2D
class_name Platform



func _on_body_entered(body: Node2D) -> void:
	if body is Player and body.velocity.y > 0.0:
		body.jump()
