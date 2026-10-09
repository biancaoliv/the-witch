extends Node

const PLANT_PATHS: Array[String] = [
	"res://Systems/farming/data/corn.tres",
	"res://Systems/farming/data/tomato.tres",
	"res://Systems/farming/data/beet.tres",
]

var _plants: Dictionary = {}
var is_valid: bool = false


func _ready() -> void:
	is_valid = _build_catalog()
	if is_valid:
		print("Catálogo de plantas pronto: %d plantas." % _plants.size())


func _build_catalog() -> bool:
	_plants.clear()
	var pending: Dictionary = {}

	for path in PLANT_PATHS:
		var data := load(path) as PlantData

		if data == null:
			push_error("Recurso de planta inválido: " + path)
			return false

		if data.plant_id.is_empty() or data.plant_id != data.plant_id.strip_edges():
			push_error("Plant Id vazio ou com espaços: " + path)
			return false

		if pending.has(data.plant_id):
			push_error("Plant Id duplicado: " + data.plant_id)
			return false

		pending[data.plant_id] = data

	_plants = pending
	return true


func get_plant(plant_id: String) -> PlantData:
	if not is_valid:
		push_error("Catálogo de plantas indisponível.")
		return null

	if not _plants.has(plant_id):
		push_error("Plant Id desconhecido: " + plant_id)
		return null

	return _plants[plant_id] as PlantData