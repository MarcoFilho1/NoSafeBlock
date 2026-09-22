extends Node3D
const Props = preload("res://src/world/props.gd")
const Weapons = preload("res://src/data/weapon_catalog.gd")
const Upgrades = preload("res://src/data/upgrade_catalog.gd")
var offer: Dictionary = {}
var sign: Label3D
func _ready() -> void:
	var color := Color("6fc6b8") if offer.kind == "weapon" else Color("e6ac60")
	Props.box(self, Vector3(1.1, 1.7, 0.65), Vector3(0, 0.85, 0), Color("263c3d"))
	Props.box(self, Vector3(0.88, 0.6, 0.1), Vector3(0, 1.2, 0.38), color)
	Props.cylinder(self, 1.0, 0.035, Vector3(0, 0.09, 0), color.darkened(0.3))
	sign = Props.sign_text(self, offer.title, Vector3(0, 2.5, 0), 42)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.modulate = color
func price(player, progression) -> int:
	match offer.kind:
		"weapon": return int(Weapons.get_definition(offer.id).price)
		"upgrade": return progression.upgrade_cost(offer.id)
		"damage": return 1500 * (int(progression.weapon_levels.get(player.weapon.id, 0)) + 1)
		"ammo": return maxi(100, int(player.weapon.definition.price) / 5)
	return int(offer.get("price", 0))
func eligible(player, progression) -> bool:
	if not player.active or not player.health.is_alive():
		return false
	match offer.kind:
		"weapon": return not Weapons.get_definition(offer.id).is_empty() and not player.loadout.owns(offer.id)
		"upgrade": return progression.upgrade_cost(offer.id) >= 0
		"damage": return int(progression.weapon_levels.get(player.weapon.id, 0)) < 2
		"ammo": return player.weapon.reserve >= 0 and player.weapon.reserve < int(player.weapon.definition.reserve)
		"medkit": return player.health.current < player.health.maximum
		"armor": return player.armor < 50
		"grenade": return player.grenades < 3
	return false
func prompt(player, progression) -> String:
	var text: String = "E  " + offer.title
	if not eligible(player, progression):
		return text + " / MAXIMO ou ja adquirido"
	text += " / %d pontos" % price(player, progression)
	if offer.kind == "weapon" and player.loadout.slots[1] != null:
		text += " / substitui " + player.weapon.definition.name
	if offer.kind == "upgrade":
		var level: int = progression.levels.get(offer.id, 0)
		var values: Array = Upgrades.get_definition(offer.id)["values"]
		text += " / nivel %d > %d (%.2f)" % [level, level + 1, values[level + 1]]
	if progression.balance < price(player, progression):
		text += " / SALDO INSUFICIENTE"
	return text
func interact(player, progression) -> bool:
	if not eligible(player, progression):
		return false
	if offer.kind == "upgrade":
		var bought: bool = progression.buy_upgrade(offer.id)
		if bought:
			player.apply_upgrades()
		return bought
	if offer.kind == "damage":
		return progression.buy_weapon_upgrade(player.weapon.id)
	if not progression.spend(price(player, progression)):
		return false
	match offer.kind:
		"weapon": player.loadout.equip(offer.id)
		"ammo": player.weapon.refill()
		"medkit": player.health.heal(50)
		"armor": player.armor = 50
		"grenade": player.grenades += 1
	return true
