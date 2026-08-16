class_name SeedStation extends Area2D


@export var plant_data: PlantData

var player_nearby: bool = false
var plant_system: PlantSystem


func _ready() -> void:
	plant_system = get_tree().get_first_node_in_group("plant_system")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("space") and player_nearby:
		if plant_system and plant_data:
			plant_system.selected_plant_data = plant_data

			print(
				"Semente selecionada: ",
				plant_data.plant_name
			)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false