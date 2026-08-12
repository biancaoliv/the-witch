class_name Crop extends Node2D

@export var crop_data: CropData


var planted: bool = false
var ready_to_harvest: bool = false
var player_nearby: bool = false


@onready var sprite: AnimatedSprite2D = $CropArea/CropSprite


func _ready() -> void:
	sprite.visible = false

	if crop_data:
		sprite.sprite_frames = crop_data.sprite_frames


# INPUT

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("space") and player_nearby:
		plant()

# PLANTIO

func plant() -> void:
	if planted:
		return

	planted = true
	ready_to_harvest = false

	sprite.visible = true
	sprite.frame = 0

	grow()


# CRESCIMENTO

func grow() -> void:
	for stage in range(crop_data.growth_stages):
		sprite.frame = stage

		if stage < crop_data.growth_stages - 1:
			await get_tree().create_timer(crop_data.growth_time).timeout

	ready_to_harvest = true


# ÁREA DO JOGADOR

func _on_crop_area_body_entered(body: Node2D) -> void:
	player_nearby = true


func _on_crop_area_body_exited(body: Node2D) -> void:
	player_nearby = false
