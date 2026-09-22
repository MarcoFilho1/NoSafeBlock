extends Node
const Props = preload("res://src/world/props.gd")
const Hazard = preload("res://src/combat/hazard.gd")
const Projectile = preload("res://src/combat/projectile.gd")
const Combat = preload("res://src/combat/combat_resolver.gd")
var owner_enemy: CharacterBody3D
var phase: String = "IDLE"
var phase_left: float = 0
var cooldown: float = 3
var locked_target: Vector3
var heading: Vector3
var marker: MeshInstance3D
var direction_marker: MeshInstance3D
var charge_hit: bool = false
func _ready() -> void:
	marker = Props.cylinder(owner_enemy, 1.0, 0.03, Vector3(0, 0.08, 0), Color("ed7850"))
	marker.visible = false
	direction_marker = Props.box(owner_enemy, Vector3(0.6, 0.025, 16), Vector3(0, 0.08, -8), Color("ef9b68"))
	direction_marker.material_override = Props.material(Color("ef9b68"), true)
	direction_marker.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	direction_marker.material_override.albedo_color.a = 0.25
	direction_marker.visible = false
func telegraph(duration: float) -> void:
	phase = "WINDUP"
	phase_left = duration
	locked_target = owner_enemy.player.global_position
	heading = (locked_target - owner_enemy.global_position).normalized()
	heading.y = 0
	marker.visible = true
	direction_marker.visible = owner_enemy.kind in ["demolisher", "executioner", "aberration"]
	owner_enemy.face(locked_target)
func tick(delta: float) -> bool:
	if not owner_enemy.active or not owner_enemy.health.is_alive():
		marker.visible = false
		direction_marker.visible = false
		return false
	cooldown -= delta
	phase_left -= delta
	if phase == "CHARGE":
		owner_enemy.velocity = heading * 12
		owner_enemy.move_and_slide()
		for i in range(owner_enemy.get_slide_collision_count()):
			var collider = owner_enemy.get_slide_collision(i).get_collider()
			if collider.has_method("take_damage") and not charge_hit:
				collider.take_damage(120 if collider.is_in_group("barricades") else owner_enemy.contact_damage * 1.5)
				charge_hit = true
			phase_left = 0
		if phase_left <= 0:
			phase = "RECOVER"
			phase_left = 1.2
		return true
	if phase == "RECOVER":
		if phase_left <= 0:
			phase = "IDLE"
		return true
	if phase == "WINDUP":
		marker.scale = Vector3.ONE * (1.0 + 0.18 * sin(phase_left * 20))
		if phase_left <= 0:
			marker.visible = false
			direction_marker.visible = false
			execute()
		return true
	var distance: float = owner_enemy.global_position.distance_to(owner_enemy.player.global_position)
	if cooldown <= 0 and owner_enemy.has_clear_attack():
		match owner_enemy.kind:
			"spitter":
				if distance < 16: telegraph(0.8)
			"demolisher":
				if distance > 3 and distance < 13: telegraph(1.0)
			"screamer":
				if distance < 15: telegraph(1.0)
			"volatile":
				if distance < 3.5: telegraph(1.2)
	return false
func execute() -> void:
	cooldown = 5
	phase = "IDLE"
	match owner_enemy.kind:
		"spitter": spit(locked_target)
		"demolisher":
			phase = "CHARGE"
			phase_left = 0.7
			charge_hit = false
		"screamer":
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if enemy.global_position.distance_to(owner_enemy.global_position) < 8:
					enemy.buff_left = 4
		"volatile":
			area(owner_enemy.global_position, 3, 45, 0)
			owner_enemy.take_damage(owner_enemy.health.maximum * 2)
func spit(target: Vector3) -> void:
	var projectile := Projectile.new()
	var origin: Vector3 = owner_enemy.global_position + Vector3.UP
	projectile.launch(origin, target + Vector3.UP - origin, 11, owner_enemy.contact_damage, 1.5)
	owner_enemy.effects.add_child(projectile)
func area(pos: Vector3, radius: float, damage: float, warning: float, kind: String = "blast") -> void:
	var hazard := Hazard.new()
	hazard.configure(kind, Vector3(pos.x, 0, pos.z), damage, radius, 4 if kind == "acid" else 0.2)
	hazard.warmup = warning
	owner_enemy.effects.add_child(hazard)
