extends Node3D
const Props = preload("res://src/world/props.gd")
const Combat = preload("res://src/combat/combat_resolver.gd")
var active: bool = true
var kind: String = "acid"
var remaining: float = 4
var damage: float = 10
var radius: float = 3
var warmup: float = 0
var pulse: float = 0
var targets_player: bool = true
var fired: bool = false
var disc: MeshInstance3D
func configure(type: String, origin: Vector3, amount: float, area: float, duration: float) -> void:
	kind = type
	position = origin
	damage = amount
	radius = area
	remaining = duration
func _ready() -> void:
	disc = Props.cylinder(self, radius, 0.035, Vector3(0, 0.10, 0), Color("bbdd65") if kind == "acid" else Color("ef7f54"))
	disc.material_override = Props.material(Color("bcdf69") if kind == "acid" else Color("fa9260"), true)
	disc.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc.material_override.albedo_color.a = 0.32
func _physics_process(delta: float) -> void:
	if not active:
		return
	if warmup > 0:
		warmup = maxf(0, warmup - delta)
		disc.scale = Vector3.ONE * (0.85 + 0.15 * sin(warmup * 18))
		return
	remaining -= delta
	pulse -= delta
	if pulse <= 0 and (kind == "acid" or not fired):
		fired = true
		pulse = 0.75
		var targets := get_tree().get_nodes_in_group("players" if targets_player else "enemies")
		Combat.blast(get_world_3d(), global_position + Vector3.UP, radius, damage, targets)
		if kind != "acid":
			remaining = minf(remaining, 0.18)
	if remaining <= 0:
		queue_free()
