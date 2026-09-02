class_name WheelItemData
extends RefCounted


enum ItemType {
	TEXT,
	ICON,
	EMPTY,
}

var type: ItemType
var id: String


static func from_dict(data: Dictionary) -> WheelItemData:
	var item := WheelItemData.new()
	item.type = ItemType[data.get("type", "EMPTY")]
	item.id = data.get("id", "")
	
	return item
