extends Node3D
const Props = preload("res://src/world/props.gd")
const Hazard = preload("res://src/combat/hazard.gd")
var active: bool = true
var direction: Vector3
var speed: float
var damage: float
var remaining: float
func launch(origin: Vector3, heading: Vector3, velocity: float, amount: float, lifetime: float) -> void:
	position = origin
	direction = heading.normalized()
	speed = velocity
	damage = amount
	remaining = lifetime
func _ready() -> void:
	Props.cylinder(self, 0.2, 0.3, Vector3.ZERO, Color("c4ed6c"))
func _physics_process(delta: float) -> void:
	if not active:
		return
	var next := global_position + direction * speed * delta
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position, next, 1 | 2 | 8))
	remaining -= delta
	if not hit.is_empty():
		global_position = hit.position - direction * 0.15
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(damage)
	if not hit.is_empty() or remaining <= 0:
		var acid := Hazard.new()
		acid.configure("acid", Vector3(global_position.x, 0, global_position.z), damage * 0.45, 2.3, 4)
		# Damage can synchronously end the match before the impact leaves acid behind.
		acid.active = bool(get_parent().get_meta("effects_active", true))
		get_parent().add_child(acid)
		queue_free()
	else:
		global_position = next
