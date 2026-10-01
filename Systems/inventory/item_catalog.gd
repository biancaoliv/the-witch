extends Node

const ITEM_PATHS: Array[String] = [
	"res://Systems/inventory/data/hoe.tres",
	"res://Systems/inventory/data/watering_can.tres",
	"res://Systems/inventory/data/corn_seed.tres",
	"res://Systems/inventory/data/tomato_seed.tres",
	"res://Systems/inventory/data/beet_seed.tres",
	"res://Systems/inventory/data/corn_item.tres",
	"res://Systems/inventory/data/tomato_item.tres",
	"res://Systems/inventory/data/beet_item.tres",
]

var _items: Dictionary = {}
var is_valid: bool = false


func _ready() -> void:
	is_valid = _build_catalog()
	if is_valid:
		print("Catálogo de itens pronto: %d itens." % _items.size())


func _build_catalog() -> bool:
	_items.clear()
	var pending: Dictionary = {}
	for path in ITEM_PATHS:
		var data := load(path) as ItemData
		if data == null:
			push_error("Catálogo: recurso inválido em %s" % path)
			return false
		if data.item_id.is_empty() or data.item_id != data.item_id.strip_edges():
			push_error("Catálogo: Item Id vazio ou com espaços nas extremidades em %s" % path)
			return false
		if pending.has(data.item_id):
			push_error("Catálogo: Item Id duplicado: %s" % data.item_id)
			return false
		pending[data.item_id] = data
	_items = pending
	return true


func get_item(item_id: String) -> ItemData:
	if not is_valid:
		push_error("Catálogo de itens indisponível. Verifique os erros de inicialização.")
		return null
	if not _items.has(item_id):
		push_error("Item Id desconhecido: %s" % item_id)
		return null
	return _items[item_id] as ItemData
