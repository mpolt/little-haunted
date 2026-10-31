extends Node

enum World { NORMAL, GHOST }

signal run_changed
signal run_reset
signal world_changed(world: World)

var points: int = 0
var souls: int = 0
var world: World = World.NORMAL:
	set(value):
		if world == value:
			return
		world = value
		world_changed.emit(world)


func _ready() -> void:
	reset_run()
	souls = 0


func reset_run() -> void:
	points = 0
	world = World.NORMAL
	run_changed.emit()
	run_reset.emit()


func toggle_world() -> void:
	world = World.GHOST if world == World.NORMAL else World.NORMAL


func collect(point_delta: int, soul_delta: int) -> void:
	if point_delta == 0 and soul_delta == 0:
		return
	points += point_delta
	souls += soul_delta
	run_changed.emit()
