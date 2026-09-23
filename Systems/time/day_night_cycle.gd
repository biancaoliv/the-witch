extends CanvasModulate

@export var night_color: Color = Color("#56618c")
@export var dawn_color: Color = Color("#d8b0a0")
@export var day_color: Color = Color.WHITE
@export var sunset_color: Color = Color("#e8ab80")

@export var transition_seconds: float = 0.6

var transition: Tween


func _ready() -> void:
	color = _get_color_for_time(GameClock.minute_of_day)
	GameClock.time_changed.connect(_on_time_changed)


func _on_time_changed(hour: int, minute: int) -> void:
	var target: Color = _get_color_for_time(hour * 60 + minute)

	if transition != null:
		transition.kill()

	transition = create_tween()
	transition.tween_property(
		self,
		"color",
		target,
		maxf(transition_seconds, 0.01)
	)


func _get_color_for_time(minutes: int) -> Color:
	if minutes < 5 * 60:
		return night_color

	if minutes < 6 * 60:
		return night_color.lerp(
			dawn_color,
			_progress(minutes, 5 * 60, 6 * 60)
		)

	if minutes < 8 * 60:
		return dawn_color.lerp(
			day_color,
			_progress(minutes, 6 * 60, 8 * 60)
		)

	if minutes < 17 * 60:
		return day_color

	if minutes < 19 * 60:
		return day_color.lerp(
			sunset_color,
			_progress(minutes, 17 * 60, 19 * 60)
		)

	if minutes < 21 * 60:
		return sunset_color.lerp(
			night_color,
			_progress(minutes, 19 * 60, 21 * 60)
		)

	return night_color


func _progress(value: int, start: int, finish: int) -> float:
	return clampf(
		float(value - start) / float(finish - start),
		0.0,
		1.0
	)