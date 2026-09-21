extends Node3D

const Props = preload("res://src/world/props.gd")
var navigation_ready: bool = false
var camera: Camera3D
var region: NavigationRegion3D
var spawn_points: Array[Vector3] = [Vector3(-16, 0, 0), Vector3(16, 0, 0), Vector3(0, 0, -16), Vector3(0, 0, 16), Vector3(-16, 0, -16), Vector3(16, 0, -16), Vector3(-16, 0, 16), Vector3(16, 0, 16)]

func _ready() -> void:
	build_lighting()
	region = NavigationRegion3D.new()
	region.name = "StreetNavigation"
	add_child(region)
	Props.solid(region, Vector3(36, 0.5, 36), Vector3(0, -0.25, 0), Color("4b5857"))
	# Painted streets and sidewalks are decorative: only collision geometry is baked.
	Props.box(region, Vector3(8, 0.025, 35.8), Vector3(0, 0.014, 0), Color("354346"))
	Props.box(region, Vector3(35.8, 0.026, 8), Vector3(0, 0.015, 0), Color("354346"))
	for i in range(-8, 9):
		if absi(i) > 2:
			Props.box(region, Vector3(0.10, 0.03, 1), Vector3(0, 0.04, i * 2), Color("b9a775"))
			Props.box(region, Vector3(1, 0.03, 0.10), Vector3(i * 2, 0.04, 0), Color("b9a775"))
	for i in range(6):
		Props.box(region, Vector3(0.55, 0.04, 2.5), Vector3(-2 + i * 0.8, 0.045, 4.5), Color("919a8b"))
	for x in [-1, 1]:
		for z in [-1, 1]:
			Props.box(region, Vector3(12, 0.08, 12), Vector3(x * 11, 0.04, z * 11), Color("67716a"))
	Props.building(region, Vector3(-11, 0, -10), Vector3(7, 4.3, 7), Color("897d63"), "LAST STOP")
	Props.building(region, Vector3(11, 0, -11), Vector3(7, 3.5, 6), Color("6f7b70"), "PHARMACY")
	Props.building(region, Vector3(-12, 0, 11), Vector3(5, 2.9, 5), Color("8d705a"), "AUTO / 24")
	Props.building(region, Vector3(11.5, 0, 12), Vector3(6, 3.2, 5), Color("69777b"), "DEPOT")
	Props.car(region, Vector3(5.7, 0, -3.5), Color("a47148"))
	Props.car(region, Vector3(-3, 0, 10), Color("5d7c79"))
	Props.solid(region, Vector3(3.5, 0.8, 0.6), Vector3(-6.3, 0.4, 3.4), Color("958d6e"))
	Props.solid(region, Vector3(0.7, 1.1, 2.6), Vector3(8, 0.55, 5), Color("687957"))
	for pos in [Vector3(-16, 0, 5), Vector3(16, 0, -5), Vector3(6, 0, 16)]:
		Props.tree(region, pos)
	for point in spawn_points:
		var ring := Props.cylinder(self, 0.8, 0.025, point + Vector3(0, 0.07, 0), Color("9a6550"))
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in [-1, 1]:
		Props.solid(region, Vector3(36.5, 2, 0.3), Vector3(0, 1, i * 18), Color("374846"))
		Props.solid(region, Vector3(0.3, 2, 36.5), Vector3(i * 18, 1, 0), Color("374846"))
	var nav := NavigationMesh.new()
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = 1
	nav.agent_radius = 0.5
	nav.agent_height = 2.0
	nav.agent_max_climb = 0.25
	nav.cell_size = 0.25
	nav.cell_height = 0.25
	region.navigation_mesh = nav
	region.bake_navigation_mesh(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	navigation_ready = true

func build_lighting() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("182729")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a4c6c4")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("ffe1a4")
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 85
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 40
	camera.position = Vector3(28, 34, 28)
	camera.far = 140
	add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
