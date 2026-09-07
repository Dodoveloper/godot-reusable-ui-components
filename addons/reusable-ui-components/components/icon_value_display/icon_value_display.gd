@tool
@icon("res://addons/reusable-ui-components/assets/icons/tag.svg")
class_name IconValueDisplay
extends Control
## Displays an icon and a numeric value, with support for string formatting.
##
## It can be plugged to any [Control] scene, or extended for further customization.


@export_group("Nodes")
## The [TextureRect] node displaying the texture.
@export var icon_node: TextureRect:
	set(value):
		icon_node = value
		update_configuration_warnings()
## The [Label] node which will display the value.
@export var value_node: Label:
	set(value):
		value_node = value
		update_configuration_warnings()

@export_group("Display")
## Format string used when displaying the value. It should contain at least [code]{value}[/code].[br]
## [b]NOTE[/b]: if [member format_callable] is set, this property will be ignored.
@export var format_string := "{value}":
	set = _set_format_string
## Label settings to be applied to [member value_node].
@export var label_settings: LabelSettings:
	set = _set_label_settings

@export_group("Editor Preview", "_preview_")
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR) var _preview_value := 0.0
@warning_ignore("unused_private_class_variable")
@export_tool_button("Play Value Change", "PlayStart") var _preview_play_value_change := (
	func(): set_value(_preview_value, true)
)

## Format callable used when displaying the value. If not set, this object will default to using
## [member format_string].[br]
## The callable must accept a numeric value and return a string. Example:
## [codeblock]func(v: float): return "%.2f" % v[/codeblock]
var format_callable: Callable:
	set = _set_format_callable

## The displayed value.
var _value := 0.0


func _ready() -> void:
	_set_format_string(format_string)
	_set_format_callable(format_callable)
	_set_label_settings(label_settings)
	set_value(_value, false)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not icon_node:
		warnings.append("Icon node must be set")
	if not value_node:
		warnings.append("Value node must be set")
	
	return warnings


func set_value(value: float, should_animate := true) -> void:
	var prev_value := _value
	_value = value
	if not is_node_ready():
		return
	
	_update_value_node(_value)
	if should_animate:
		_on_value_changed(prev_value, _value)


func get_value() -> float:
	return _value


@warning_ignore("unused_parameter")
## Virtual method. Called when [member value] changes, right after updating the UI.
func _on_value_changed(old_value: float, new_value: float) -> void:
	pass


func _update_value_node(value_: float) -> void:
	if format_callable.is_valid():
		value_node.text = str(format_callable.call(value_))
	else:
		var formatted_string := "%.2f" if value_ != round(value_) else "%d"
		value_node.text = format_string.format({"value": formatted_string % value_})


func _set_format_string(value: String) -> void:
	format_string = value
	if not is_node_ready():
		return
	
	_update_value_node(_value)


func _set_format_callable(value: Callable) -> void:
	format_callable = value
	if not is_node_ready():
		return
	
	_update_value_node(_value)


func _set_label_settings(value: LabelSettings) -> void:
	label_settings = value
	if not is_node_ready():
		return
	
	value_node.label_settings = label_settings
