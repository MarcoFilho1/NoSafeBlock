extends Node3D

const Props = preload("res://src/world/props.gd")
const Layout = preload("res://src/world/city_layout.gd")
const Buildings = preload("res://src/world/city_buildings.gd")
const Station = preload("res://src/world/interaction_station.gd")
const Barricade = preload("res://src/world/barricade.gd")
const Weapons = preload("res://src/data/weapon_catalog.gd")
var layout: Dictionary = Layout.definition()
var follow_target: Node3D
var city_buildings: Array[Node3D] = []
var faded: Array[Node3D] = []
var interactables: Array[Node3D] = []
var discovered: Array = []
var navigation_ready: bool = false
var camera: Camera3D
var region: NavigationRegion3D
var spawn_points: Array[Vector3] = [Vector3(-16, 0, 0), Vector3(16, 0, 0), Vector3(0, 0, -16), Vector3(0, 0, 16), Vector3(-16, 0, -16), Vector3(16, 0, -16), Vector3(-16, 0, 16), Vector3(16, 0, 16)]

func _ready() -> void:
	build_lighting()
	region = NavigationRegion3D.new()
	NavigationServer3D.region_set_use_async_iterations(region.get_rid(), false)
	NavigationServer3D.map_set_use_async_iterations(get_world_3d().navigation_map, false)
	region.name = "StreetNavigation"
	add_child(region)
	Props.solid(region, Vector3(180, 0.5, 180), Vector3(0, -0.25, 0), Color("343b38"))
	build_city()
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
		Props.solid(region, Vector3(180.5, 3, 0.3), Vector3(0, 1.5, i * 90), Color("374846"))
		Props.solid(region, Vector3(0.3, 3, 180.5), Vector3(i * 90, 1.5, 0), Color("374846"))
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
	NavigationServer3D.map_force_update(get_world_3d().navigation_map)
	navigation_ready = true
	build_interactions()

func build_lighting() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("182729")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9baab9")
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("d6b295")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 85
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 30
	camera.position = Vector3(28, 34, 28)
	camera.far = 140
	add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true

func build_city() -> void:
	spawn_points.assign(layout.spawn_points)
	for lane in [-60, -30, 0, 30, 60]:
		Props.box(region, Vector3(8, 0.025, 180), Vector3(lane, 0.012, 0), Color("303b3c"))
		Props.box(region, Vector3(180, 0.025, 8), Vector3(0, 0.013, lane), Color("303b3c"))
		for stripe in range(-85, 86, 5):
			Props.box(region, Vector3(0.13, 0.03, 1.8), Vector3(lane, 0.035, stripe), Color("a99868"))
			Props.box(region, Vector3(1.8, 0.03, 0.13), Vector3(stripe, 0.036, lane), Color("a99868"))
	for data in layout.buildings:
		city_buildings.append(Buildings.build(region, data))
	for i in range(18):
		var pos := Vector3(-78 + i % 6 * 30, 0, -60 + i / 6 * 60)
		if absf(pos.x) < 20 and absf(pos.z) < 20:
			continue
		Props.car(region, pos, Color("755747") if i % 2 else Color("4d6964"))
		Props.tree(region, pos + Vector3(3, 0, 5))
	for district in layout.districts:
		var sign := Props.sign_text(self, district.name, district.position + Vector3(0, 5, 0), 64)
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Burned bus and abandoned fuel station are navigable city landmarks.
	var bus := Props.solid(region, Vector3(2.6, 2.3, 8), Vector3(2, 1.15, 48), Color("55493d"))
	for side in [-1, 1]:
		for window in range(5):
			Props.box(bus, Vector3(0.06, 0.75, 0.85), Vector3(side * 1.32, 0.5, -2.6 + window * 1.2), Color("1c292b"))
	Props.box(region, Vector3(8, 0.4, 10), Vector3(54, 4, 15), Color("706657"))
	for z in [12, 18]:
		Props.solid(region, Vector3(0.8, 1.7, 0.8), Vector3(54, 0.85, z), Color("9d7655"))
		Props.box(region, Vector3(0.1, 0.5, 0.5), Vector3(54.45, 1.1, z), Color("27383b"))
	Props.sign_text(region, "SUNSET / FUEL", Vector3(54, 4.2, 20), 48)
	# Painted damage does not add navigation obstacles or draw-time shadows.
	for i in range(85):
		var x: float = -83 + (i * 17 % 166)
		var z: float = -83 + (i * 29 % 166)
		var stain := Props.cylinder(region, 0.5 + (i % 4) * 0.25, 0.015, Vector3(x, 0.06, z), Color("422d2a") if i % 3 == 0 else Color("252d2b"))
		stain.scale.z = 0.5
		stain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var crack := Props.box(region, Vector3(0.08, 0.02, 3.2), Vector3(x + 1, 0.07, z), Color("202626"))
		crack.rotation.y = i * 0.73
		crack.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(delta: float) -> void:
	if not is_instance_valid(follow_target):
		return
	camera.position = camera.position.lerp(follow_target.global_position + Vector3(22, 28, 22), 1.0 - exp(-8.0 * delta))
	var next_faded: Array[Node3D] = []
	for building in city_buildings:
		var p: Vector3 = follow_target.global_position - building.global_position
		# Camera looks from +X,+Z: fade occupied buildings and foreground occluders.
		var obscure: bool = absf(p.x) < 12 and absf(p.z) < 12
		obscure = obscure or (p.x < 0 and p.z < 0 and absf(p.x - p.z) < 12 and p.length() < 30)
		if obscure:
			next_faded.append(building)
			if not faded.has(building):
				Buildings.set_occluded(building, true)
	for building in faded:
		if not next_faded.has(building):
			Buildings.set_occluded(building, false)
	faded = next_faded
	for node in interactables:
		if node is StaticBody3D:
			node.label.visible = node.position.distance_to(follow_target.position) < 13
		elif node.sign:
			node.sign.visible = node.position.distance_to(follow_target.position) < 15

