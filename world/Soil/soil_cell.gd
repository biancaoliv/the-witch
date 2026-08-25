class_name SoilCell extends RefCounted

signal watered_changed(is_watered: bool)


enum SoilState {
	VIRGIN,
	TILLED,
	PLANTED,
	INFERTILE,
	DEAD
}


var state: SoilState = SoilState.VIRGIN

var watered: bool = false
var fertilized: bool = false

var plant: Plant = null


func can_till() -> bool:
	return state == SoilState.VIRGIN


func can_plant() -> bool:
	return state == SoilState.TILLED


func can_water() -> bool:
	return (
		state == SoilState.TILLED
		or state == SoilState.PLANTED
	)


func can_fertilize() -> bool:
	return (
		state == SoilState.TILLED
		or state == SoilState.PLANTED
	)

func set_watered(value: bool) -> void:
	if watered == value:
		return
	
	watered = value
	watered_changed.emit(watered)