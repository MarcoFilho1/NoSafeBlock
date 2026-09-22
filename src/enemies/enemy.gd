extends CharacterBody3D

const Health = preload("res://src/core/health.gd")
const Brain = preload("res://src/enemies/agent_brain.gd")
const Visual = preload("res://src/visuals/actor_visual.gd")
const Props = preload("res://src/world/props.gd")
const Catalog = preload("res://src/data/enemy_catalog.gd")
const Abilities = preload("res://src/enemies/enemy_abilities.gd")
const BossAbilities = preload("res://src/enemies/boss_abilities.gd")
var kind: String = "walker"
var definition: Dictionary = Catalog.get_definition("walker")
var contact_damage: float = 10
var points: int = 10
var buff_left: float = 0
var abilities: Node
var effects: Node3D
var game: Node
var is_boss: bool = false
func configure(kind_id: String, round_number: int) -> void:
	kind = kind_id
	definition = Catalog.get_definition(kind)
	is_boss = definition.boss
	var growth := 1.0 + maxf(0, round_number - 1) * (0.025 if is_boss else 0.055)
	health = Health.new(float(definition.health) * growth)
	speed = minf(4.3, float(definition.speed) + (round_number - 1) * 0.025)
	contact_damage = float(definition.damage) * (1.0 + (round_number - 1) * 0.025)
	points = 1000 + 50 * round_number if is_boss else int(definition.points)

signal eliminated(points: int)
signal cue_requested(kind: String)

var health = Health.new(68.0)
var brain = Brain.new()
var player: CharacterBody3D
var navigation: NavigationAgent3D
var visual: Node3D
var active: bool = true
var alert_time: float = 0.0
var attack_left: float = 0.0
var path_left: float = 0.0
var idle_left: float = 0.5
var speed: float = 1.8
var patrol_target: Vector3
var debug_label: Label3D
var debug_radius: MeshInstance3D
var debug_path: MeshInstance3D
var debug_enabled: bool = false

func setup(target: CharacterBody3D) -> void:
	player = target

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 2 | 4 | 8
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	visual = Visual.new()
	add_child(visual)
	visual.build(true)
	visual.scale = definition.scale
	visual.body_material.albedo_color = definition.color
	visual.set_enemy_kind(kind, definition.color)
	if kind not in ["walker", "runner"] and is_instance_valid(effects):
		abilities = BossAbilities.new() if is_boss else Abilities.new()
		abilities.owner_enemy = self
		add_child(abilities)
		var identifier := Props.sign_text(self, definition.name, Vector3(0, 3.2 if is_boss else 2.6, 0), 24)
		identifier.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		identifier.modulate = definition.color.lightened(0.3)
	navigation = NavigationAgent3D.new()
	# Keep corner acceptance below the clearance between the body and baked walls.
	navigation.path_desired_distance = 0.10
	# The baked floor is two 0.25 m voxels above the physical feet origin.
	navigation.path_height_offset = 0.5
	navigation.target_desired_distance = 0.65
	add_child(navigation)
	patrol_target = global_position
	health.died.connect(on_death)
	debug_label = Label3D.new()
	debug_label.position.y = 2.6
	debug_label.font_size = 28
	debug_label.pixel_size = 0.01
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	debug_label.no_depth_test = true
	debug_label.visible = false
	add_child(debug_label)
	var ring := TorusMesh.new()
	ring.inner_radius = Brain.DETECTION_RANGE - 0.025
	ring.outer_radius = Brain.DETECTION_RANGE
	debug_radius = MeshInstance3D.new()
	debug_radius.mesh = ring
	debug_radius.material_override = Props.material(Color("88b898"), true)
	debug_radius.position.y = 0.1
	debug_radius.visible = false
	add_child(debug_radius)
	debug_path = MeshInstance3D.new()
	add_child(debug_path)
	debug_path.top_level = true

