@tool
@icon("res://addons/reusable-ui-components/assets/icons/box_wireframe.svg")
class_name Node2DWrapper
extends Control
## UI object which can make [Node2D] nodes [Control] nodes, useful when using them inside [Container]s
## or [Control] nodes in general, like a button.
##
## It currently supports a single child node.


## If [code]true[/code], this node's [member custom_minimum_size] won't be set automatically.
@export var manual_resize := false
## If [code]true[/code], the target node's [member Node2D.position] won't be set automatically
@export var manual_positioning := false
## Target [Node2D] which will be wrapped inside this node.
@export var _target_node: Node2D:
	set(value):
		if _target_node == value:
			return
		
		_target_node = value
		_sync_layout()
		update_configuration_warnings()
		notify_property_list_changed()


func _ready() -> void:
	_sync_layout()
	
	resized.connect(_on_resized)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if not _target_node:
		warnings.append("Target Node must be set")
	
	return warnings


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_sync_layout()


## Sets the wrapped [Node2D], replacing any previously set target.[br]
## The node is added as a child of this wrapper, and the wrapper's layout is synchronized
## to match the node's natural extents.[br]
## If a target is already set, it is freed before the new one is adopted.
func set_target_node(value: Node2D) -> void:
	if not is_instance_valid(value):
		return
	
	clear_target_node()
	add_child(value)
	_target_node = value


## Returns the currently wrapped [Node2D], or [code]null[/code] if none is set.
func get_target_node() -> Node2D:
	return _target_node


## Removes and frees the currently wrapped [Node2D]. Does nothing if no target is set.
func clear_target_node() -> void:
	if not is_instance_valid(_target_node):
		return
	
	_target_node.queue_free()
	_target_node = null


func _update_size(size_: Vector2) -> void:
	if custom_minimum_size == size_:
		return
	
	custom_minimum_size = size_
	size = size_


func _update_sprite_position() -> void:
	if manual_positioning or not _target_node:
		return
	
	_target_node.position = size / 2.0


func _sync_layout() -> void:
	if not _target_node or not is_node_ready():
		return
	if manual_resize:
		_update_sprite_position()
		return
	
	var min_size: Vector2
	if _target_node is Sprite2D:
		min_size = (
			_target_node.region_rect.size
			if _target_node.region_enabled
			else _target_node.texture.get_size()
		)
	else:
		if _target_node.has_method(&"get_size"):
			min_size = _target_node.get_size()
		else:
			push_warning("Unsupported Node2D type ", _target_node.to_string())
	
	var target_size := min_size * _target_node.scale
	_update_size(target_size)
	_update_sprite_position()


func _on_resized() -> void:
	_update_sprite_position()
