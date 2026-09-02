@tool
@icon("res://addons/reusable-ui-components/assets/icons/wheel.svg")
class_name SlotWheel
extends Control
## A slot-machine-style wheel that scrolls through a looping list of items and 
## can spin to land on a chosen one.
##
## Items (text or icons) are arranged in a loop, scrolling vertically or horizontally,
## and the wheel can spin through them at a configurable speed and duration,
## easing into a smooth stop on a specific item.[br]
## A spin can be paused and resumed at any time, and its progress can be read
## or set directly rather than only driven by elapsed time. That means the exact
## same visual outcome can be reproduced from a handful of values, which makes it
## straightforward to keep several instances -- for example across a network -- in sync.


## Emitted when the wheel has started spinning.
signal spin_started
## Emitted when the wheel has finished spinning.
signal spin_finished
## Emitted when the wheel has paused spinning.
signal spin_paused
## Emitted when the wheel has resumed spinning.
signal spin_resumed

enum Orientation {
	## Top to bottom.
	VERTICAL,
	## Left to right.
	HORIZONTAL
}

## Container that holds the wheel items.
@export var content: BoxContainer:
	set(value):
		content = value
		_apply_orientation()
		update_configuration_warnings()
## Direction in which the wheel scrolls.
@export var orientation := Orientation.VERTICAL:
	set(value):
		orientation = value
		_apply_orientation()
## Fixed size for each wheel item.[br]
## Used to compute scrolling distance and snapping positions.
@export var item_size := Vector2(32, 32):
	set = _set_item_size
## Space (in pixels) between adjacent wheel items.[br]
## Participates in the wheel's scroll and snapping calculations, just like [member item_size].
@export var separation := 0:
	set(value):
		separation = value
		_apply_orientation()
		_update_cycle_length()
		_apply_scroll(_normalized_position)
## List of items for the wheel. [b]NOTE[/b]: this is for editor preview, it won't matter at runtime.
@export var _editor_items: Array[Dictionary] = []:
	set = _editor_set_items

## Style to be applied for all text-type items.[br]
## [b]NOTE:[/b] takes precedence over [member item_text_style].
@export var ItemTextDisplayScene: PackedScene
## Style to be applied for all text-type items.
@export var item_text_style: LabelSettings
## Style to be applied for all texture-type items.
@export var item_texture_style: Dictionary[String, Texture2D] = {}

@export_group("Spin Animation", "spin_")
## Duration (in seconds) of a single spin animation.[br]
## Does not affect speed, only how long the spin lasts.
@export_range(0.1, 20.0, 0.1) var spin_duration := 1.5
## Base scrolling speed in normalized units per second.[br]
## [code]1.0[/code] = one full wheel loop per second.
@export_range(0.1, 20.0, 0.1) var spin_speed := 1.5
## Curve defining the spin motion.
@export var spin_curve: Curve

@export_group("Editor Preview", "preview_")
@export_tool_button("Start Spin", "PlayStart") var preview_spin := (
	func():
		var idx := randi_range(0, _items.size() - 1)
		print("Spinning to value ", _items[idx].id)
		spin_to_index(idx)
)
@export_tool_button("Pause Spin", "Pause") var preview_pause_spin := pause_spin
@export_tool_button("Resume Spin", "Play") var preview_resume_spin := resume_spin
@export var preview_spin_progress := 0.0:
	set(value):
		preview_spin_progress = value
		snap_spin_progress(preview_spin_progress)

## List of items tracked by the wheel.[br]
## Items are duplicated internally to allow seamless looping.[br]
var _items: Array[WheelItemData] = []
## Number of unique items in the wheel.
var _item_count := 0
## List of [b]displayed[/b] items tracked by the wheel.
var _visible_items: Array[WheelItemData] = []
## Map of logical_index -> visual_index.
var _visible_index_map: Dictionary[int, int] = {}
## Number of unique [b]displayed[/b] items in the wheel.
var _visual_item_count := 0
## Total pixel length of one full wheel cycle.[br]
## Equals to [member _visual_item_count] multiplied by [member item_size] (plus [member separation]) along the scroll axis.
var _cycle_length := 0.0
## Current scroll position expressed as an unbounded normalized value.[br]
## Integer values represent full loops, fractional part defines visual offset.
var _normalized_position := 0.0

# Spin State
var _spin_active := false
var _spin_start_time := 0.0
var _spin_duration := 0.0
var _spin_start_pos := 0.0
var _spin_end_pos := 0.0
var _spin_paused := false
var _spin_paused_elapsed := 0.0


func _ready() -> void:
	_set_item_size(item_size)
	_editor_set_items(_editor_items)
	set_normalized_position(_normalized_position)


func _process(_delta: float) -> void:
	if not _spin_active or _spin_paused:
		return
	
	var now := Time.get_ticks_msec() * 0.001
	var value := _evaluate_spin(now)
	set_normalized_position(value)
	
	if now >= _spin_start_time + _spin_duration:
		_spin_active = false
		set_normalized_position(_spin_end_pos)
		spin_finished.emit()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if not content:
		warnings.append("Content must be set")
	
	return warnings


#region Public API
## Sets the list of items displayed by the wheel.[br]
## Rebuilds the internal looped content and resets scroll metrics.
func set_items(items: Array[WheelItemData]) -> void:
	_items = items
	_item_count = items.size()
	_visible_items.clear()
	_visible_index_map.clear()
	
	var visual_index := 0
	for i in range(items.size()):
		var item := items[i]
		if _is_item_empty(item):
			continue
		
		_visible_items.append(item)
		_visible_index_map[i] = visual_index
		visual_index += 1
	_visual_item_count = _visible_items.size()
	
	_rebuild_content()


