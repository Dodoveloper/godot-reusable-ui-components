@tool
@icon("res://addons/reusable-ui-components/assets/icons/push_button.svg")
class_name StatefulButton
extends BaseButton
## A visual-less button that tracks and exposes its interaction state, useful for
## composing buttons whose visuals go beyond what [i]vanilla[/i] ones support.
##
## It comes with no built-in look, which makes it an ideal building block for
## composition: attach it on top of, or alongside, any node hierarchy
## and react to its signals to drive that hierarchy's appearance.


signal hovered
signal unhovered
signal state_changed(new_state: State)

enum State {
	NORMAL,
	HOVER,
	PRESSED,
	DISABLED,
}

## The button's current state.
@export var state := State.NORMAL:
	set = _set_state
# NOTE: this is needed since there's no built-in way of signaling when a button
# is disabled/enabled and polling seems like overkill to me.
## Whether the button is disabled.[br]
## [b]NOTE[/b]: use this instead of setting [member BaseButton.disabled].
@export var button_disabled: bool:
	set(value):
		button_disabled = value
		disabled = value
		_update_state()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	mouse_entered.connect(_update_state)
	mouse_exited.connect(_update_state)
	button_down.connect(_update_state)
	button_up.connect(_update_state)
	toggled.connect(func(_pressed): _update_state())
	focus_entered.connect(_update_state)
	focus_exited.connect(_update_state)
	
	_update_state()


func _validate_property(property: Dictionary) -> void:
	if property.name == "state":
		property.usage = PROPERTY_USAGE_EDITOR


func _compute_state() -> State:
	if not is_inside_tree():
		return State.NORMAL
	if disabled:
		return State.DISABLED
	if button_pressed:
		return State.PRESSED
	if is_hovered():
		return State.HOVER
	
	return State.NORMAL


func _update_state() -> void:
	var new_state := _compute_state()
	state = new_state


func _set_state(value: State) -> void:
	var previous := state
	if state == value:
		return
	
	state = value
	state_changed.emit(state)
	
	match state:
		State.HOVER:
			hovered.emit()
		State.NORMAL:
			if previous == State.HOVER:
				unhovered.emit()
