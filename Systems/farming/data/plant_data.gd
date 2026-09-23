class_name PlantData extends Resource


@export_category("Informações")
@export var plant_name: String = ""


@export_category("Crescimento")
@export var growth_time: float = 3.0
@export var growth_stages: int = 6
@export_range(1, 112) var growth_days: int = 5


@export_category("Visual")
@export var sprite_frames: SpriteFrames

@export_group("Colheita")
@export var harvest_item: CropItemData
@export var harvest_quantity: int = 1


@export_category("Estações")
@export_flags("Primavera", "Verão", "Outono", "Inverno")
var allowed_seasons: int = 15


func can_grow_in(season_index: int) -> bool:
	if season_index < 0 or season_index > 3:
		return false

	return (allowed_seasons & (1 << season_index)) != 0
