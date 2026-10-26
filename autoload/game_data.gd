extends Node

signal run_changed

var points: int = 0
var souls: int = 0

func _ready() -> void:
	reset_run()
	souls = 0


func reset_run() -> void:
	points = 0
	run_changed.emit()


func collect(point_delta: int, soul_delta: int) -> void:
	if point_delta == 0 and soul_delta == 0:
		return
	points += point_delta
	souls += soul_delta
	run_changed.emit()
