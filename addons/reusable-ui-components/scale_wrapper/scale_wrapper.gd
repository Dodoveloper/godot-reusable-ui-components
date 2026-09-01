@tool
class_name ScaleWrapper
extends Control
## A wrapper that adapts its minimum size to a single child [Control].
##
## Useful when [Control] nodes which are children of [Container] nodes want to set their own scale,
## thus not have their [Container] parent override it.[br]
## [br]
## Usage:[br]
## - Add this node/scene.[br]
## - Add the target [Control] as a child of this node.[br]
## - Set the scale directly on the target [Control].
## @experimental


var _target_control: Control
var _last_scale := Vector2.ONE


func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)
	
	if get_child_count() > 0:
		var child := get_child(0)
		if child is Control:
			_set_control(child)


func _process(_delta: float) -> void:
	# Check if control scale changes, resize if so.
	# NOTE: there is no scale_changed signal on Control, so we poll each frame.
	# This means scale changes will not be detected while the node's process is paused
	# (e.g. inside a paused SubViewport or when process_mode is set to Disabled/WhenPaused).
	if not _target_control or _target_control.scale == _last_scale:
		return
	
	_last_scale = _target_control.scale
	_on_control_resized()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not _target_control:
		warnings.append("Target control child missing, add it as a child of this node")
	if get_child_count() > 1:
		warnings.append("Multiple children detected. Only one is allowed")
	if is_inside_tree() and get_parent() != null and not get_parent() is Container:
		warnings.append("ScaleWrapper should be a direct child of a Container. Anchor presets may produce unexpected results outside of a Container.")
	
	return warnings


func _set_control(node: Control) -> void:
	_target_control = node
	_last_scale = _target_control.scale
	
	if not _target_control.resized.is_connected(_on_control_resized):
		_target_control.resized.connect(_on_control_resized)
	if not _target_control.visibility_changed.is_connected(_on_control_visibility_changed):
		_target_control.visibility_changed.connect(_on_control_visibility_changed)
	
	_on_control_resized()
	set_process(true)


func _clear_control() -> void:
	if _target_control:
		if _target_control.resized.is_connected(_on_control_resized):
			_target_control.resized.disconnect(_on_control_resized)
		if _target_control.visibility_changed.is_connected(_on_control_visibility_changed):
			_target_control.visibility_changed.disconnect(_on_control_visibility_changed)
	
	_target_control = null
	custom_minimum_size = Vector2.ZERO
	size = Vector2.ZERO
	set_process(false)


func _on_control_resized() -> void:
	if not _target_control:
		return
	
	var new_size := Vector2.ZERO
	if _target_control.is_visible_in_tree():
		new_size = _target_control.size * _target_control.scale
	
	if custom_minimum_size == new_size:
		return
	
	custom_minimum_size = new_size


func _on_control_visibility_changed() -> void:
	_on_control_resized()


func _on_child_entered_tree(node: Node) -> void:
	update_configuration_warnings()
	if _target_control or not node is Control:
		return
	
	_set_control(node)


func _on_child_exiting_tree(node: Node) -> void:
	update_configuration_warnings()
	if node != _target_control:
		return
	
	_clear_control()