## Sets the current scroll position using an unbounded normalized value.[br]
## The fractional part determines the visible offset, integer values represent full loops.
func set_normalized_position(value: float) -> void:
	_normalized_position = value
	_apply_scroll(value)


## Spins the wheel and smoothly stops on the given item index.[br]
## [br]
## [param target_index] - The target index of the spin.[br]
## [param spin_start_time] - The starting time of the spin.[br]
## [param duration] - The duration of the spin.
func spin_to_index(target_index: int, spin_start_time := -1.0, duration := spin_duration) -> void:
	_spin_to_index(target_index, spin_start_time, duration)
	spin_started.emit()


## Pauses the current spin, if active.
func pause_spin() -> void:
	if not _spin_active or _spin_paused:
		return
	
	var now := Time.get_ticks_msec() * 0.001
	_spin_paused_elapsed = now - _spin_start_time
	_spin_paused = true
	spin_paused.emit()


## Resumes the current spin, if paused.
func resume_spin() -> void:
	if not _spin_active or not _spin_paused:
		return
	
	var now := Time.get_ticks_msec() * 0.001
	_spin_start_time = now - _spin_paused_elapsed
	_spin_paused = false
	spin_resumed.emit()


## Snaps spin progress to [param progress].
func snap_spin_progress(progress: float) -> void:
	if not _spin_active:
		return
	
	progress = clampf(progress, 0.0, 1.0)
	var eased := spin_curve.sample(progress) if spin_curve else progress
	var value := lerpf(_spin_start_pos, _spin_end_pos, eased)
	set_normalized_position(value)
	
	# Update spin state so resume works correctly
	_spin_paused_elapsed = progress * _spin_duration
#endregion


func _rebuild_content() -> void:
	if not content:
		return
	
	for child in content.get_children():
		child.queue_free()
	
	for _i in range(3):
		for data in _visible_items:
			if not data:
				continue
			
			var item := _create_item(data)
			content.add_child(item)
	
	_update_cycle_length()


func _create_item(data: WheelItemData) -> Control:
	var root := CenterContainer.new()
	root.custom_minimum_size = item_size
	
	match data.type:
		WheelItemData.ItemType.TEXT:
			var display: Control
			if ItemTextDisplayScene:
				display = ItemTextDisplayScene.instantiate()
			else:
				display = Label.new()
				display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				display.label_settings = item_text_style
			display.text = data.id
			root.add_child(display)
		WheelItemData.ItemType.ICON:
			var texture_rect := TextureRect.new()
			var texture: Texture2D = item_texture_style.get(data.id)
			texture_rect.texture = texture
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			root.add_child(texture_rect)
	
	return root


func _update_cycle_length() -> void:
	var item_step := item_size.y + separation if orientation == Orientation.VERTICAL else item_size.x + separation
	_cycle_length = _visual_item_count * item_step


func _evaluate_spin(now: float) -> float:
	var t := (now - _spin_start_time) / _spin_duration if _spin_duration > 0.0 else 1.0
	t = clampf(t, 0.0, 1.0)
	
	var eased := spin_curve.sample(t) if spin_curve else t
	return lerpf(_spin_start_pos, _spin_end_pos, eased)


## Applies a normalized scroll value to the content container.[br]
## Uses modulo arithmetic to loop seamlessly without visible jumps.
func _apply_scroll(normalized: float) -> void:
	if _item_count == 0 or not content:
		return
	
	var pos := fposmod(normalized, 1.0)
	var pixel_offset := pos * _cycle_length
	if orientation == Orientation.VERTICAL:
		content.position.y = -pixel_offset
	else:
		content.position.x = -pixel_offset


## Animates the wheel at constant speed and decelerates to land exactly on the target item index.
func _spin_to_index(target_index: int, spin_start_time: float, duration: float) -> void:
	if _item_count == 0:
		return
	
	var start := _normalized_position
	# Compute how far the wheel should travel
	var travel := spin_speed * duration
	# Compute the raw end position (before snapping)
	var raw_end := start + travel
	
	# Convert target index into normalized space
	target_index = target_index % _item_count
	# Check if the target item is empty
	var target_normalized: float
	var is_item_empty := _is_item_empty(_items[target_index])
	if is_item_empty:
		target_normalized = 0.5 / _visual_item_count
	else:
		var visual_index := _visible_index_map[target_index]
		target_normalized = float(visual_index) / _visual_item_count
	
	# Find the closest occurrence of the normalized target
	var base_loop := floorf(raw_end)
	var end := base_loop + target_normalized
	# Closest occurrence doesn't always mean "future", so ensure we never go backwards
	if end <= raw_end:
		end += 1.0
	
	_spin_start_pos = start
	_spin_end_pos = end
	_spin_duration = duration
	_spin_start_time = spin_start_time if spin_start_time >= 0.0 else Time.get_ticks_msec() * 0.001
	_spin_active = true
	_spin_paused = false
	_spin_paused_elapsed = 0.0


func _apply_orientation() -> void:
	if not content:
		return
	
	content.vertical = orientation == Orientation.VERTICAL
	content.add_theme_constant_override(&"separation", separation)


func _is_item_empty(item: WheelItemData) -> bool:
	if item.id == "0":
		return true
	if item.id.is_empty():
		return true
	
	return false


func _set_item_size(value: Vector2) -> void:
	item_size = value
	custom_minimum_size = item_size
	_update_cycle_length()
	_apply_scroll(_normalized_position)


func _editor_set_items(value: Array[Dictionary]) -> void:
	if not Engine.is_editor_hint():
		return
	
	_editor_items = value
	var items: Array[WheelItemData] = []
	for item_data in _editor_items:
		items.append(WheelItemData.from_dict(item_data))
	if items:
		set_items(items)
