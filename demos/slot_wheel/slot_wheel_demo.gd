@tool
extends Control


## Emitted when [b]all[/b] wheels finished spinning.
signal spin_finished

@export var wheels: Array[SlotWheel]:
	set(value):
		wheels = value
		update_configuration_warnings()
## Seconds of delay between each wheel's starting moment.
@export var wheel_start_delay := 0.15

@export_group("Editor Preview", "preview_")
@export_tool_button("Start Spin", "PlayStart") var preview_start_spin := (
	func():
		var indexes: Array[int] = []
		for i in range(wheels.size()):
			var wheel := wheels[i]
			var idx := randi_range(0, wheel._item_count - 1)
			print("Wheel %d target value %s" % [i, wheel._items[idx].id])
			indexes.append(idx)
		start_spin(indexes)
)
@export_tool_button("Pause", "Pause") var preview_pause_spin := pause_spin
@export_tool_button("Resume", "Play") var preview_resume_spin := resume_spin
@export var preview_spin_progress := 0.0:
	set(value):
		preview_spin_progress = value
		snap_spin_progress(preview_spin_progress)

var _wheels_finished := 0

var _spin_active := false
var _spin_paused := false
var _spin_start_time := 0.0
var _spin_paused_elapsed := 0.0


func _validate_property(property: Dictionary) -> void:
	if property.name == "preview_spin_progress":
		property.hint = PROPERTY_HINT_RANGE
		var max_time := _calculate_max_spin_time()
		property.hint_string = "0.0, %.2f, 0.01" % [max_time]


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not wheels:
		warnings.append("Wheels not specified")
	
	return warnings


## Initializes all wheels by filling them with items.[br]
## [br]
## [param payload] - Ordered list of wheel data. Each index corresponds to a wheel.
## [codeblock]
## @shape: Array[Array[Dictionary]]
## # Nested array's dictionary
## @shape: {
##   type: String, # WheelItemData.ItemType as uppercase string
##   id?: String, # Required if type not empty
## }
## [/codeblock]
func apply_payload(payload: Array[Array]) -> void:
	for i in range(payload.size()):
		var items: Array[WheelItemData] = []
		for item_dict in payload[i]:
			items.append(WheelItemData.from_dict(item_dict))
		wheels[i].set_items(items)


## Progressively starts spinning all wheels, from first to last, each one with
## delay [member wheel_start_delay].[br]
## [br]
## [param target_indices] - Ordered list of target indices, from the first wheel to the last one.
func start_spin(target_indices: Array[int], duration := -1.0) -> void:
	if not target_indices.size() == wheels.size():
		push_error(
			"Target indices' size %d doesn't match the number of wheels %d"
			% [target_indices.size(), wheels.size()]
		)
		return
	
	var now := Time.get_ticks_msec() * 0.001
	_spin_start_time = now
	_spin_active = true
	_spin_paused_elapsed = 0.0
	_spin_paused = false
	
	_wheels_finished = 0
	
	for i in wheels.size():
		var wheel := wheels[i]
		if not wheel.spin_finished.is_connected(_on_wheel_spin_finished):
			wheel.spin_finished.connect(_on_wheel_spin_finished)
		
		var delay := i * wheel_start_delay
		# Pass the start time to shift the wheel's internal start time, to keep it deterministic
		if duration > 0.0:
			wheel.spin_to_index(target_indices[i], now + delay, duration)
		else:
			wheel.spin_to_index(target_indices[i], now + delay)


func pause_spin() -> void:
	if not _spin_active or _spin_paused:
		return
	
	var now := Time.get_ticks_msec() * 0.001
	_spin_paused_elapsed = now - _spin_start_time
	_spin_paused = true
	
	for wheel in wheels:
		wheel.pause_spin()


func resume_spin() -> void:
	if not _spin_active or not _spin_paused:
		return
	
	var now := Time.get_ticks_msec() * 0.001
	_spin_start_time = now - _spin_paused_elapsed
	_spin_paused = false
	
	for wheel in wheels:
		wheel.resume_spin()


func snap_spin_progress(global_time_offset: float) -> void:
	if not _spin_active:
		return
	
	for i in wheels.size():
		var wheel := wheels[i]
		var delay := i * wheel_start_delay
		
		var local_time := global_time_offset - delay
		if local_time < 0.0:
			# Wheel hasn't started yet
			continue
		
		var wheel_progress := local_time / wheel.spin_duration
		wheel.snap_spin_progress(wheel_progress)


func get_total_spin_duration() -> float:
	var total_duration := 0.0
	for i in range(wheels.size()):
		var delay := i * wheel_start_delay
		total_duration += wheels[i].spin_duration + delay
	
	return total_duration


func _calculate_max_spin_time() -> float:
	var max_time := 0.0
	for i in wheels.size():
		var time := i * wheel_start_delay + wheels[i].spin_duration
		max_time = maxf(max_time, time)
	
	return max_time


func _on_wheel_spin_finished() -> void:
	_wheels_finished += 1
	if _wheels_finished == wheels.size():
		_spin_active = false
		spin_finished.emit()
