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
