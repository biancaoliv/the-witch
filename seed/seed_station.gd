class_name SeedStation extends Area2D

# Arraste o arquivo .tres da semente desejada no Inspector desta estação
@export var crop_data: CropData

var player_nearby: bool = false
var farm_grid: FarmGrid


func _ready() -> void:
	# Encontra o FarmGrid na cena globalmente
	farm_grid = get_tree().get_first_node_in_group("farm_grid")

	# Conecta os próprios sinais da Area2D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	# Pressiona espaço para coletar as sementes da estação
	if event.is_action_released("space") and player_nearby:
		if farm_grid and crop_data:
			farm_grid.selected_seed = crop_data

			print(
				"Você coletou e equipou sementes de: ",
				crop_data.crop_name
			)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
