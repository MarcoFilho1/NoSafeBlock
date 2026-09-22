extends StaticBody3D
const Props = preload("res://src/world/props.gd")
var integrity: float = 0
var maximum: float = 300
var repair_left: float = 0
var active: bool = true
var boards: Array[MeshInstance3D] = []
var frame: Array[MeshInstance3D] = []
var label: Label3D
func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	add_to_group("barricades")
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.9, 2.0, 0.4)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 1
	add_child(collision)
	for i in range(3):
		boards.append(Props.box(self, Vector3(2.9, 0.42, 0.25), Vector3(0, 0.45 + 0.55 * i, 0), Color("a18458")))
	Props.box(self, Vector3(3, 0.03, 0.6), Vector3(0, 0.08, 0), Color("9d8755"))
	# Uprights, braces and brackets frame the boards. They appear with the first
	# board and disappear with the last, so an unbuilt spot still reads as empty.
	for x in [-1.38, 1.38]:
		frame.append(Props.detail(Props.box(self, Vector3(0.22, 2.0, 0.34), Vector3(x, 1.0, 0), Color("6f5b3e"))))
		frame.append(Props.detail(Props.beam(self, Vector3(x, 0.1, 0.02), Vector3(x * 0.2, 1.85, 0.02), 0.14, Color("7d6746"))))
		for y in [0.45, 1.0, 1.55]:
			frame.append(Props.detail(Props.box(self, Vector3(0.1, 0.1, 0.42), Vector3(x, y, 0), Color("4b4132"))))
	label = Props.sign_text(self, "DEFESA / E", Vector3(0, 2.4, 0), 28)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	refresh()
func _physics_process(delta: float) -> void:
	if active:
		repair_left = maxf(0, repair_left - delta)
func occupied() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.0, 1.8, 0.65)
	query.shape = shape
	query.transform = Transform3D(global_basis, global_position + Vector3.UP)
	query.collision_mask = 2 | 4
	return not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
func repair(progression) -> bool:
	if not active or repair_left > 0 or integrity >= maximum or (integrity == 0 and occupied()):
		return false
	if not progression.spend(100 if integrity == 0 else 50):
		return false
	integrity = maximum if integrity == 0 else minf(maximum, integrity + 100)
	repair_left = 1
	refresh()
	return true
func take_damage(amount: float) -> void:
	if not active or amount <= 0:
		return
	integrity = maxf(0, integrity - amount)
	refresh()
func refresh() -> void:
	set_deferred("collision_layer", 8 if integrity > 0 else 0)
	for i in range(boards.size()):
		boards[i].visible = integrity > i * 100
	for part in frame:
		part.visible = integrity > 0
func prompt(_player, _progression) -> String:
	if integrity >= maximum:
		return "BARRICADA / INTEGRA"
	return "E  Construir barricada / 100" if integrity == 0 else "E  Reparar +100 / 50"
func interact(_player, progression) -> bool:
	return repair(progression)
func reset_match() -> void:
	integrity = 0
	repair_left = 0
	active = true
	refresh()
