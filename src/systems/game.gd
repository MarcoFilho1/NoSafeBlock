extends Node3D
## Owns match lifetime. Every restart creates fresh actors and rule objects.

const World = preload("res://src/world/world.gd")
const Player = preload("res://src/player/player.gd")
const Enemy = preload("res://src/enemies/enemy.gd")
const Waves = preload("res://src/systems/wave_director.gd")
const HUD = preload("res://src/ui/hud.gd")
const Sound = preload("res://src/systems/audio.gd")
const Progression = preload("res://src/systems/progression.gd")
const Interactions = preload("res://src/systems/interactions.gd")
const Pickup = preload("res://src/world/pickup.gd")
var progression = Progression.new()
var effects: Node3D
var interaction: Node3D
var feedback: String = ""
var feedback_left: float = 0

var world: Node3D
var player: CharacterBody3D
var actors: Node3D
var enemies: Array[CharacterBody3D] = []
var waves = Waves.new()
var hud: CanvasLayer
var audio: Node
var state: String = "MENU"
var score: int = 0
var elapsed: float = 0.0
var spawn_left: float = 0.0
var intermission: float = 2.5
var debug_enabled: bool = false

func _ready() -> void:
	configure_input()
	world = World.new()
	add_child(world)
	actors = Node3D.new()
	actors.name = "MatchActors"
	add_child(actors)
	audio = Sound.new()
	add_child(audio)
	hud = HUD.new()
	add_child(hud)
	hud.play_requested.connect(start_game)
	hud.menu_requested.connect(show_menu)
	hud.resume_requested.connect(func(): set_paused(false))
	hud.quit_requested.connect(func(): get_tree().quit())
	hud.mute_requested.connect(toggle_mute)
	hud.show_screen("MENU", 0, 0)

