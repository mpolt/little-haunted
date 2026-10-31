class_name ClockOverlay
extends Control

var progress := 0.0
var fill_color := Color(0.02, 0.01, 0.05, 0.72)
## Anteil der kürzeren Seite; hält den Metallrand frei.
var radius_ratio := 0.30


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	visible = progress > 0.001
	queue_redraw()


func _draw() -> void:
	if progress <= 0.001:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * radius_ratio
	var steps := maxi(ceili(progress * 64.0), 1)
	var points := PackedVector2Array()
	points.append(center)
	for i in range(steps + 1):
		var t := (float(i) / float(steps)) * progress
		# 12 Uhr, dann im Uhrzeigersinn (y nach unten).
		var angle := -PI * 0.5 + t * TAU
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, fill_color)
