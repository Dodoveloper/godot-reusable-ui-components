@tool
extends ToggleableDisplay


signal quit_requested

@onready var _resume_button: Button = %ResumeButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)


func _open() -> void:
	show()


func _close() -> void:
	hide()


func _on_resume_button_pressed() -> void:
	_request_close()


func _on_quit_button_pressed() -> void:
	quit_requested.emit()
