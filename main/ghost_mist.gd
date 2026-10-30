extends Node2D

const _LIFETIME := 1.5
const _SPACING := 18.0

@export var ghost_path: NodePath = ^"../ghost2"

var _ghost: Sprite2D
var _blob: GradientTexture2D
var _puffs: Array[Dictionary] = []
var _carry := 0.0
var _previous := Vector2.ZERO


func _ready() -> void:
	_ghost = get_node_or_null(ghost_path) as Sprite2D
	if _ghost == null:
		push_error("Geisternebel findet den Geist nicht: %s" % ghost_path)
		set_process(false)
		return
	_blob = _make_blob()
	_previous = _ghost.position
	texture_filter = TEXTURE_FILTER_LINEAR


func _process(delta: float) -> void:
	var current := _ghost.position
	var step := current - _previous
	var distance := step.length()
	if distance > 0.35:
		_drop_along(current, step / distance, distance)
	else:
		_carry = 0.0
	_previous = current
	_age(delta)
	queue_redraw()


func _drop_along(current: Vector2, direction: Vector2, distance: float) -> void:
	_carry += distance
	while _carry >= _SPACING:
		_carry -= _SPACING
		var point := current - direction * _carry
		_puffs.append(_make_puff(point, direction))


func _make_puff(point: Vector2, direction: Vector2) -> Dictionary:
	var length := _ghost_length()
	return {
		"point": point - direction * length * 0.22,
		"age": 0.0,
		"length": length,
		"angle": direction.angle(),
		"spread": randf_range(0.86, 1.16),
		"alpha": _ghost.modulate.a * clampf(96.0 / length, 0.62, 1.0),
		"side": direction.orthogonal() * randf_range(-0.16, 0.16) * length,
	}


func _ghost_length() -> float:
	var bounds := _ghost.get_rect().size * _ghost.scale.abs()
	return maxf(bounds.x, bounds.y)


func _age(delta: float) -> void:
	var kept: Array[Dictionary] = []
	for puff in _puffs:
		puff["age"] = float(puff["age"]) + delta
		if float(puff["age"]) < _LIFETIME:
			kept.append(puff)
	_puffs = kept


func _draw() -> void:
	if _blob == null:
		return
	for puff in _puffs:
		var t := clampf(float(puff["age"]) / _LIFETIME, 0.0, 1.0)
		var length := float(puff["length"]) * float(puff["spread"])
		var grow := lerpf(1.05, 1.7, t)
		var center: Vector2 = puff["point"] + puff["side"] * t + Vector2(0.0, -22.0 * t)
		var alpha := float(puff["alpha"])
		var core := pow(1.0 - t, 1.8)
		var wide := pow(1.0 - t, 1.15)
		var along := length * 1.35 * grow
		var across := length * 0.95 * grow
		_stamp(center, float(puff["angle"]), along * 1.7, across * 1.55, Color(0.74, 0.72, 0.94, 0.16 * alpha * wide))
		_stamp(center, float(puff["angle"]), along, across, Color(0.9, 0.93, 1.0, 0.32 * alpha * core))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _stamp(center: Vector2, angle: float, along: float, across: float, color: Color) -> void:
	var tex_size := _blob.get_size()
	draw_set_transform(center, angle, Vector2(along / tex_size.x, across / tex_size.y))
	draw_texture(_blob, -tex_size * 0.5, color)


func _make_blob() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.48, 0.75, 1.0])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 1),
		Color(1, 1, 1, 0.7),
		Color(1, 1, 1, 0.28),
		Color(1, 1, 1, 0.05),
		Color(1, 1, 1, 0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
