extends CenterContainer


var _data: InventoryItemData

@onready var _rarity_label: Label = %RarityLabel
@onready var _quantity_label: Label = %QuantityLabel


func _ready() -> void:
	_refresh()


func set_data(data: InventoryItemData) -> void:
	_data = data
	_refresh()


func _refresh() -> void:
	if not is_node_ready() or not _data:
		return
	
	_rarity_label.text = InventoryItemData.Rarity.keys()[_data.rarity - 1]
	_quantity_label.text = str(_data.quantity)
	tooltip_text = str(_data.to_dict())
