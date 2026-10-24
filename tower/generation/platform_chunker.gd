extends Node2D
class_name PlatformChunker

const PLATFORM_SCENE := preload("res://tower/platforms/platform.tscn")

const PLATFORMS_PER_CHUNK: int = 6
const Y_SPACING_MIN: float = 110.0
const Y_SPACING_MAX: float = 180.0
const EDGE_MARGIN: float = 16.0
## Abstand unter dem Spieler, auf dem die erste Plattform steht.
const START_DROP: float = 190.0

## How far above the camera top platforms must reach before we stop spawning ahead.
const AHEAD_VIEWPORTS: float = 1.0
## How far below the camera bottom a chunk's top may sit before it is freed.
const BEHIND_VIEWPORTS: float = 0.5

var _view_size: Vector2
var _cursor_y: float
## Oldest (lowest / largest Y) first.
var _chunks: Array[Dictionary] = []
var _started := false
var _player: Player
## Welt-X der ersten Plattform. Negativ: keine Vorgabe, dann Bildschirmmitte.
var _anchor_x := -1.0


func _ready() -> void:
	_player = _find_player()
	if _started:
		return

	var view := _viewport_size()
	var start_y := view.y - 40.0
	if _player:
		start_y = _player.global_position.y + START_DROP
		_anchor_x = _player.global_position.x
	start(view, start_y)


func _process(_delta: float) -> void:
	if not _started:
		return

	var view_height := _viewport_size().y
	var center_y := view_height * 0.5
	if _player and is_instance_valid(_player):
		center_y = _player.global_position.y
	update_window(center_y, view_height)


func start(view_size: Vector2, start_y: float) -> Node2D:
	_started = true
	_view_size = view_size
	_cursor_y = start_y

	var first_platform: Node2D = null
	var camera_center_y := view_size.y * 0.5
	_fill_ahead(camera_center_y, view_size.y)

	if not _chunks.is_empty():
		var first_chunk: Node2D = _chunks[0]["node"]
		if first_chunk.get_child_count() > 0:
			first_platform = first_chunk.get_child(0) as Node2D

	return first_platform


func update_window(camera_center_y: float, view_height: float) -> void:
	_fill_ahead(camera_center_y, view_height)
	_cull_behind(camera_center_y, view_height)


func _fill_ahead(camera_center_y: float, view_height: float) -> void:
	var camera_top := camera_center_y - view_height * 0.5
	var target_y := camera_top - view_height * AHEAD_VIEWPORTS

	while _cursor_y > target_y:
		_spawn_chunk()


func _cull_behind(camera_center_y: float, view_height: float) -> void:
	var camera_bottom := camera_center_y + view_height * 0.5
	var cull_y := camera_bottom + view_height * BEHIND_VIEWPORTS

	while not _chunks.is_empty():
		var entry: Dictionary = _chunks[0]
		var top_y: float = entry["top_y"]
		if top_y < cull_y:
			break

		var chunk: Node2D = entry["node"]
		_chunks.pop_front()
		chunk.queue_free()


func _spawn_chunk() -> void:
	var chunk := Node2D.new()
	chunk.name = "Chunk"
	add_child(chunk)

	var top_y := _cursor_y
	for i in PLATFORMS_PER_CHUNK:
		var is_start_platform := _chunks.is_empty() and i == 0
		var platform := PLATFORM_SCENE.instantiate() as Platform
		chunk.add_child(platform)

		var half := _half_width(platform)
		var min_x := half + EDGE_MARGIN
		var max_x := _view_size.x - half - EDGE_MARGIN
		var x := _view_size.x * 0.5
		if is_start_platform and _anchor_x >= 0.0:
			x = clampf(_anchor_x, min_x, max_x)
		elif max_x > min_x:
			x = randf_range(min_x, max_x)

		platform.global_position = Vector2(x, _cursor_y)
		top_y = _cursor_y
		_cursor_y -= randf_range(Y_SPACING_MIN, Y_SPACING_MAX)

	_chunks.append({
		"node": chunk,
		"top_y": top_y,
	})


func _half_width(platform: Platform) -> float:
	var shape_node := platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is RectangleShape2D:
		var rect := shape_node.shape as RectangleShape2D
		return rect.size.x * 0.5 * absf(platform.global_scale.x)
	return 100.0


func _viewport_size() -> Vector2:
	var size := get_viewport().get_visible_rect().size
	if size.x < 1.0 or size.y < 1.0:
		size = Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")
		)
	return size


func _find_player() -> Player:
	var parent := get_parent()
	if parent == null:
		return null
	for child in parent.get_children():
		if child is Player:
			return child
	return null
