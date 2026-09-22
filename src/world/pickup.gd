extends Node3D
const Props = preload("res://src/world/props.gd")
var kind: String = "ammo"
var remaining: float = 20
var active: bool = true
var collected: bool = false
func _ready() -> void:
	var tint := Color("7cc9b6") if kind == "ammo" else Color("d79079")
	Props.box(self, Vector3(0.6, 0.4, 0.6), Vector3(0, 0.3, 0), tint)
	# A lid, corner brackets and a marker ring read as a crate, not a cube.
	Props.detail(Props.box(self, Vector3(0.66, 0.08, 0.66), Vector3(0, 0.52, 0), tint.darkened(0.3)))
	for x in [-0.29, 0.29]:
		for z in [-0.29, 0.29]:
			Props.detail(Props.box(self, Vector3(0.08, 0.42, 0.08), Vector3(x, 0.3, z), tint.darkened(0.45)))
	Props.detail(Props.ring(self, 0.44, 0.52, Vector3(0, 0.05, 0), tint, 14))
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
