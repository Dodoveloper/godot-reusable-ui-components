@abstract
@icon("res://addons/reusable-ui-components/assets/icons/list_unordered.svg")
class_name ListDisplay
extends Control
## Abstract UI element for displaying a dynamic list of [Control] nodes bound to arbitrary data.
##
## Supports adding, updating, removing, sorting, and batching elements efficiently.


## Sorting direction.
enum SortDir {
	ASC = 1,
	DESC = -1,
}

## Single source of truth of the elements tracked by the Display.[br]
## It is only concerned with keeping track of the elements involved in the Display, associated to
## their unique id. It has no implications in terms of display order or state.
## [codeblock]
## @shape: {
##     [id: Variant]: [payload: Variant]
## }
## [/codeblock]
var _elements: Dictionary = {}
## Maps each element's id to its corresponding UI node.
## [codeblock]
## @shape: {
##     [id: Variant]: [ui_element: Control]
## }
## [/codeblock]
## [b]NOTE[/b]: it only tracks elements whose nodes are currently mounted.
var _ids_to_nodes: Dictionary[Variant, Control] = {}
## Ordered list of ids, representing the current sort order.[br]
## Its indexes correspond to the children node's indexes of this class.
var _ordered_ids: Array = []

## Maximum number of elements to display at once. Nodes beyond this limit are not instantiated.
var _visible_count := 9999
## Used to enable imperative sorting. It must return an array of values to sort by.
## [codeblock]
## # Sorts by higher -> lower rarity.
## # Items of same rarity are sorted by older -> newer
## list_display.set_sort(func(item):
##     return [-item.rarity, item.created_at]
## )
## [/codeblock]
var _sort_callable := Callable()
## Used to enable declarative sorting. It must be an array of dictionaries describing the property
## and sort direction to sort by.
## [codeblock]
## # Sorts by higher -> lower rarity.
## # Items of same rarity are sorted by older -> newer
## list_display.set_sort_rules([
##     {"field": "rarity", "dir": SortDir.DESC }
##     {"field": "created_at", "dir": SortDir.ASC }
## ])
## [/codeblock]
var _sort_rules: Array[Dictionary] = []
var _preserve_input_order := false

var _is_dirty := false
var _is_sorting_blocked := false


#region Built-in Virtual methods
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	_resort_and_refresh()
#endregion


#region Custom Virtual methods
## Virtual method. It should only instantiate a [Control] node and return it.
@abstract func _create_node() -> Control


## Virtual method. It should only update [param node]'s properties from [param element].
@abstract func _update_node(node: Control, element: Variant) -> void


## Virtual method. It should retrieve the unique id from [param element] and return it.
@abstract func _get_id(element: Variant) -> Variant
#endregion


#region Public methods
## Replaces the tracked elements with [param elements], diffing against the current state.[br]
## Only nodes for IDs that are no longer present are removed, nodes for IDs that already exist are
## updated in-place and nodes for new IDs are created.[br]
## Performs batch resorting based on the current rules.
func set_elements(elements: Array) -> void:
	_preserve_input_order = false
	pause_sorting()
	
	# Build a set of incoming IDs for O(1) lookup.
	var incoming_ids: Dictionary = {}
	for element in elements:
		var id = _get_id(element)
		incoming_ids[id] = true
	
	# Remove nodes whose IDs are no longer in the incoming list.
	var ids_to_remove: Array = []
	for id in _elements.keys():
		if not incoming_ids.has(id):
			ids_to_remove.append(id)
	for id in ids_to_remove:
		_remove_element(id)
	
	# Upsert all incoming elements.
	for element in elements:
		set_element(element)
	
	resume_sorting()


## Replaces the tracked elements and preserves the order received in [param elements].
## Use this when upstream code already performed filtering, sorting, and paging.
func set_ordered_elements(elements: Array) -> void:
	_preserve_input_order = true
	pause_sorting()
	
	var incoming_ids: Dictionary = {}
	var ordered_ids: Array = []
	for element in elements:
		var id = _get_id(element)
		incoming_ids[id] = true
		ordered_ids.append(id)
	
	var ids_to_remove: Array = []
	for id in _elements.keys():
		if not incoming_ids.has(id):
			ids_to_remove.append(id)
	for id in ids_to_remove:
		_remove_element(id)
	
	for element in elements:
		set_element(element)
	
	_ordered_ids = ordered_ids
	_is_dirty = true
	resume_sorting()


## Adds or updates a single element.[br]
## [br]
## [param element] - The element to be set.
func set_element(element: Variant) -> void:
	var id = _get_id(element)
	_elements[id] = element
	_is_dirty = true


## Removes an element by id and resorts.[br]
## [br]
## [param id] - The id of the element to be removed. It must be a key present in [member _elements].
func remove_element(id: Variant) -> void:
	if _remove_element(id):
		_is_dirty = true


## Returns [code]true[/code] if the element with id [param id] is tracked by this Display.
func has_element(id: Variant) -> bool:
	return _elements.has(id)


## Returns [code]true[/code] if all the elements tracked by this list are fully loaded.
func is_fully_loaded() -> bool:
	return _visible_count >= _elements.size()


