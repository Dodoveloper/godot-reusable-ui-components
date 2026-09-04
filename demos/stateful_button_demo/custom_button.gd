extends PanelContainer


var _state: StatefulButton.State

@onready var _stateful_button: StatefulButton = %StatefulButton
@onready var _state_label: Label = %StateLabel


func _ready() -> void:
	_update_label()
	
	_stateful_button.state_changed.connect(_on_stateful_button_state_changed)


func _update_label() -> void:
	if not is_node_ready():
		return
	
	_state_label.text = StatefulButton.State.keys()[_state]


func _on_stateful_button_state_changed(new_state: StatefulButton.State) -> void:
	_state = new_state
	_update_label()
