extends PlayerState

# O que acontece quando o jogador entra nesse estado?
func enter() -> void:
	player.update_animation("idle")

# O que acontece durante o _process(atualização) de processo neste estado?
func physics_update(_delta: float) -> void:
	if player.is_moving():
		player.change_state("walk")
		return

	player.velocity = Vector2.ZERO