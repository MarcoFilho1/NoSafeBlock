extends CharacterBody3D

const Health = preload("res://src/core/health.gd")
const Brain = preload("res://src/enemies/agent_brain.gd")
const Visual = preload("res://src/visuals/actor_visual.gd")
const Props = preload("res://src/world/props.gd")

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
	collision_layer = 4
	collision_mask = 1 | 2 | 4
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
	alert_time = maxf(0.0, alert_time - delta)
	attack_left = maxf(0.0, attack_left - delta)
	path_left -= delta
	idle_left -= delta
	var distance := global_position.distance_to(player.global_position)
	if idle_left > 0:
		return
	brain.decide(distance, health.is_alive(), alert_time > 0)
	velocity = Vector3.ZERO
	if brain.state == "ATTACK":
		face(player.global_position)
		if attack_left == 0.0 and has_clear_attack():
			attack_left = 1.0
			player.take_damage(10.0)
			cue_requested.emit("attack")
	else:
		if path_left <= 0.0:
			path_left = 0.3
			if brain.state == "CHASE":
				navigation.target_position = player.global_position
			else:
				if global_position.distance_to(patrol_target) < 1.0:
					# Inward patrol prevents idle enemies from stranding a round at the perimeter.
					patrol_target = Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
				navigation.target_position = patrol_target
		if not navigation.is_navigation_finished():
			var next := navigation.get_next_path_position()
			var direction := next - global_position
			direction.y = 0.0
			velocity = direction.normalized() * speed * (0.6 if brain.state == "PATROL" else 1.0)
			face(global_position + direction)
	velocity.y = -1.0
	move_and_slide()
	visual.animate(delta, Vector2(velocity.x, velocity.z).length(), false, true, brain.state == "ATTACK")
	if debug_enabled:
		debug_label.text = "WALKER #%d · %s\nPlayer · %.1f m · %.0f HP" % [get_instance_id() % 1000, brain.state, distance, health.current]
		update_debug_path()

func face(target: Vector3) -> void:
	var delta := target - global_position
	if Vector2(delta.x, delta.z).length() > 0.01:
		rotation.y = atan2(-delta.x, -delta.z)

func has_clear_attack() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, player.global_position + Vector3.UP, 1)
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
	eliminated.emit(10)
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
