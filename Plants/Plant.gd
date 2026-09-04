class_name Plant extends Node2D


signal harvested(plant: Plant)


@export var plant_data: PlantData


var current_stage: int = 0
var ready_to_harvest: bool = false
var player_nearby: bool = false
var soil: SoilCell


@onready var sprite: AnimatedSprite2D = $PlantSprite
@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	if plant_data == null:
		print("ERRO: PlantData não definido.")
		return

	sprite.sprite_frames = plant_data.sprite_frames
	sprite.frame = 0

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

	print("Plant criada: ", plant_data.plant_name)

	grow()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("space"):
		return

	if not player_nearby:
		return

	if not ready_to_harvest:
		print(plant_data.plant_name, " ainda não está pronta para colher.")
		return

	harvest()


func grow() -> void:
	current_stage = 0
	sprite.frame = current_stage

	while current_stage < plant_data.growth_stages - 1:

		# Se estiver seco, espera até o solo ser molhado.
		while not soil.watered:
			print(
				plant_data.plant_name,
				" está esperando água."
			)

			await soil.watered_changed

		# Solo está molhado. Agora começa o tempo de crescimento.
		await get_tree().create_timer(
			plant_data.growth_time
		).timeout

		# Pode ter secado enquanto esperava.
		if not soil.watered:
			continue

		current_stage += 1
		sprite.frame = current_stage

		print(
			plant_data.plant_name,
			" cresceu para o estágio ",
			current_stage
		)

	ready_to_harvest = true

	print(
		plant_data.plant_name,
		" está pronta para colher!"
	)


func harvest() -> void:
	if not ready_to_harvest:
		return
	print("Colhido: ", plant_data.plant_name, " x", plant_data.harvest_quantity)

	harvested.emit(self)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
