extends ListDisplay


const InventoryItem = preload("res://demos/inventory_demo/item/inventory_item.gd")

@export var InventoryItemScene: PackedScene


func _create_node() -> Control:
	var node: InventoryItem = InventoryItemScene.instantiate()
	return node


func _update_node(node: Control, element: Variant) -> void:
	var item_node := node as InventoryItem
	var item_data := element as InventoryItemData
	item_node.set_data(item_data)


func _get_id(element: Variant) -> Variant:
	var item_data := element as InventoryItemData
	return item_data.id
