extends RefCounted
static func clear_line(world: World3D, origin: Vector3, target: Vector3) -> bool:
	return world.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, target, 1 | 8)).is_empty()

static func blast(world: World3D, center: Vector3, radius: float, damage: float, targets: Array) -> void:
	for target in targets.duplicate():
		if not is_instance_valid(target) or not target.has_method("take_damage"):
			continue
		var endpoint: Vector3 = target.global_position + Vector3.UP
		if center.distance_to(endpoint) <= radius and clear_line(world, center, endpoint):
			target.take_damage(damage)

static func fire(player: CharacterBody3D, target: Vector3) -> void:
	var data: Dictionary = player.weapon.definition
	var damage: float = data.damage * (1.0 + 0.2 * int(player.progression.weapon_levels.get(player.weapon.id, 0)))
	var origin: Vector3 = player.visual.muzzle.global_position
	var body: Vector3 = player.global_position + Vector3.UP
	var space := player.get_world_3d().direct_space_state
	var barrel: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(body, origin, 1 | 8))
	var base := (target - origin).normalized()
	base.y = 0
	if base.length_squared() < 0.001:
		base = -player.global_basis.z
	base = base.normalized()
	for pellet in range(int(data.pellets)):
		var spread: float = data.spread
		if player.focused:
			spread *= 0.65 if int(data.pellets) > 1 else 0.0
		var direction := base.rotated(Vector3.UP, randf_range(-spread, spread))
		var end: Vector3 = origin + direction * float(data.range)
		var hit: Dictionary = barrel
		if barrel.is_empty():
			var query := PhysicsRayQueryParameters3D.create(origin, end, 1 | 4 | 8)
			query.exclude = [player.get_rid()]
			hit = space.intersect_ray(query)
		else:
			origin = body
		if not hit.is_empty():
			end = hit.position
			if hit.collider.has_method("take_damage"):
				hit.collider.take_damage(damage)
			if data.mode == "plasma":
				blast(player.get_world_3d(), end - direction * 0.15, 3.0, damage * 0.7, player.get_tree().get_nodes_in_group("enemies"))
			elif data.mode == "arc" and hit.collider.is_in_group("enemies"):
				var visited: Array = [hit.collider]
				var chain_origin: Vector3 = hit.collider.global_position + Vector3.UP
				for hop in range(2):
					var nearest: Node3D = null
					var nearest_distance: float = 5.0
					for enemy in player.get_tree().get_nodes_in_group("enemies"):
						if visited.has(enemy) or not enemy.health.is_alive():
							continue
						var distance: float = chain_origin.distance_to(enemy.global_position + Vector3.UP)
						if distance < nearest_distance and clear_line(player.get_world_3d(), chain_origin, enemy.global_position + Vector3.UP):
							nearest = enemy
							nearest_distance = distance
					if not nearest:
						break
					visited.append(nearest)
					player.draw_tracer(chain_origin, nearest.global_position + Vector3.UP)
					chain_origin = nearest.global_position + Vector3.UP
					nearest.take_damage(damage * pow(0.7, hop + 1))
		player.draw_tracer(origin, end)
