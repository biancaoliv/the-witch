class_name Plant extends Node2D


signal harvested(plant: Plant)


@export var plant_data: PlantData


var current_stage: int = 0
var ready_to_harvest: bool = false
var player_nearby: bool = false
var soil: SoilCell
var growth_days_completed: int = 0
var is_dead: bool = false


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

	_update_growth_visual()


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if not event.is_action_pressed("space"):
		return

	if not player_nearby:
		return

	if not ready_to_harvest:
		print(
			plant_data.plant_name,
			" ainda não está pronta para colher."
		)
		return

	harvest()
	get_viewport().set_input_as_handled()


func grow_one_day() -> void:
	if is_dead:
		return
	if plant_data == null or soil == null:
		return

	if ready_to_harvest or not soil.watered:
		return

	growth_days_completed += 1
	_update_growth_visual()

	print(
		plant_data.plant_name,
		" — crescimento: ",
		growth_days_completed,
		"/",
		plant_data.growth_days
	)


func _update_growth_visual() -> void:
	if is_dead:
		return
	var required_days: int = maxi(1, plant_data.growth_days)
	var last_stage: int = maxi(0, plant_data.growth_stages - 1)

	var progress: float = clampf(
		float(growth_days_completed) / float(required_days),
		0.0,
		1.0
	)

	current_stage = floori(progress * last_stage)
	sprite.frame = current_stage

	ready_to_harvest = growth_days_completed >= required_days


func harvest() -> void:
	if is_dead:
		return
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


func die() -> void:
	if is_dead:
		return

	is_dead = true
	ready_to_harvest = false

	# Mantém o estágio atual, mas tingido de vermelho.
	sprite.pause()
	sprite.modulate = Color(1.0, 0.15, 0.15)
	set_process_unhandled_input(false)

	if soil != null:
		soil.state = SoilCell.SoilState.DEAD
		soil.set_watered(false)
