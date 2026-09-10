class_name PlantData extends Resource


@export_category("Informações")
@export var plant_name: String = ""


@export_category("Crescimento")
@export var growth_time: float = 3.0
@export var growth_stages: int = 6


@export_category("Visual")
@export var sprite_frames: SpriteFrames

@export_group("Colheita")
@export var harvest_item: CropItemData
@export var harvest_quantity: int = 1
