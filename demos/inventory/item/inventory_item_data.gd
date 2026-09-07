class_name InventoryItemData
extends RefCounted
## Data model for inventory items.
## 
## Designed to be passed to [ItemListDisplay] as element payloads.


enum Rarity {
	COMMON = 1,
	UNCOMMON = 2,
	RARE = 3,
	EPIC = 4,
	LEGENDARY = 5,
}

var id: int
var item_name: String
var rarity: int
var quantity: int


func to_dict() -> Dictionary[StringName, Variant]:
	return {
		&"id": id,
		&"name": item_name,
		&"rarity": rarity,
		&"quantity": quantity,
	} as Dictionary[StringName, Variant]


## Factory method to create a random inventory item.
static func create_random(id_: int) -> InventoryItemData:
	var item := InventoryItemData.new()
	item.id = id_
	item.item_name = _generate_item_name()
	item.rarity = randi_range(Rarity.COMMON, Rarity.LEGENDARY)
	item.quantity = randi_range(1, 99)
	
	return item


static func _generate_item_name() -> String:
	var names: Array[String] = [
		"Sword",
		"Shield",
		"Potion",
		"Scroll",
		"Ring",
		"Amulet",
		"Boots",
		"Gloves",
		"Cloak",
		"Helm",
	]
	return names[randi() % names.size()]
