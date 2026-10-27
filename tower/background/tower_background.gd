extends Node2D
class_name TowerBackground

## Parallax hinter dem Turm. Jede Parallax2D-Ebene mit einem Sprite wird auf
## den Bildschirm gelegt und folgt GameData.world mit den Grafiken unter
## assets/ghost_world.

var _layers: Array[Dictionary] = []


func _ready() -> void:
	_collect_layers()
	GameData.world_changed.connect(_on_world_changed)
	get_viewport().size_changed.connect(_apply)
	_apply()


func _on_world_changed(_world: GameData.World) -> void:
	_apply()


func _collect_layers() -> void:
	_layers.clear()
	for child in get_children():
		var layer := child as Parallax2D
		if layer == null:
			continue
		var sprite := _first_sprite(layer)
		if sprite == null or sprite.texture == null:
			continue
		var normal := sprite.texture
		var ghost := _ghost_texture(normal)
		_layers.append({
			&"layer": layer,
			&"sprite": sprite,
			&"normal": normal,
			&"ghost": ghost,
		})


func _apply() -> void:
	var ghost_world := GameData.world == GameData.World.GHOST
	for entry in _layers:
		var texture: Texture2D = entry[&"ghost"] if ghost_world else entry[&"normal"]
		_fit(entry[&"layer"], entry[&"sprite"], texture)


## Oben links im Wiederholungsfeld, horizontal mittig, wenn die Grafik breiter
## als der Bildschirm ist. repeat_size enthält die Sprite-Skalierung.
func _fit(layer: Parallax2D, sprite: Sprite2D, texture: Texture2D) -> void:
	sprite.texture = texture
	sprite.centered = false
	var view := get_viewport_rect().size
	var tex_size := texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0 or view.x <= 0.0 or view.y <= 0.0:
		return
	var factor := maxf(view.x / tex_size.x, view.y / tex_size.y)
	sprite.scale = Vector2(factor, factor)
	var drawn := tex_size * factor
	sprite.position = Vector2((view.x - drawn.x) * 0.5, 0.0)
	layer.repeat_size = Vector2(0.0, drawn.y)
	layer.repeat_times = 1


func _first_sprite(layer: Parallax2D) -> Sprite2D:
	for child in layer.get_children():
		if child is Sprite2D:
			return child
	return null


func _ghost_texture(normal: Texture2D) -> Texture2D:
	var path := normal.resource_path
	if path.is_empty() or "/ghost_world/" in path:
		return normal
	var ghost_path := path.get_base_dir().path_join("ghost_world").path_join(path.get_file())
	if not ResourceLoader.exists(ghost_path):
		return normal
	return load(ghost_path)
