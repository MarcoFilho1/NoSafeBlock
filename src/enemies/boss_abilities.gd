extends "res://src/enemies/enemy_abilities.gd"
var attack_index: int = 0
var summoned: Array = []
var summon_cooldown: float = 0
func tick(delta: float) -> bool:
	summon_cooldown -= delta
	if phase != "IDLE":
		return super.tick(delta)
	cooldown -= delta * (1.25 if owner_enemy.kind == "aberration" and owner_enemy.health.current <= owner_enemy.health.maximum * 0.5 else 1.0)
	if cooldown <= 0 and owner_enemy.global_position.distance_to(owner_enemy.player.global_position) < 22:
		telegraph(1.2)
	return false
func execute() -> void:
	phase = "RECOVER"
	phase_left = 1.5
	cooldown = 4
	attack_index += 1
	match owner_enemy.kind:
		"executioner":
			if attack_index % 2:
				phase = "CHARGE"
				phase_left = 0.7
				charge_hit = false
			else:
				area(owner_enemy.global_position, 5, 40, 0.4)
		"matriarch":
			for offset in [Vector3(-2, 0, 0), Vector3.ZERO, Vector3(2, 0, 0)]:
				spit(locked_target + offset)
			if summon_cooldown <= 0:
				summon_cooldown = 12
				summoned = summoned.filter(func(e): return is_instance_valid(e) and e.health.is_alive())
				for i in range(mini(4, 8 - summoned.size())):
					var child = owner_enemy.game.summon_enemy(owner_enemy.global_position + Vector3(cos(i * PI / 2), 0, sin(i * PI / 2)) * 3)
					if child:
						summoned.append(child)
		"aberration":
			if attack_index % 2:
				# Beam follows the locked direction, so lateral movement evades it.
				for i in range(1, 12):
					var point: Vector3 = owner_enemy.global_position + heading * i * 1.5
					if not Combat.clear_line(owner_enemy.get_world_3d(), owner_enemy.global_position + Vector3.UP, point + Vector3.UP):
						break
					area(point, 1.1, 38, 0)
			else:
				for offset in [Vector3(-3, 0, 0), Vector3.ZERO, Vector3(3, 0, 0)]:
					area(locked_target + offset, 2.4, 38, 1.2)
