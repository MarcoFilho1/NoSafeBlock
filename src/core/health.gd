extends RefCounted
## Owns hit points; consumers connect to died instead of polling for repeated deaths.

signal changed(current: float, maximum: float)
signal died

var maximum: float
var current: float

func _init(max_hp: float = 100.0) -> void:
	maximum = maxf(1.0, max_hp)
	current = maximum

func damage(amount: float) -> void:
	if amount <= 0.0 or not is_alive():
		return
	current = maxf(0.0, current - amount)
	changed.emit(current, maximum)
	if current == 0.0:
		died.emit()

func is_alive() -> bool:
	return current > 0.0

func heal(amount: float) -> void:
	if amount > 0 and is_alive():
		current = minf(maximum, current + amount)
		changed.emit(current, maximum)
