extends CharacterBody2D
class_name Player

signal died
signal shield_changed(charges: int)

const SPEED = 300.0
const BOOST_DEFAULT = -800.0
## Schwächster Absprung. Mehrere Netze können die Sprungkraft nicht darunter drücken.
const MIN_BOOST := -160.0
## project.godot: 2d_physics/layer_1 = player
const PHYSICS_LAYER := 1

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
const _HALO_COLOR := Color(0.55, 0.88, 1.0, 0.38)
const _HALO_SCALE := Vector2(1.7, 2.05)
const _BREATH_SECONDS := 2.1
const _SHIELD_MAX := 3
const _SHIELD_SCALE := Vector2(2.15, 2.55)
## Stufen 1–3: Farbe und Basisgröße des gelben Scheins.
const _SHIELD_TIERS := [
	{"color": Color(1.0, 0.82, 0.28, 0.42), "scale": 1.0},
	{"color": Color(1.0, 0.78, 0.18, 0.68), "scale": 1.18},
	{"color": Color(1.0, 0.92, 0.35, 0.92), "scale": 1.38},
]
const _DEATH_COLOR := Color(1.0, 0.32, 0.38, 0.0)
const _BOOST_PLUS := preload("res://tower/items/assets/boost_plus.png")
const _BOOST_MIN := preload("res://tower/items/assets/boost_min.png")
## 1254px-Icon, sichtbar etwa so hoch wie der Körper.
const _BOOST_ICON_SCALE := 0.06

## Stärkster Boost, der in diesem Physikschritt schon vergeben wurde.
var _boost_this_step := 0.0
## Sprungkraft dieses Laufs. Candies erhöhen sie, Spinnennetze senken sie, der Tod setzt sie auf 0.
var jump_bonus := 0.0
## Gestapelte Schild-Ladungen. Kerze +1, Gegner-Treffer −1.
var shield_charges := 0
var _facing_left := false
var _halo: Sprite2D
var _glow_time := 0.0
var _shield_ring: Sprite2D
var _dead := false
var _hurt_flash := 0.0

@onready var _sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var _visual: Node2D = $Visual
@onready var _squash_animation: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	collision_layer = PHYSICS_LAYER
	## Keine physische Welt-Kollision; Sprünge laufen über Area2D.
	collision_mask = 0
	z_index = 2
	_apply_frame(&"default")
	_ensure_halo()
	shield_changed.emit(shield_charges)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_boost_this_step = 0.0
	velocity += get_gravity() * delta

	var direction := Settings.steer()
	if direction:
		velocity.x = direction * SPEED
		_facing_left = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 5 * delta)

	move_and_slide()


func _process(delta: float) -> void:
	if _dead:
		return
	_update_animation()
	_update_glow(delta)


func add_jump_bonus(amount: float) -> void:
	if is_zero_approx(amount):
		return
	jump_bonus += amount
	_popup_boost(amount > 0.0)


func grant_shield() -> void:
	if _dead or shield_charges >= _SHIELD_MAX:
		return
	shield_charges += 1
	shield_changed.emit(shield_charges)
	_refresh_shield_ring()


## Gibt true zurück, wenn der Treffer überlebt wurde (Schild oder Geisterwelt).
func take_hit() -> bool:
	if _dead:
		return true
	if GameData.world == GameData.World.GHOST:
		return true
	if shield_charges > 0:
		shield_charges -= 1
		shield_changed.emit(shield_charges)
		_refresh_shield_ring()
		_hurt_flash = 0.22
		return true
	_begin_death()
	return false


func reset_after_death() -> void:
	jump_bonus = 0.0
	shield_charges = 0
	_dead = false
	_hurt_flash = 0.0
	_clear_shield_ring()
	_visual.rotation = 0.0
	_visual.scale = Vector2.ONE
	_visual.modulate = Color.WHITE
	_visual.position = Vector2.ZERO
	collision_layer = PHYSICS_LAYER
	set_physics_process(true)
	shield_changed.emit(shield_charges)
	for child in get_children():
		if str(child.name).begins_with("BoostPopup"):
			child.queue_free()


func jump(boost: float = BOOST_DEFAULT) -> bool:
	if _dead:
		return false
	# Negativer Boost: größerer Betrag bedeutet höher.
	boost = minf(boost - jump_bonus, MIN_BOOST)
	var already_boosted := _boost_this_step < 0.0
	if velocity.y <= 0.0 and not already_boosted:
		return false
	if already_boosted and boost >= _boost_this_step:
		return false
	_boost_this_step = boost
	velocity.y = boost
	_play_squash(boost)
	return true


func _begin_death() -> void:
	_dead = true
	collision_layer = 0
	velocity = Vector2.ZERO
	_clear_shield_ring()
	_play_death_then_emit()


func _play_death_then_emit() -> void:
	await _play_death_animation()
	if is_inside_tree():
		died.emit()


