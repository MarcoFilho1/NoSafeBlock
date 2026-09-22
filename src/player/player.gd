extends CharacterBody3D

const Health = preload("res://src/core/health.gd")
const Weapon = preload("res://src/player/weapon.gd")
const Visual = preload("res://src/visuals/actor_visual.gd")
const Props = preload("res://src/world/props.gd")

signal shot_fired(origin: Vector3)
signal cue_requested(kind: String)
signal died

var health = Health.new(100.0)
var weapon = Weapon.new()
var visual: Node3D
var camera: Camera3D
var active: bool = true
var focused: bool = false
var aim_point: Vector3 = Vector3(0, 1, -5)
var invulnerability: float = 0.0
var mouse_armed: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	visual = Visual.new()
	add_child(visual)
	visual.build(false)
	health.died.connect(func(): active = false; died.emit())

func _physics_process(delta: float) -> void:
	if not health.is_alive():
		visual.animate(delta, 0, false, false)
		return
	if not active:
		return
	weapon.tick(delta)
	invulnerability = maxf(0, invulnerability - delta)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		mouse_armed = true
	focused = mouse_armed and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x + input.y, 0, input.y - input.x).normalized()
	var speed := 3.0 if focused else 5.3
	velocity = direction * speed
	velocity.y = -1.0
	move_and_slide()
	update_aim()
	if Input.is_action_just_pressed("reload") and weapon.reload():
		cue_requested.emit("reload")
	if mouse_armed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		shoot_at(aim_point)
	visual.animate(delta, Vector2(velocity.x, velocity.z).length(), focused, true, false, weapon.reloading)

func update_aim() -> void:
	if not camera:
		return
	var mouse := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse)
	var ray_direction := camera.project_ray_normal(mouse)
	# Ground-plane raycast: targets are lifted to weapon height after intersection.
	var ground_hit: Variant = Plane(Vector3.UP, 0).intersects_ray(ray_origin, ray_direction)
	if ground_hit != null:
		aim_point = ground_hit + Vector3(0, 1.0, 0)
		var direction: Vector3 = aim_point - global_position
		if Vector2(direction.x, direction.z).length() > 0.1:
			rotation.y = atan2(-direction.x, -direction.z)

func shoot_at(target: Vector3) -> bool:
	if not active or not health.is_alive() or not weapon.fire():
		return false
	var facing := target - global_position
	if Vector2(facing.x, facing.z).length() > 0.1:
		rotation.y = atan2(-facing.x, -facing.z)
	visual.animate(0.0, 0.0, focused, true)
	var body_origin := global_position + Vector3(0, 1.0, 0)
	var origin: Vector3 = visual.muzzle.global_position
	var direction := (target - origin).normalized()
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = -global_basis.z
	direction = direction.normalized().rotated(Vector3.UP, randf_range(-0.065, 0.065) if not focused else 0.0)
	var end := origin + direction * 45.0
	# The barrel must not bypass a wall when it visually extends beyond the body.
	var barrel_query := PhysicsRayQueryParameters3D.create(body_origin, origin, 1)
	var barrel_hit := get_world_3d().direct_space_state.intersect_ray(barrel_query)
	if not barrel_hit.is_empty():
		origin = body_origin
		end = barrel_hit.position
	var query := PhysicsRayQueryParameters3D.create(origin, end, 1 | 4)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query) if barrel_hit.is_empty() else barrel_hit
	if not hit.is_empty():
		end = hit.position
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(Weapon.DAMAGE)
	draw_tracer(origin, end)
	visual.shot()
	shot_fired.emit(global_position)
	cue_requested.emit("shot")
	return true

func draw_tracer(origin: Vector3, end: Vector3) -> void:
	var tracer := MeshInstance3D.new()
	tracer.name = "ShotTracer"
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, Props.material(Color("ffe2a0"), true))
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(end - origin)
	mesh.surface_end()
	tracer.mesh = mesh
	get_parent().add_child(tracer)
	tracer.global_position = origin
	get_tree().create_timer(0.07).timeout.connect(tracer.queue_free)

func take_damage(amount: float) -> void:
	if not active or invulnerability > 0 or not health.is_alive():
		return
	invulnerability = 0.35
	health.damage(amount)
	visual.hurt()
	cue_requested.emit("hurt")
