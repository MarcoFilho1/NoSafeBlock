extends Node3D
const Props = preload("res://src/world/props.gd")
var kind: String = "ammo"
var remaining: float = 20
var active: bool = true
var collected: bool = false
func _ready() -> void:
	Props.box(self, Vector3(0.6, 0.4, 0.6), Vector3(0, 0.3, 0), Color("7cc9b6") if kind == "ammo" else Color("d79079"))
	var sign := Props.sign_text(self, "MUNICAO" if kind == "ammo" else "+ VIDA", Vector3(0, 1.1, 0), 24)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
func collect(player: CharacterBody3D) -> bool:
	if not active or collected or not player.active or not player.health.is_alive():
		return false
	if kind == "ammo":
		if not player.weapon.refill():
			return false
	else:
		if player.health.current >= player.health.maximum:
			return false
		player.health.heal(25)
	collected = true
	queue_free()
	return true
func _physics_process(delta: float) -> void:
	if not active:
		return
	remaining -= delta
	if remaining <= 0:
		queue_free()
		return
	for player in get_tree().get_nodes_in_group("players"):
		if global_position.distance_to(player.global_position) < 1.5:
			collect(player)
