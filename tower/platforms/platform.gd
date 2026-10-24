extends Area2D
class_name Platform

@export var boost: float = Player.BOOST_DEFAULT

@onready var _boost_animation: AnimationPlayer = get_node_or_null("AnimationPlayer")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and body.jump(boost):
		if _boost_animation:
			_boost_animation.play(&"boost")