func _physics_process(delta: float) -> void:
	if not active:
		return
	if not health.is_alive():
		visual.animate(delta, 0, false, false)
		return
	if not is_instance_valid(player) or not player.health.is_alive():
		return
	buff_left = maxf(0, buff_left - delta)
	if abilities and abilities.tick(delta):
		visual.animate(delta, velocity.length(), false, true, true)
		return
	alert_time = maxf(0.0, alert_time - delta)
	attack_left = maxf(0.0, attack_left - delta)
	path_left -= delta
	idle_left -= delta
	var distance := global_position.distance_to(player.global_position)
	if idle_left > 0:
		return
	var attack_visible := distance > Brain.ATTACK_RANGE or has_clear_attack()
	brain.decide(distance, health.is_alive(), alert_time > 0, attack_visible)
	velocity = Vector3.ZERO
	if brain.state == "ATTACK":
		face(player.global_position)
		if attack_left == 0.0:
			attack_left = 1.0
			player.take_damage(contact_damage * (1.35 if buff_left > 0 else 1.0))
			cue_requested.emit("attack")
	else:
		if path_left <= 0.0:
			path_left = 0.3
			if brain.state == "CHASE":
				navigation.target_position = player.global_position
			else:
				if global_position.distance_to(patrol_target) < 1.0:
					# Inward patrol prevents idle enemies from stranding a round at the perimeter.
					patrol_target = player.global_position
				navigation.target_position = patrol_target
		if not navigation.is_navigation_finished():
			var next := navigation.get_next_path_position()
			var closest := NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, global_position)
			if Vector2(closest.x - global_position.x, closest.z - global_position.z).length() > 0.18:
				next = closest
			var direction := next - global_position
			direction.y = 0.0
			velocity = direction.normalized() * speed * (0.6 if brain.state == "PATROL" else 1.0)
			face(global_position + direction)
	if velocity.length_squared() > 0.1:
		var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, global_position + Vector3.UP + velocity.normalized() * 1.4, 8)
		var barrier := get_world_3d().direct_space_state.intersect_ray(query)
		if not barrier.is_empty():
			velocity = Vector3.ZERO
			if attack_left <= 0:
				barrier.collider.take_damage(100 if kind == "demolisher" or is_boss else 30)
				attack_left = 1
	velocity.y = -1.0
	move_and_slide()
	visual.animate(delta, Vector2(velocity.x, velocity.z).length(), false, true, brain.state == "ATTACK")
	if debug_enabled:
		var target_name := "Patrulha" if brain.state == "PATROL" else "Player"
		var target_distance := global_position.distance_to(patrol_target) if brain.state == "PATROL" else distance
		debug_label.text = "WALKER #%d · %s\n%s · %.1f m · %.0f HP" % [get_instance_id() % 1000, brain.state, target_name, target_distance, health.current]
		update_debug_path()

func face(target: Vector3) -> void:
	var delta := target - global_position
	if Vector2(delta.x, delta.z).length() > 0.01:
		rotation.y = atan2(-delta.x, -delta.z)

func has_clear_attack() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, player.global_position + Vector3.UP, 1 | 8)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func take_damage(amount: float) -> void:
	if not active:
		return
	health.damage(amount)
	visual.hurt()
	alert_time = 8.0

func on_death() -> void:
	brain.decide(0, false, false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	debug_label.visible = false
	debug_radius.visible = false
	debug_path.visible = false
	if abilities:
		abilities.marker.visible = false
		abilities.direction_marker.visible = false
	eliminated.emit(points)
	cue_requested.emit("death")
	get_tree().create_timer(1.1).timeout.connect(queue_free)

func set_debug(value: bool) -> void:
	debug_enabled = value
	debug_label.visible = value
	debug_radius.visible = value
	debug_path.visible = value

func update_debug_path() -> void:
	var path := navigation.get_current_navigation_path()
	if path.size() < 2:
		debug_path.mesh = null
		return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, Props.material(Color("e5bc72"), true))
	for point in path:
		mesh.surface_add_vertex(point + Vector3(0, 0.18, 0))
	mesh.surface_end()
	debug_path.mesh = mesh
