extends Node2D
class_name PlatformChunker

const PLATFORM_SCENE := preload("res://tower/platforms/platform.tscn")
const BOOST_PLATFORM_SCENE := preload("res://tower/platforms/pumpkin_platform.tscn")

const ITEM_CANDY := preload("res://tower/items/candy.tscn")
const ITEM_PUMPKIN := preload("res://tower/items/pumpkin.tscn")
const ITEM_CANDLE := preload("res://tower/items/candle.tscn")
const ITEM_BELL := preload("res://tower/items/bell.tscn")
const ITEM_SOUL_FLAME := preload("res://tower/items/soul_flame.tscn")
const ITEM_SPIDER_NET := preload("res://tower/items/spider_net.tscn")

const ENEMY_ZOMBIE := preload("res://tower/enemies/zombie.tscn")
const ENEMY_BAT := preload("res://tower/enemies/bat.tscn")
const ENEMY_SPOOK := preload("res://tower/enemies/spook.tscn")

const PLATFORMS_PER_CHUNK: int = 6
const EDGE_MARGIN: float = 16.0
## Abstand unter dem Spieler, auf dem die erste Plattform steht.
const START_DROP: float = 190.0
## Wie weit Items über der Plattform schweben.
const ITEM_OFFSET_Y: float = 56.0
const ITEM_OFFSET_X: float = 28.0
## Fliegende Gegner starten etwas über der Plattformoberfläche.
const FLY_ENEMY_OFFSET_Y: float = 72.0
## Zombie-Füße leicht über der Plattform-Collision.
const ZOMBIE_STAND_OFFSET_Y: float = -8.0
## Abstand der Zombie-Patrouille zu den Plattformrändern.
const PATROL_EDGE_INSET: float = 24.0

## How far above the camera top platforms must reach before we stop spawning ahead.
const AHEAD_VIEWPORTS: float = 1.0
## How far below the camera bottom a chunk's top may sit before it is freed.
const BEHIND_VIEWPORTS: float = 0.5

@export_group("Difficulty")
@export var platforms_per_tier: int = 12
@export var tiers_to_max: int = 8
@export var y_spacing_min_start: float = 110.0
@export var y_spacing_max_start: float = 180.0
@export var y_spacing_min_end: float = 220.0
@export var y_spacing_max_end: float = 420.0

@export_group("Boost")
@export var normal_jump_reach: float = 300.0
@export var boost_jump_reach: float = 520.0
@export_range(0.0, 1.0) var boost_chance_when_needed: float = 0.7
@export var boost_min_gap: int = 4

@export_group("Items")
@export_range(0.0, 1.0) var item_chance: float = 0.3
@export var spider_from_tier: int = 2
@export var weight_candy: int = 5
@export var weight_pumpkin: int = 10
@export var weight_candle: int = 3
@export var weight_bell: int = 2
@export var weight_soul_flame: int = 1
@export var weight_spider_net: int = 1

@export_group("Enemies")
@export_range(0.0, 1.0) var enemy_chance: float = 0.1
@export var weight_zombie: int = 2
@export var weight_bat: int = 1
@export var weight_spook: int = 1

var _view_size: Vector2
var _cursor_y: float
## Oldest (lowest / largest Y) first.
var _chunks: Array[Dictionary] = []
var _started := false
var _player: Player
## Welt-X der ersten Plattform. Negativ: keine Vorgabe, dann Bildschirmmitte.
var _anchor_x := -1.0
var _platforms_spawned: int = 0
var _platforms_since_boost: int = 999


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
	_platforms_spawned = 0
	_platforms_since_boost = 999

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
		var spacing := _roll_spacing()
		var use_boost := false

		if spacing > normal_jump_reach:
			if (
				not is_start_platform
				and _platforms_since_boost >= boost_min_gap
				and randf() < boost_chance_when_needed
			):
				use_boost = true
			else:
				spacing = normal_jump_reach

		var scene := BOOST_PLATFORM_SCENE if use_boost else PLATFORM_SCENE
		var platform := scene.instantiate() as Platform
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

		if not is_start_platform:
			if randf() < item_chance:
				_spawn_item(chunk, platform.global_position)
			elif randf() < enemy_chance:
				_spawn_enemy(chunk, platform)

		_platforms_spawned += 1
		if use_boost:
			_platforms_since_boost = 0
		else:
			_platforms_since_boost += 1

		_cursor_y -= spacing

	_chunks.append({
		"node": chunk,
		"top_y": top_y,
	})


