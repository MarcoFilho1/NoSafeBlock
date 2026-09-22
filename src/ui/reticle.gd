extends Control

var focused: bool = false
var reloading: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var point := get_local_mouse_position()
	var color := Color("f1c27b") if focused else Color("e3ebe1")
	var radius: float = 5 if focused else 12
	if reloading:
		draw_arc(point, 12, -PI / 2, TAU * 0.65, 28, Color("dfaa65"), 2, true)
		return
	draw_circle(point, 2, color)
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(point + dir * radius, point + dir * (radius + 7), color, 2, true)
	if focused:
		draw_arc(point, 14, 0, TAU, 40, Color(0.95, 0.76, 0.48, 0.4), 1, true)
