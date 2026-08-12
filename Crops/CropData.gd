class_name CropData extends Resource


@export_category("Informações")
@export var crop_name: String = ""


@export_category("Crescimento")
@export var growth_time: float = 3.0
@export var growth_stages: int = 6


@export_category("Visual")
@export var sprite_frames: SpriteFrames