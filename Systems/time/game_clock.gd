extends Node

signal time_changed(hour: int, minute: int)
signal day_changed(day: int, season: int, year: int)
signal season_changed(season: int, year: int)
signal year_changed(year: int)
signal day_ended
signal morning_started

enum Season { SPRING, SUMMER, AUTUMN, WINTER }

const DAYS_PER_SEASON: int = 28
const MINUTES_PER_STEP: int = 10
const SECONDS_PER_STEP: float = 7.0
const WAKE_MINUTE: int = 6 * 60
const END_MINUTE: int = 2 * 60
const SEASON_NAMES: Array[String] = ["Primavera", "Verão", "Outono", "Inverno"]

var day: int = 1
var season: int = Season.SPRING
var year: int = 1
var total_days: int = 0
var minute_of_day: int = WAKE_MINUTE
var paused: bool = false
var waiting_for_morning: bool = false

var _elapsed: float = 0.0
var _advancing_to_morning: bool = false


func _process(delta: float) -> void:
	if paused or waiting_for_morning or _advancing_to_morning:
		return
	_elapsed += delta
	while _elapsed >= SECONDS_PER_STEP:
		_elapsed -= SECONDS_PER_STEP
		_advance_step()
		if minute_of_day == END_MINUTE:
			waiting_for_morning = true
			_elapsed = 0.0
			day_ended.emit()
			break
		if paused:
			break


func get_hour() -> int:
	return floori(minute_of_day / 60.0)


func get_minute() -> int:
	return minute_of_day % 60


func get_time_text() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]


func get_date_text() -> String:
	return "Dia %d — %s — Ano %d" % [day, SEASON_NAMES[season], year]


func _advance_step() -> void:
	minute_of_day += MINUTES_PER_STEP
	if minute_of_day >= 24 * 60:
		minute_of_day -= 24 * 60
		_advance_calendar()
	time_changed.emit(get_hour(), get_minute())


func _advance_calendar() -> void:
	total_days += 1
	day += 1
	if day > DAYS_PER_SEASON:
		day = 1
		season += 1
		if season > Season.WINTER:
			season = Season.SPRING
			year += 1
			year_changed.emit(year)
		season_changed.emit(season, year)
	day_changed.emit(day, season, year)


# A cama e o encerramento da jornada poderão chamar esta função.
# Antes das 06:00, acorda no mesmo dia do calendário.
# A partir das 06:00, acorda no dia seguinte.
func advance_to_next_morning() -> void:
	if _advancing_to_morning:
		return
	_advancing_to_morning = true
	var target_day: int = total_days
	if minute_of_day >= WAKE_MINUTE:
		target_day += 1
	var target: int = target_day * 1440 + WAKE_MINUTE
	while total_days * 1440 + minute_of_day < target:
		_advance_step()
	_elapsed = 0.0
	waiting_for_morning = false
	_advancing_to_morning = false
	morning_started.emit()

func get_save_data() -> Dictionary:
	return {
		"day": day,
		"season": season,
		"year": year,
		"total_days": total_days,
		"minute_of_day": minute_of_day,
		"elapsed": _elapsed,
		"waiting_for_morning": waiting_for_morning
	}

func load_save_data(data: Dictionary) -> bool:
	var limits: Dictionary = {
		"day": [1, DAYS_PER_SEASON],
		"season": [Season.SPRING, Season.WINTER],
		"year": [1, 999999],
		"total_days": [0, 999999 * DAYS_PER_SEASON * 4],
		"minute_of_day": [0, 1439]
	}

	for key in limits:
		var value: Variant = data.get(key)

		if not (value is int or value is float):
			return false
		if not is_finite(float(value)):
			return false
		if float(value) != floor(float(value)):
			return false
		if value < limits[key][0] or value > limits[key][1]:
			return false

	var elapsed: Variant = data.get("elapsed")
	if not (elapsed is int or elapsed is float):
		return false
	if not is_finite(float(elapsed)):
		return false
	if elapsed < 0 or elapsed >= SECONDS_PER_STEP:
		return false

	var waiting: Variant = data.get("waiting_for_morning")
	if not waiting is bool:
		return false

	var expected_days: int = (
		(int(data["year"]) - 1) * DAYS_PER_SEASON * 4
		+ int(data["season"]) * DAYS_PER_SEASON
		+ int(data["day"]) - 1
	)

	if int(data["total_days"]) != expected_days:
		push_error("Calendário salvo inconsistente.")
		return false

	if waiting and int(data["minute_of_day"]) != END_MINUTE:
		return false

	day = int(data["day"])
	season = int(data["season"])
	year = int(data["year"])
	total_days = int(data["total_days"])
	minute_of_day = int(data["minute_of_day"])
	_elapsed = float(elapsed)
	waiting_for_morning = waiting
	_advancing_to_morning = false

	# Atualiza o texto do calendário e a iluminação.
	time_changed.emit(get_hour(), get_minute())
	return true