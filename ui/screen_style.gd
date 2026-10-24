@tool
extends RefCounted

const CREAM := Color(0.96, 0.93, 0.88)
const MUTED := Color(0.78, 0.73, 0.84)
const INK := Color(0.17, 0.08, 0.05)
const PUMPKIN := Color(0.88, 0.46, 0.22)
const PUMPKIN_EDGE := Color(0.52, 0.24, 0.1)
const PANEL := Color(0.12, 0.08, 0.17)
const GHOST := Color(0.17, 0.13, 0.24)
const GHOST_EDGE := Color(0.45, 0.39, 0.56)
const BACKDROP := Color(0.07, 0.045, 0.11, 1)


static func paint_panel(panel: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.border_color = PUMPKIN
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	box.content_margin_left = 32.0
	box.content_margin_right = 32.0
	box.content_margin_top = 36.0
	box.content_margin_bottom = 28.0
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 28
	box.shadow_offset = Vector2(0, 12)
	panel.add_theme_stylebox_override("panel", box)


static func paint_title(label: Label) -> void:
	label.add_theme_color_override("font_color", CREAM)


static func paint_hint(label: Label) -> void:
	label.add_theme_color_override("font_color", MUTED)


static func paint_primary(button: Button) -> void:
	_paint_button(button, PUMPKIN, INK, PUMPKIN_EDGE)


static func paint_secondary(button: Button) -> void:
	_paint_button(button, GHOST, CREAM, GHOST_EDGE)


static func _paint_button(button: Button, fill: Color, font: Color, border: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_box(fill, border))
	button.add_theme_stylebox_override("hover", _button_box(fill.lightened(0.14), border.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", _button_box(fill.darkened(0.12), border))
	button.add_theme_stylebox_override("focus", _button_box(fill.lightened(0.14), CREAM))
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_focus_color", font)


static func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	box.content_margin_left = 16.0
	box.content_margin_right = 16.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box
