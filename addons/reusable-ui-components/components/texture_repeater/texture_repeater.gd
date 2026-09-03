@tool
@icon("res://addons/reusable-ui-components/assets/icons/duplicate.svg")
class_name TextureRepeater
extends Control
## Generic UI view that instantiates a number of identical [TextureRect] nodes.
## 
## It can be attached as a script for any [Control] node and can be used in
## composition with other UI components.


## Number of nodes to display. It will trigger insertion/removal of [TextureRect] nodes.
@export_range(0, 999, 1, "or_greater") var node_count := 0:
	set = _set_node_count
## Texture to be applied to each node.
@export var texture: Texture2D:
	set = _set_texture


func _ready() -> void:
	_set_node_count(node_count)
	_set_texture(texture)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not texture:
		warnings.append("Slot texture must be set")
	
	return warnings


func _add_slot_node() -> void:
	var slot_node := TextureRect.new()
	slot_node.texture = texture
	add_child(slot_node)
	slot_node.owner = self


func _remove_slot_node(index: int) -> void:
	var slot_node := get_child(index)
	remove_child(slot_node)
	slot_node.queue_free()


func _set_node_count(value: int) -> void:
	node_count = value
	if not is_node_ready() or get_child_count() == value:
		return
	
	var delta := value - get_child_count()
	if delta > 0:
		for i in range(delta):
			_add_slot_node()
	else:
		for i in range(get_child_count() - 1, value - 1, -1):
			_remove_slot_node(i)


func _set_texture(value: Texture2D) -> void:
	texture = value
	update_configuration_warnings()
	if not is_node_ready() or get_child_count() == 0:
		return
	
	var prev_texture := (get_child(0) as TextureRect).texture
	if prev_texture == texture:
		return
	
	for child: TextureRect in get_children():
		child.texture = texture
