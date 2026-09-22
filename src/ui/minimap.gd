extends Control
var layout: Dictionary = {}
var player_position: Vector3
var discovered: Array = []
func update_map(data: Dictionary, pos: Vector3, stations: Array) -> void:
	layout = data
	player_position = pos
	discovered = stations
	queue_redraw()
func map_point(pos: Vector3) -> Vector2:
	var bounds: Rect2 = layout.bounds
	return Vector2(10, 10) + (Vector2(pos.x, pos.z) - bounds.position) / bounds.size * (size - Vector2(20, 20))
func _draw() -> void:
	draw_style_box(make_style(), Rect2(Vector2.ZERO, size))
	if layout.is_empty(): return
	for lane in [-60, -30, 0, 30, 60]:
		draw_line(map_point(Vector3(lane, 0, -90)), map_point(Vector3(lane, 0, 90)), Color("40514c"), 2)
		draw_line(map_point(Vector3(-90, 0, lane)), map_point(Vector3(90, 0, lane)), Color("40514c"), 2)
	for district in layout.districts:
		draw_circle(map_point(district.position), 4, district.color)
	for node in discovered:
		if is_instance_valid(node):
			draw_rect(Rect2(map_point(node.global_position) - Vector2(2, 2), Vector2(4, 4)), Color("70bfaf"))
	draw_circle(map_point(player_position), 4, Color("ffcf78"))
	draw_arc(map_point(player_position), 6, 0, TAU, 16, Color.WHITE, 1)
func make_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.08, 0.9)
	style.border_color = Color("64796a")
	style.set_border_width_all(1)
	return style
