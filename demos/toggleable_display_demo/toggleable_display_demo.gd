extends Control


const PauseMenu = preload("res://demos/toggleable_display_demo/pause_menu/pause_menu.gd")
const ConfirmationDialogControl = preload("res://demos/toggleable_display_demo/confirmation_dialog/confirmation_dialog.gd")
const ConfirmationDialogScene = preload("res://demos/toggleable_display_demo/confirmation_dialog/confirmation_dialog.tscn")

@onready var _color_rect: ColorRect = %ColorRect
@onready var _pause_menu: PauseMenu = %PauseMenu


func _ready() -> void:
	_pause_menu.close()
	
	_pause_menu.open_requested.connect(_on_pause_menu_open_requested)
	_pause_menu.close_requested.connect(_on_pause_menu_close_requested)
	_pause_menu.quit_requested.connect(_on_pause_menu_quit_requested)


func _on_pause_menu_open_requested() -> void:
	_pause_menu.open()


func _on_pause_menu_close_requested() -> void:
	_pause_menu.close()


func _on_pause_menu_quit_requested() -> void:
	var dialog: ConfirmationDialogControl = ConfirmationDialogScene.instantiate()
	_color_rect.add_child(dialog)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dialog.close_requested.connect(_on_dialog_close_requested.bind(dialog), CONNECT_ONE_SHOT)
	dialog.confirmed.connect(_on_dialog_confirmed, CONNECT_ONE_SHOT)
	
	_color_rect.show()


func _on_dialog_close_requested(dialog: ConfirmationDialogControl) -> void:
	dialog.queue_free()
	_color_rect.hide()


func _on_dialog_confirmed() -> void:
	get_tree().quit()
