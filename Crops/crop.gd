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


# COLHEITA: Detecta interação se estiver madura
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("space") and player_nearby and ready_to_harvest:
		harvest()


# Chamado diretamente pelo FarmGrid ao ser criada
func plant() -> void:
	if planted:
		return

	planted = true
	ready_to_harvest = false
	sprite.visible = true
	sprite.frame = 0

	grow()


# Ciclo de crescimento baseado nos seus recursos .tres
func grow() -> void:
	for stage in range(crop_data.growth_stages):
		sprite.frame = stage

		if stage < crop_data.growth_stages - 1:
			await get_tree().create_timer(crop_data.growth_time).timeout

	ready_to_harvest = true

	print(
		"A planta ",
		crop_data.crop_name,
		" está pronta para colheita!"
	)


# Realiza a colheita
func harvest() -> void:
	print("Você colheu: ", crop_data.crop_name)

	# Notifica o FarmGrid para liberar o espaço do grid
	var farm_grid = get_parent()

	if farm_grid and farm_grid.has_method("remove_crop_at_position"):
		farm_grid.remove_crop_at_position(global_position)

	# Remove a planta do mapa
	queue_free()


# Sinais do Area2D para saber se o jogador está perto para colher
func _on_crop_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player_nearby = true


func _on_crop_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