func configure_input() -> void:
	var bindings := {"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "reload": KEY_R}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = bindings[action]
			InputMap.action_add_event(action, event)

func clear_match() -> void:
	for child in actors.get_children():
		actors.remove_child(child)
		child.queue_free()
	enemies.clear()
	player = null
	interaction = null

func start_game() -> void:
	if not world.navigation_ready:
		return
	clear_match()
	waves = Waves.new()
	waves.start_next()
	score = 0
	progression = Progression.new()
	feedback = ""
	elapsed = 0.0
	spawn_left = 0.0
	intermission = 2.5
	state = "PLAYING"
	player = Player.new()
	player.progression = progression
	effects = Node3D.new()
	effects.name = "Effects"
	effects.set_meta("effects_active", true)
	actors.add_child(effects)
	player.effects = effects
	player.camera = world.camera
	actors.add_child(player)
	world.follow_target = player
	world.reset_match()
	player.died.connect(on_player_died)
	player.shot_fired.connect(alert_agents)
	player.cue_requested.connect(audio.play_cue)
	hud.show_screen(state, score, waves.round_number)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _physics_process(delta: float) -> void:
	if state != "PLAYING":
		return
	elapsed += delta
	feedback_left = maxf(0, feedback_left - delta)
	interaction = Interactions.nearest(player.global_position, world.interactables)
	for node in world.interactables:
		if node.global_position.distance_to(player.global_position) < 15 and not world.discovered.has(node):
			world.discovered.append(node)
	if intermission > 0:
		intermission = maxf(0.0, intermission - delta)
		return
	spawn_left -= delta
	if (waves.pending > 0 or waves.boss_pending) and spawn_left <= 0:
		try_spawn()
		spawn_left = waves.spawn_interval()
	if waves.is_clear():
		progression.award(100 + 25 * waves.round_number)
		score = progression.earned
		waves.start_next()
		intermission = 4.0
		audio.play_cue("wave")

func _process(_delta: float) -> void:
	if hud:
		hud.update_game(self)

func try_spawn() -> void:
	if not is_instance_valid(player) or waves.alive >= Waves.MAX_ACTIVE or (waves.pending <= 0 and not waves.boss_pending):
		return
	# Reserve free, navigable space even when several enemies spawn on the same edge.
	var candidates: Array[Vector3] = []
	var nav_map := world.get_world_3d().navigation_map
	for base in world.spawn_points:
		if base.distance_to(player.global_position) < 14 or base.distance_to(player.global_position) > 32:
			continue
		for offset in [Vector3.ZERO, Vector3(1.3, 0, 0), Vector3(-1.3, 0, 0), Vector3(0, 0, 1.3), Vector3(0, 0, -1.3)]:
			var candidate := NavigationServer3D.map_get_closest_point(nav_map, base + offset)
			candidate.y = 0.0
			if candidate.distance_to(player.global_position) < 14:
				continue
			var occupied := false
			for enemy in enemies:
				if candidate.distance_to(enemy.global_position) < 1.0:
					occupied = true
					break
			if not occupied and spawn_position_clear(candidate):
				candidates.append(candidate)
	var point: Variant = waves.choose_spawn(candidates, player.global_position)
	if point == null:
		return
	if waves.boss_pending:
		if waves.register_boss_spawn():
			spawn_enemy(point, waves.boss_kind())
	elif waves.register_spawn():
		spawn_enemy(point, waves.enemy_kind(randf()))

func spawn_enemy(point: Vector3, kind: String = "walker") -> CharacterBody3D:
	var enemy := Enemy.new()
	enemy.position = point
	enemy.setup(player)
	enemy.configure(kind, waves.round_number)
	enemy.game = self
	enemy.effects = effects
	enemy.alert_time = 60
	actors.add_child(enemy)
	enemies.append(enemy)
	enemy.set_debug(debug_enabled)
	enemy.eliminated.connect(func(points: int): on_enemy_eliminated(enemy, points))
	enemy.cue_requested.connect(audio.play_cue)
	return enemy

func summon_enemy(point: Vector3) -> CharacterBody3D:
	if state != "PLAYING" or waves.alive >= Waves.MAX_ACTIVE:
		return null
	var candidate := NavigationServer3D.map_get_closest_point(world.get_world_3d().navigation_map, point)
	candidate.y = 0
	if candidate.distance_to(player.global_position) < 4:
		return null
	if not spawn_position_clear(candidate):
		return null
	for enemy in enemies:
		if candidate.distance_to(enemy.global_position) < 1.3:
			return null
	if not waves.register_summon():
		return null
	return spawn_enemy(candidate, "runner")

func spawn_position_clear(point: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, point + Vector3(0, 0.95, 0))
	query.collision_mask = 1 | 2 | 4 | 8
	return world.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func on_enemy_eliminated(enemy: CharacterBody3D, points: int) -> void:
	if state != "PLAYING" or not enemies.has(enemy):
		return
	enemies.erase(enemy)
	waves.register_kill()
	score += points
	progression.award(points)
	score = progression.earned
	var roll := randf()
	if roll < 0.13:
		var drop := Pickup.new()
		drop.kind = "ammo" if roll < 0.08 else "health"
		drop.position = enemy.global_position
		effects.add_child(drop)

func alert_agents(origin: Vector3) -> void:
	for enemy in enemies:
		if enemy.global_position.distance_to(origin) <= 24.0:
			enemy.alert_time = 8.0

func on_player_died() -> void:
	state = "OVER"
	set_effects_active(false)
	for enemy in enemies:
		enemy.active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_screen(state, score, waves.round_number)
	audio.play_cue("over")

func set_paused(value: bool) -> void:
	if (value and state != "PLAYING") or (not value and state != "PAUSED"):
		return
	state = "PAUSED" if value else "PLAYING"
	set_effects_active(not value)
	player.active = not value
	player.focused = false
	player.mouse_armed = false
	for enemy in enemies:
		enemy.active = not value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_HIDDEN
	hud.show_screen(state, score, waves.round_number)

func show_menu() -> void:
	state = "MENU"
	clear_match()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_screen(state, score, waves.round_number)

func toggle_mute() -> void:
	audio.set_muted(not audio.muted)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E:
				if state == "PLAYING" and is_instance_valid(interaction):
					var ok: bool = interaction.interact(player, progression)
					feedback = "ADQUIRIDO / DEFESA ATUALIZADA" if ok else "INDISPONIVEL / verifique saldo e espaco"
					feedback_left = 1.4
					if ok:
						audio.play_cue("reload")
			KEY_ESCAPE:
				set_paused(state == "PLAYING")
			KEY_F1:
				debug_enabled = not debug_enabled
				for enemy in enemies:
					enemy.set_debug(debug_enabled)
			KEY_M:
				toggle_mute()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "PLAYING":
		set_paused(true)

func set_effects_active(value: bool) -> void:
	if is_instance_valid(effects):
		effects.set_meta("effects_active", value)
		for effect in effects.get_children():
			effect.active = value
	for node in world.interactables:
		if node is StaticBody3D:
			node.active = value
