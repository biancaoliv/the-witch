class_name Plant extends Node2D


@export var plant_data: PlantData

@onready var sprite: AnimatedSprite2D = $PlantSprite


func _ready() -> void:
	if plant_data == null:
		print("PlantData não definido.")
		return

	sprite.sprite_frames = plant_data.sprite_frames
	sprite.frame = 0

	print("Plant criada: ", plant_data.plant_name)