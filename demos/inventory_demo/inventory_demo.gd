extends PanelContainer


const DUMMY_ITEM_COUNT := 24

@onready var _sort_by_rarity_button: OptionButton = %SortByRarityButton
@onready var _sort_by_quantity_button: OptionButton = %SortByQuantityButton
@onready var _item_list_display: ListDisplay = %ItemListDisplay


func _ready() -> void:
	_item_list_display.set_elements(_generate_dummy_items(DUMMY_ITEM_COUNT))
	
	_sort_by_rarity_button.item_selected.connect(_on_sort_by_rarity_button_item_selected)
	_sort_by_quantity_button.item_selected.connect(_on_sort_by_quantity_button_item_selected)


## Generates an array of dummy inventory items for demo purposes.
func _generate_dummy_items(count: int) -> Array:
	var items: Array = []
	for i in range(count):
		items.append(InventoryItemData.create_random(i))
	return items


func _on_sort_by_rarity_button_item_selected(index: int) -> void:
	if index == 0:
		_on_sort_rarity_asc_pressed()
	else:
		_on_sort_rarity_desc_pressed()


func _on_sort_by_quantity_button_item_selected(index: int) -> void:
	if index == 0:
		_on_sort_quantity_asc_pressed()
	else:
		_on_sort_quantity_desc_pressed()


func _on_sort_rarity_asc_pressed() -> void:
	_item_list_display.set_sort_rules([
		{"field": "rarity", "dir": ListDisplay.SortDir.ASC},
		{"field": "id", "dir": ListDisplay.SortDir.ASC}
	])


func _on_sort_rarity_desc_pressed() -> void:
	_item_list_display.set_sort_rules([
		{"field": "rarity", "dir": ListDisplay.SortDir.DESC},
		{"field": "id", "dir": ListDisplay.SortDir.ASC}
	])


func _on_sort_quantity_asc_pressed() -> void:
	_item_list_display.set_sort_rules([
		{"field": "quantity", "dir": ListDisplay.SortDir.ASC},
		{"field": "id", "dir": ListDisplay.SortDir.ASC}
	])


func _on_sort_quantity_desc_pressed() -> void:
	_item_list_display.set_sort_rules([
		{"field": "quantity", "dir": ListDisplay.SortDir.DESC},
		{"field": "id", "dir": ListDisplay.SortDir.ASC}
	])