func _current_tier() -> int:
	if platforms_per_tier <= 0 or tiers_to_max <= 0:
		return 0
	return mini(_platforms_spawned / platforms_per_tier, tiers_to_max)


func _tier_progress() -> float:
	if tiers_to_max <= 0:
		return 1.0
	return float(_current_tier()) / float(tiers_to_max)


func _roll_spacing() -> float:
	var t := _tier_progress()
	var min_y := lerpf(y_spacing_min_start, y_spacing_min_end, t)
	var max_y := lerpf(y_spacing_max_start, y_spacing_max_end, t)
	if max_y < min_y:
		max_y = min_y
	return minf(randf_range(min_y, max_y), boost_jump_reach)


func _spawn_item(chunk: Node2D, platform_pos: Vector2) -> void:
	var scene := _pick_item_scene()
	if scene == null:
		return
	var item := scene.instantiate() as Node2D
	chunk.add_child(item)
	var side := -1.0 if randf() < 0.5 else 1.0
	item.global_position = platform_pos + Vector2(side * ITEM_OFFSET_X, -ITEM_OFFSET_Y)


func _spawn_enemy(chunk: Node2D, platform: Platform) -> void:
	var scene := _pick_enemy_scene()
	if scene == null:
		return
	var enemy := scene.instantiate() as Enemy
	chunk.add_child(enemy)

	var half := _half_width(platform)
	var platform_pos := platform.global_position
	if enemy.move_mode == Enemy.MoveMode.PATROL:
		enemy.global_position = platform_pos + Vector2(0.0, ZOMBIE_STAND_OFFSET_Y)
		var left_x := platform_pos.x - half + PATROL_EDGE_INSET
		var right_x := platform_pos.x + half - PATROL_EDGE_INSET
		enemy.setup_bounds(left_x, right_x)
	else:
		enemy.global_position = platform_pos + Vector2(0.0, -FLY_ENEMY_OFFSET_Y)
		var left_x := EDGE_MARGIN
		var right_x := _view_size.x - EDGE_MARGIN
		enemy.setup_bounds(left_x, right_x)


func _pick_enemy_scene() -> PackedScene:
	var entries: Array[Dictionary] = [
		{"scene": ENEMY_ZOMBIE, "weight": weight_zombie},
		{"scene": ENEMY_BAT, "weight": weight_bat},
		{"scene": ENEMY_SPOOK, "weight": weight_spook},
	]
	return _pick_weighted(entries)


func _pick_item_scene() -> PackedScene:
	var entries: Array[Dictionary] = [
		{"scene": ITEM_CANDY, "weight": weight_candy},
		{"scene": ITEM_PUMPKIN, "weight": weight_pumpkin},
		{"scene": ITEM_CANDLE, "weight": weight_candle},
		{"scene": ITEM_BELL, "weight": weight_bell},
		{"scene": ITEM_SOUL_FLAME, "weight": weight_soul_flame},
	]
	if _current_tier() >= spider_from_tier:
		entries.append({"scene": ITEM_SPIDER_NET, "weight": weight_spider_net})
	return _pick_weighted(entries)


func _pick_weighted(entries: Array[Dictionary]) -> PackedScene:
	var total := 0
	for entry in entries:
		total += maxi(int(entry["weight"]), 0)
	if total <= 0:
		return null

	var pick := randi() % total
	var running := 0
	for entry in entries:
		running += maxi(int(entry["weight"]), 0)
		if pick < running:
			return entry["scene"] as PackedScene
	return entries.back()["scene"] as PackedScene


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
