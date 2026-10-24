extends Camera2D
class_name UpwardCamera

## Anteil der Sichthöhe unter der Kameramitte, auf der der Player gehalten wird.
## Die Kamera rückt nur nach oben nach, nie nach unten.
@export var anchor_ratio: float = 0.18

## Ziel, dem die Kamera folgt. Im Inspektor zuweisen.
## Bleibt das Feld leer, wird ein Player in der aktuellen Szene gesucht.
@export var target: Node2D


func _ready() -> void:
	# Vor dem Turm, damit der Chunker dieselbe Kameraposition nutzt.
	process_physics_priority = -1
	var viewport_size := get_viewport_rect().size
	position = viewport_size * 0.5
	make_current()
	_ensure_target()


func _physics_process(_delta: float) -> void:
	_ensure_target()
	if target == null:
		return

	var view_h := get_viewport_rect().size.y
	var follow_line := global_position.y + view_h * anchor_ratio
	if target.global_position.y < follow_line:
		global_position.y -= follow_line - target.global_position.y
		force_update_scroll()


func _ensure_target() -> void:
	if is_instance_valid(target):
		return

	target = _find_player()


func _find_player() -> Node2D:
	var root := get_tree().current_scene
	if root == null:
		root = get_parent()
	if root == null:
		return null

	if root is Player:
		return root

	var named := root.find_child("Player", true, false) as Node2D
	if named != null:
		return named

	var players := root.find_children("*", "Player", true, false)
	if players.is_empty():
		return null
	return players[0] as Node2D
