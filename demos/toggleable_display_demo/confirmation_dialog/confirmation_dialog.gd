@tool
extends ToggleableDisplay


signal confirmed


@onready var _close_button: Button = %CloseButton
@onready var _cancel_button: Button = %CancelButton
@onready var _ok_button: Button = %OkButton


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	
	_close_button.pressed.connect(_on_close_button_pressed)
	_cancel_button.pressed.connect(_on_cancel_button_pressed)
	_ok_button.pressed.connect(_on_ok_button_pressed)


func _on_close_button_pressed() -> void:
	_request_close()


func _on_cancel_button_pressed() -> void:
	_request_close()


func _on_ok_button_pressed() -> void:
	confirmed.emit()
