extends Control

const _SHEET := preload("res://ui/buttons/assets/world_state_button.png")

const GHOST_DURATION := 5.0
const COOLDOWN_DURATION := 2.0

enum Phase { READY, GHOST, COOLDOWN }

@onready var _button: TextureButton = %Button
@onready var _clock: ClockOverlay = %ClockOverlay
@onready var _timer_label: Label = %TimerLabel

var _phase: Phase = Phase.READY
var _remaining := 0.0

## Zeile 1: Geisterwelt → normal. Zeile 2: normal → Geisterwelt.
## Spalte 1: Ruhezustand. Spalte 2: pressed / hover / cooldown.
var _to_normal_idle: AtlasTexture
var _to_normal_active: AtlasTexture
var _to_ghost_idle: AtlasTexture
var _to_ghost_active: AtlasTexture


func _ready() -> void:
	_build_atlas()
	_clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button.focus_mode = Control.FOCUS_NONE
	_button.pressed.connect(_on_pressed)
	GameData.world_changed.connect(_on_world_changed)
	GameData.run_reset.connect(_on_run_reset)
	_apply_visuals()
	_set_progress(0.0, false)


func _process(delta: float) -> void:
	if _phase == Phase.READY:
		return
	_remaining = maxf(_remaining - delta, 0.0)
	_refresh_timer_ui()
	if _remaining > 0.0:
		return
	if _phase == Phase.GHOST:
		_leave_ghost()
	elif _phase == Phase.COOLDOWN:
		_phase = Phase.READY
		_apply_visuals()
		_set_progress(0.0, false)


func _on_pressed() -> void:
	match _phase:
		Phase.READY:
			_enter_ghost()
		Phase.GHOST:
			_leave_ghost()
		Phase.COOLDOWN:
			pass


func _enter_ghost() -> void:
	_phase = Phase.GHOST
	_remaining = GHOST_DURATION
	GameData.world = GameData.World.GHOST
	_apply_visuals()
	_refresh_timer_ui()


func _leave_ghost() -> void:
	_phase = Phase.COOLDOWN
	_remaining = COOLDOWN_DURATION
	if GameData.world != GameData.World.NORMAL:
		GameData.world = GameData.World.NORMAL
	_apply_visuals()
	_refresh_timer_ui()


func _on_world_changed(world: GameData.World) -> void:
	if _phase == Phase.GHOST and world != GameData.World.GHOST:
		_phase = Phase.COOLDOWN
		_remaining = COOLDOWN_DURATION
	elif _phase == Phase.READY and world == GameData.World.GHOST:
		_phase = Phase.GHOST
		_remaining = GHOST_DURATION
	_apply_visuals()
	_refresh_timer_ui()


func _on_run_reset() -> void:
	_phase = Phase.READY
	_remaining = 0.0
	_apply_visuals()
	_set_progress(0.0, false)


func _apply_visuals() -> void:
	var in_ghost := _phase == Phase.GHOST or GameData.world == GameData.World.GHOST
	var idle := _to_normal_idle if in_ghost else _to_ghost_idle
	var active := _to_normal_active if in_ghost else _to_ghost_active
	_button.texture_normal = idle
	_button.texture_pressed = active
	_button.texture_hover = active
	# Cooldown nutzt Spalte 2 der Zielrichtung normal → Geisterwelt.
	_button.texture_disabled = _to_ghost_active
	_button.disabled = _phase == Phase.COOLDOWN


func _refresh_timer_ui() -> void:
	if _phase == Phase.READY:
		_set_progress(0.0, false)
		return
	var total := GHOST_DURATION if _phase == Phase.GHOST else COOLDOWN_DURATION
	var progress := 1.0 - (_remaining / total)
	_set_progress(progress, true)
	_timer_label.text = str(ceili(_remaining)) if _remaining > 0.0 else "0"


func _set_progress(progress: float, show_label: bool) -> void:
	_clock.set_progress(progress)
	_timer_label.visible = show_label
	if not show_label:
		_timer_label.text = ""


func _build_atlas() -> void:
	var cell := Vector2i(_SHEET.get_width() / 2, _SHEET.get_height() / 2)
	_to_normal_idle = _slice(Vector2i(0, 0), cell)
	_to_normal_active = _slice(Vector2i(cell.x, 0), cell)
	_to_ghost_idle = _slice(Vector2i(0, cell.y), cell)
	_to_ghost_active = _slice(Vector2i(cell.x, cell.y), cell)


func _slice(origin: Vector2i, cell: Vector2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = _SHEET
	atlas.region = Rect2(origin, cell)
	return atlas