## Updates the number of elements visible in the display.
## Triggers a refresh on next frame if the value changes.
func set_visible_count(visible_count: int) -> void:
	if _visible_count == visible_count:
		return
	
	_visible_count = visible_count
	_is_dirty = true


## Imperative sort using a [Callable].[br]
## See [member _sort_callable] for a reference on how [param sort_callable] should be.
func set_sort(sort_callable: Callable) -> void:
	_preserve_input_order = false
	if _sort_callable != sort_callable:
		_is_dirty = true
	_sort_callable = sort_callable
	_sort_rules.clear()


## Declarative sort using an [Array] of rules.[br]
## [param sort_rules]'s elements should be shaped as follows:
## [codeblock]
## @shape: {
##     field: Variant,
##     dir: SortDir,
## }
## [/codeblock]
## See [member _sort_rules] for an example on how [param sort_rules] should be.
func set_sort_rules(sort_rules: Array[Dictionary]) -> void:
	_preserve_input_order = false
	if _sort_rules != sort_rules:
		_is_dirty = true
	_sort_rules = sort_rules
	_sort_callable = Callable()


## Pauses sorting. It will suppress resort/refresh until [method resume_sorting] is called.
func pause_sorting() -> void:
	_is_sorting_blocked = true


## Resumes sorting. It will run pending resort/refresh if needed.
func resume_sorting() -> void:
	_is_sorting_blocked = false


## Wipes all nodes and local state.
func clear() -> void:
	for node in _ids_to_nodes.values():
		node.queue_free()
	_elements.clear()
	_ids_to_nodes.clear()
	_ordered_ids.clear()
#endregion


#region Private methods
## Create or update the UI node for the element.
func _upsert_node(id: Variant, element: Variant) -> void:
	if not _ids_to_nodes.has(id):
		var node := _create_node()
		_ids_to_nodes[id] = node
		add_child(node)
	
	_update_node(_ids_to_nodes[id], element)


func _remove_element(id: Variant) -> bool:
	if not _elements.has(id):
		push_error("Tried to remove non-existent id '%s'" % str(id))
		return false
	
	_remove_node_only(id)
	_elements.erase(id)
	_ordered_ids.erase(id)
	return true


func _remove_node_only(id: Variant) -> void:
	var node: Control = _ids_to_nodes.get(id, null)
	if node:
		node.queue_free()
	_ids_to_nodes.erase(id)


# NOTE: since Array.sort_custom seems to be using heapsort behind the scenes, calling
# such function and passing it this callable has complexity O(n log n * k), where n is the size of
# the array and k the number of sort keys.
## Comparator to be passed to [method Array.sort_custom] when custom sorting.[br]
## Returns [code]true[/code] if [param a_id] should be moved [b]before[/b] [param b_id].
func _compare_elements(a_id: Variant, b_id: Variant) -> bool:
	var a = _elements[a_id]
	var b = _elements[b_id]
	
	if _sort_callable.is_valid():
		var sort_key_a = _sort_callable.call(a)
		var sort_key_b = _sort_callable.call(b)
		if sort_key_a != sort_key_b:
			return sort_key_a < sort_key_b
	elif not _sort_rules.is_empty():
		for rule in _sort_rules:
			var field: String = rule.get("field")
			var dir: int = rule.get("dir", SortDir.ASC)
			var value_a = a.get(field)
			var value_b = b.get(field)
			if value_a != value_b:
				return value_a < value_b if dir == SortDir.ASC else value_a > value_b
	
	# Fallback to ascending order
	return a_id < b_id


## Resorts elements. Meant to be called per-frame and only when necessary.
func _resort_and_refresh() -> void:
	if not _is_dirty or _is_sorting_blocked:
		return
	
	if not _preserve_input_order:
		_ordered_ids = _elements.keys()
		_ordered_ids.sort_custom(_compare_elements)
	
	# NOTE: we do this to avoid doing _ordered_ids.find(id), which would be O(n*m).
	var indexes_by_ids := {}
	for i in range(_ordered_ids.size()):
		indexes_by_ids[_ordered_ids[i]] = i
	_sync_visible_nodes(indexes_by_ids)
	_refresh_nodes_order()
	
	_is_dirty = false


## Performs actual node upsertion based on [member _visible_count].
func _sync_visible_nodes(indexes_by_ids: Dictionary) -> void:
	var target_count := mini(_visible_count, _ordered_ids.size())
	
	# 1. Ensure nodes exist for visible range
	for i in range(target_count):
		var id = _ordered_ids[i]
		_upsert_node(id, _elements[id])
	
	# 2. Remove nodes that are no longer visible
	var ids_to_remove: Array = []
	for id in _ids_to_nodes.keys():
		var index: int = indexes_by_ids.get(id, -1)
		if index == -1 or index >= target_count:
			ids_to_remove.append(id)
	for id in ids_to_remove:
		_remove_node_only(id)


## Syncs child order with [member _ordered_ids].
func _refresh_nodes_order() -> void:
	var target_count := mini(_visible_count, _ordered_ids.size())
	for i in range(target_count):
		var id = _ordered_ids[i]
		var node := _ids_to_nodes[id]
		if node and node.get_index() != i:
			move_child(node, i)
#endregion
