extends Label


func _ready() -> void:
	GameClock.time_changed.connect(_on_time_changed)
	GameClock.day_changed.connect(_on_day_changed)
	_refresh()


func _on_time_changed(_hour: int, _minute: int) -> void:
	_refresh()


func _on_day_changed(_day: int, _season: int, _year: int) -> void:
	_refresh()


func _refresh() -> void:
	text = "%s\n%s" % [
		GameClock.get_time_text(),
		GameClock.get_date_text()
	]