func reset_match() -> void:
	discovered.clear()
	for node in interactables:
		if node.has_method("reset_match"):
			node.reset_match()

func build_interactions() -> void:
	var positions := [Vector3(3, 0, -3), Vector3(-4, 0, -22), Vector3(-28, 0, -5), Vector3(5, 0, 25), Vector3(32, 0, 5), Vector3(-58, 0, -5), Vector3(-32, 0, 55), Vector3(58, 0, -30), Vector3(30, 0, -62)]
	for i in range(Weapons.IDS.size()):
		var id: String = Weapons.IDS[i]
		add_station(positions[i], {"kind": "weapon", "id": id, "title": Weapons.get_definition(id).name})
	for pos in [Vector3(-3, 0, 3), Vector3(-30, 0, -30), Vector3(30, 0, 30), Vector3(60, 0, -60), Vector3(-60, 0, 60)]:
		add_station(pos, {"kind": "ammo", "title": "MUNICAO / arma atual"})
	for row in [["health", "VITALIDADE", Vector3(-5, 0, -30)], ["resistance", "PELE DE FERRO", Vector3(30, 0, -5)], ["reload", "MAOS LIGEIRAS", Vector3(-30, 0, 5)], ["movement", "FOLEGO", Vector3(5, 0, 30)]]:
		add_station(row[2], {"kind": "upgrade", "id": row[0], "title": row[1]})
	add_station(Vector3(5, 0, -60), {"kind": "damage", "title": "AMPLIFICADOR / dano +20%"})
	for pos in [Vector3(5, 0, 7), Vector3(-60, 0, -30), Vector3(60, 0, 30)]:
		add_station(pos, {"kind": "medkit", "title": "KIT MEDICO", "price": 250})
		add_station(pos + Vector3(0, 0, 3), {"kind": "armor", "title": "COLETE / 50 protecao", "price": 400})
		add_station(pos + Vector3(0, 0, 6), {"kind": "grenade", "title": "GRANADA", "price": 200})
	for building in layout.buildings:
		if building.enterable:
			for entrance in building.entrances:
				var barrier := Barricade.new()
				barrier.position = entrance
				add_child(barrier)
				interactables.append(barrier)
	# A marked starting defensive position with a route around both sides.
	var first := Barricade.new()
	first.position = Vector3(-5, 0, 4)
	add_child(first)
	interactables.append(first)

func add_station(pos: Vector3, offer: Dictionary) -> void:
	var station := Station.new()
	station.position = pos
	station.offer = offer
	add_child(station)
	interactables.append(station)
	layout.stations.append({"position": pos, "title": offer.title})
