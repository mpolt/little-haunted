extends Node2D

const MAIN_SCENE := "res://main/main.tscn"
const GAME_OVER_SCENE := preload("res://ui/dialogs/game_over_dialog.tscn")

@onready var _camera: UpwardCamera = $UpwardCamera
@onready var _player: Player = $Player

var _game_over: GameOverDialog
var _run_ended := false


func _ready() -> void:
	get_tree().paused = false
	_run_ended = false
	_game_over = GAME_OVER_SCENE.instantiate()
	add_child(_game_over)
	_camera.player_fell.connect(_end_run)
	if _player:
		_player.died.connect(_end_run)
	_game_over.restart_pressed.connect(_restart)
	_game_over.main_menu_pressed.connect(_open_main_menu)


func _end_run() -> void:
	if _run_ended:
		return
	_run_ended = true
	if _player:
		_player.reset_after_death()
	get_tree().paused = true
	_game_over.open()


func _restart() -> void:
	_change_scene(func() -> Error:
		return get_tree().reload_current_scene()
	)


func _open_main_menu() -> void:
	_change_scene(func() -> Error:
		return get_tree().change_scene_to_file(MAIN_SCENE)
	)


func _change_scene(change: Callable) -> void:
	# Der Pause-Zustand bleibt über den Szenenwechsel hinweg erhalten.
	get_tree().paused = false
	var err: Error = change.call()
	if err != OK:
		push_error("Szenenwechsel fehlgeschlagen: %s" % error_string(err))
