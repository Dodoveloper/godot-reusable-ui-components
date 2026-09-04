@tool
@icon("res://addons/reusable-ui-components/assets/icons/tablet.svg")
class_name ToggleableDisplay
extends Control
## Base class for dismissable UI displays managed by external systems or local scene logic.
##
## It provides shared request signals, input hooks, and input-blocking behavior while remaining
## agnostic to whether the display is shown/hidden, instantiated/freed, or otherwise controlled.[br]
## This class is intended to be subclassed and customized.


enum MountMode {
	## Pre-instantiated, visibility toggled externally or via [member toggle_action].
	CACHED,
	## Mounted/unmounted every time, [member close_action] signals unmount.
	LAZY_LOADED,
}

signal open_requested
signal close_requested

## The display's mount mode.
@export var mount_mode := MountMode.CACHED:
	set(value):
		mount_mode = value
		notify_property_list_changed()
		update_configuration_warnings()
## Whether this display should block player inputs while its visible.
@export var should_block_inputs := true
## [b]Optional[/b] input action available that toggles the visibility of this display when pressed
## ([code]CACHED[/code] mode only).[br]
## [b]NOTE:[/b] It must be a valid input action registered under [InputMap].
@export var toggle_action := &"":
	set(value):
		toggle_action = value
		update_configuration_warnings()
## [b]Optional[/b] input action that unmounts this display when pressed
## ([code]LAZY_LOADED[/code] mode only).
## Leave empty to disable keyboard-based unmounting; the display can still be closed via
## [method _request_close] or other mechanisms.[br]
## [b]NOTE:[/b] It must be a valid input action registered under [InputMap].
@export var close_action := &"":
	set(value):
		close_action = value
		update_configuration_warnings()

var _is_blocking_inputs := false


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	_unblock_inputs()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if _should_grab_focus():
		focus_mode = Control.FOCUS_ALL
		grab_focus.call_deferred()
	
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	var viewport := get_viewport()
	if _handle_input(event):
		viewport.set_input_as_handled()


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"toggle_action":
			if mount_mode != MountMode.CACHED:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"close_action":
			if mount_mode != MountMode.LAZY_LOADED:
				property.usage = PROPERTY_USAGE_NO_EDITOR


#region Custom Virtual Methods
## Virtual method. Override to determine whether this display should grab focus
## when it becomes active. Defaults to [code]true[/code].
func _should_grab_focus() -> bool:
	return true


@warning_ignore("unused_parameter")
## Virtual. Override to add custom input handling (e.g. a busy check).
## The base implementation handles the mode's close/toggle action automatically.[br]
## Should return [code]true[/code] if the event is marked for consumption
## (prevents further propagation), [code]false[/code] otherwise.
func _handle_input(event: InputEvent) -> bool:
	match mount_mode:
		MountMode.LAZY_LOADED:
			if close_action and event.is_action_pressed(close_action):
				_request_close()
				return true
		MountMode.CACHED:
			if toggle_action and event.is_action_pressed(toggle_action):
				if visible:
					_request_close()
				else:
					_request_open()
				return true
	
	return false


## Virtual method. Override to handle opening logic.
func _open() -> void:
	pass


## Virtual method. Override to handle closing logic.
func _close() -> void:
	pass


## Virtual method. Override to handle open requests. It should emit [signal open_requested].
func _request_open() -> void:
	open_requested.emit()


## Virtual method. Override to handle close requests. It should emit [signal close_requested].
func _request_close() -> void:
	close_requested.emit()
#endregion


#region Public API
## Invokes this display’s local open hook.[br]
## This method does not impose any specific lifecycle model; subclasses may use it to
## show themselves, start animations, populate state, or do nothing.
func open() -> void:
	_open()


## Invokes this display’s local close hook.[br]
## This method does not impose any specific lifecycle model; subclasses may use it to
## hide themselves, start close animations, emit signals, or do nothing.
func close() -> void:
	_close()
#endregion


func _block_inputs() -> void:
	if not should_block_inputs:
		return
	if _is_blocking_inputs:
		return
	
	_is_blocking_inputs = true


func _unblock_inputs() -> void:
	if not _is_blocking_inputs:
		return
	
	_is_blocking_inputs = false


## Virtual method. Override to implement the actual input-blocking logic.
func _on_block_inputs() -> void:
	pass


## Virtual method. Override to implement the actual input-unblocking logic.
func _on_unblock_inputs() -> void:
	pass


func _on_visibility_changed() -> void:
	if visible:
		_block_inputs()
	else:
		_unblock_inputs()
