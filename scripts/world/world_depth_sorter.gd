extends Node

const SPRITE_SORT_FRONT_BIAS := 2.0
const FLOOR_Z_INDEX := 1
const WORLD_Z_INDEX := 2

var configured_nodes: Dictionary = {}


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_configure_current_scene")


func _on_scene_changed(_scene_root: Node) -> void:
	call_deferred("_configure_current_scene")


func _on_node_added(node: Node) -> void:
	call_deferred("_configure_added_node", node)


func _configure_current_scene() -> void:
	var scene_root := get_tree().current_scene
	if scene_root != null:
		_configure_tree(scene_root)


func _configure_added_node(node: Node) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null or (node != scene_root and not scene_root.is_ancestor_of(node)):
		return
	_configure_tree(node)


func _configure_tree(node: Node) -> void:
	if node is Camera2D or node is CanvasLayer or node is Control:
		return

	_configure_node(node)
	for child in node.get_children():
		_configure_tree(child)


func _configure_node(node: Node) -> void:
	if not node is Node2D:
		return

	var instance_id := node.get_instance_id()
	if configured_nodes.has(instance_id):
		return
	configured_nodes[instance_id] = true

	if node is TileMapLayer and node.name.to_lower() == "floor":
		node.y_sort_enabled = false
		node.z_index = FLOOR_Z_INDEX
		node.z_as_relative = false
		return
	if node is TileMapLayer and node.name.to_lower() == "floordetails":
		node.y_sort_enabled = false
		node.z_index = FLOOR_Z_INDEX
		node.z_as_relative = false
		return

	node.y_sort_enabled = true
	if node == get_tree().current_scene:
		node.z_index = 0
	else:
		node.z_index = WORLD_Z_INDEX
	node.z_as_relative = false

	if node is TileMapLayer and node.tile_set != null:
		node.y_sort_origin = int(node.tile_set.tile_size.y / 2.0)
	elif node is Sprite2D or node is AnimatedSprite2D:
		_anchor_sprite_to_bottom(node)


func _anchor_sprite_to_bottom(sprite: Node2D) -> void:
	var texture: Texture2D
	var centered: bool
	var frame_size: Vector2

	if sprite is Sprite2D:
		var sprite_2d := sprite as Sprite2D
		texture = sprite_2d.texture
		centered = sprite_2d.centered
		if texture == null:
			return
		frame_size = texture.get_size()
		if sprite_2d.region_enabled:
			frame_size = sprite_2d.region_rect.size
		elif sprite_2d.hframes > 1 or sprite_2d.vframes > 1:
			frame_size /= Vector2(sprite_2d.hframes, sprite_2d.vframes)
	else:
		var animated_sprite := sprite as AnimatedSprite2D
		if animated_sprite.sprite_frames == null or animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation) == 0:
			return
		texture = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
		centered = animated_sprite.centered
		if texture == null:
			return
		frame_size = texture.get_size()

	var bottom_offset: float = sprite.offset.y + frame_size.y
	if centered:
		bottom_offset -= frame_size.y / 2.0
	bottom_offset += SPRITE_SORT_FRONT_BIAS
	if is_zero_approx(bottom_offset):
		return

	sprite.position.y += bottom_offset * sprite.scale.y
	sprite.offset.y -= bottom_offset
