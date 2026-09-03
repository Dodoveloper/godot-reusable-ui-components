extends PanelContainer


const DUMMY_ITEM_COUNT := 100
const PAGE_SIZE := 20
const SCROLL_LOAD_THRESHOLD := 0.5
const SLOTS_PER_ROW := 7
const MIN_TEXTURE_REPEATER_SLOTS := 42

@onready var _sort_by_rarity_button: OptionButton = %SortByRarityButton
@onready var _item_list_display: ListDisplay = %ItemListDisplay
@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _texture_repeater: TextureRepeater = %TextureRepeater

## Tracks sort direction for rarity filter. -1 means not yet active/touched by user.
var _rarity_dir: int = -1
## How many items are currently allowed to be rendered (batch loading).
var _current_visible_count := PAGE_SIZE


func _ready() -> void:
	_item_list_display.set_elements(_generate_dummy_items(DUMMY_ITEM_COUNT))
	_item_list_display.set_visible_count(_current_visible_count)
	_update_texture_repeater_slots(mini(_current_visible_count, DUMMY_ITEM_COUNT))
	
	_sort_by_rarity_button.item_selected.connect(_on_sort_by_rarity_button_item_selected)
	
	# Set up scroll-triggered batch loading
	var scroll_bar := _scroll_container.get_v_scroll_bar()
	scroll_bar.scrolling.connect(_on_scroll_container_scrolling.bind(scroll_bar))


## Generates an array of dummy inventory items for demo purposes.
func _generate_dummy_items(count: int) -> Array:
	var items: Array = []
	for i in range(count):
		items.append(InventoryItemData.create_random(i))
	return items


func _load_next_batch() -> void:
	if _item_list_display.is_fully_loaded():
		return
	
	_current_visible_count += PAGE_SIZE
	_item_list_display.set_visible_count(_current_visible_count)
	_update_texture_repeater_slots(mini(_current_visible_count, DUMMY_ITEM_COUNT))


func _on_sort_by_rarity_button_item_selected(index: int) -> void:
	var dir: int = ListDisplay.SortDir.ASC if index == 0 else ListDisplay.SortDir.DESC
	_rarity_dir = dir
	_item_list_display.set_sort_rules([
		{"field": "rarity", "dir": dir},
		{"field": "id", "dir": ListDisplay.SortDir.ASC}
	])


func _on_scroll_container_scrolling(scroll_bar: ScrollBar) -> void:
	if _item_list_display.is_fully_loaded():
		return
	
	var scroll_pos := _scroll_container.scroll_vertical
	var container_size := _scroll_container.size.y
	var max_scroll: float = scroll_bar.max_value - container_size
	# If the content is shorter than the container, load everything immediately
	if max_scroll <= 0.0:
		_load_next_batch()
		return
	
	var threshold_px: float = container_size * SCROLL_LOAD_THRESHOLD
	if scroll_pos >= max_scroll - threshold_px:
		_load_next_batch()


## Updates the texture repeater to accommodate [param item_count] items.
func _update_texture_repeater_slots(item_count: int) -> void:
	var rows := ceili(float(item_count) / SLOTS_PER_ROW)
	var required_slots := rows * SLOTS_PER_ROW
	_texture_repeater.node_count = maxi(required_slots, MIN_TEXTURE_REPEATER_SLOTS)