func _play_death_animation() -> void:
	_apply_frame(&"fall")
	_sprite.play(&"fall")
	_sprite.flip_h = _facing_left
	_visual.modulate = Color(1.0, 0.55, 0.55, 1.0)
	var spin := -2.4 if _facing_left else 2.4
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "rotation", spin, 0.58) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_visual, "scale", Vector2(0.2, 0.2), 0.58) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_visual, "position:y", _visual.position.y - 56.0, 0.58) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "modulate", _DEATH_COLOR, 0.5).set_delay(0.08)
	await tween.finished


func _update_animation() -> void:
	var direction := Settings.steer()
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


func _update_glow(delta: float) -> void:
	_glow_time += delta
	if _hurt_flash > 0.0:
		_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	var breath := 0.5 + 0.5 * sin(_glow_time * TAU / _BREATH_SECONDS)
	var wobble := 0.5 + 0.5 * sin(_glow_time * 5.1 + 1.3)
	var presence := lerpf(breath, wobble, 0.18)
	_halo.modulate.a = _HALO_COLOR.a * lerpf(0.62, 1.0, presence)
	var cool := Color(0.84, 0.94, 1.0)
	var base := Color.WHITE.lerp(cool, lerpf(0.04, 0.1, breath))
	if _hurt_flash > 0.0:
		base = base.lerp(Color(1.0, 0.78, 0.35), clampf(_hurt_flash / 0.22, 0.0, 1.0))
	_sprite.modulate = base
	if _shield_ring and shield_charges > 0:
		var tier: Dictionary = _SHIELD_TIERS[mini(shield_charges, _SHIELD_MAX) - 1]
		var color: Color = tier["color"]
		var scale_mult: float = tier["scale"]
		_shield_ring.modulate = Color(color.r, color.g, color.b, color.a * lerpf(0.72, 1.0, presence))
		_shield_ring.scale = _SHIELD_SCALE * scale_mult * lerpf(0.96, 1.08, breath)


func _ensure_halo() -> void:
	_halo = Sprite2D.new()
	_halo.name = "Halo"
	_halo.texture = _radial_texture(128)
	_halo.position = _sprite.position
	_halo.scale = _HALO_SCALE
	_halo.modulate = _HALO_COLOR
	var halo_material := CanvasItemMaterial.new()
	halo_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_halo.material = halo_material
	_halo.z_index = -1
	_visual.add_child(_halo)
	_visual.move_child(_halo, 0)


func _refresh_shield_ring() -> void:
	if shield_charges <= 0:
		_clear_shield_ring()
		return
	var tier: Dictionary = _SHIELD_TIERS[mini(shield_charges, _SHIELD_MAX) - 1]
	var color: Color = tier["color"]
	var scale_mult: float = tier["scale"]
	if _shield_ring == null or not is_instance_valid(_shield_ring):
		_shield_ring = Sprite2D.new()
		_shield_ring.name = "ShieldRing"
		_shield_ring.texture = _radial_texture(128)
		_shield_ring.position = _sprite.position
		var shield_material := CanvasItemMaterial.new()
		shield_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_shield_ring.material = shield_material
		_shield_ring.z_index = -1
		_visual.add_child(_shield_ring)
		_visual.move_child(_shield_ring, 0)
	_shield_ring.visible = true
	_shield_ring.modulate = color
	_shield_ring.scale = _SHIELD_SCALE * scale_mult


func _clear_shield_ring() -> void:
	if _shield_ring and is_instance_valid(_shield_ring):
		_shield_ring.queue_free()
	_shield_ring = null


static func _radial_texture(size: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 0.85),
		Color(1, 1, 1, 0.28),
		Color(1, 1, 1, 0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = size
	texture.height = size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _popup_boost(stronger: bool) -> void:
	var icon := Sprite2D.new()
	icon.name = "BoostPopup"
	icon.texture = _BOOST_PLUS if stronger else _BOOST_MIN
	icon.scale = Vector2.ONE * 0.01
	icon.position = Vector2(randf_range(-14.0, 14.0), -118.0)
	icon.z_index = 1
	add_child(icon)
	var tween := icon.create_tween().set_parallel(true)
	tween.tween_property(icon, "scale", Vector2.ONE * _BOOST_ICON_SCALE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "position:y", icon.position.y - 70.0, 0.72) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "modulate:a", 0.0, 0.28).set_delay(0.44)
	tween.chain().tween_callback(icon.queue_free)


func _play_squash(boost: float) -> void:
	var amount := clampf(absf(boost) / absf(BOOST_DEFAULT), 0.7, 1.9)
	var blend := inverse_lerp(0.7, 1.9, amount)
	# 1.0 entspricht der Länge im AnimationPlayer. Stärkere Boosts laufen langsamer.
	_squash_animation.speed_scale = lerpf(1.15, 0.55, blend)
	_squash_animation.play(&"squash")
