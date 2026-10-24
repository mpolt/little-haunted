@tool
extends CanvasLayer
class_name GameOverDialog

const ScreenStyle := preload("res://ui/screen_style.gd")

## Bildschirmfester Abschluss. Die Szene entscheidet, wohin die Auswahl führt.
signal restart_pressed
signal main_menu_pressed

@onready var _root: Control = $Root
@onready var _panel: PanelContainer = $Root/Center/Panel
@onready var _title: Label = $Root/Center/Panel/Body/Title
@onready var _hint: Label = $Root/Center/Panel/Body/Hint
@onready var _retry: Button = %RetryButton
@onready var _menu: Button = %MenuButton

var _chosen := false


func _ready() -> void:
	# Buttons müssen reagieren, während der Lauf pausiert ist.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_style()
	if Engine.is_editor_hint():
		return

	_root.hide()
	_retry.pressed.connect(_on_retry)
	_menu.pressed.connect(_on_menu)


func open() -> void:
	_root.show()
	_retry.grab_focus()


func _apply_style() -> void:
	ScreenStyle.paint_panel(_panel)
	ScreenStyle.paint_title(_title)
	ScreenStyle.paint_hint(_hint)
	ScreenStyle.paint_primary(_retry)
	ScreenStyle.paint_secondary(_menu)


func _on_retry() -> void:
	if _chosen:
		return
	_chosen = true
	restart_pressed.emit()


func _on_menu() -> void:
	if _chosen:
		return
	_chosen = true
	main_menu_pressed.emit()
