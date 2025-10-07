extends Node2D

var powerups = {
	"common": [
		{"name": "Speed Boost", "desc": "Move 10% faster"},
		{"name": "Extra Health", "desc": "+20 HP"},
		{"name": "Range", "desc": "More attack Range"},
		{"name": "Extra Dmg", "desc": "+2 Damage per hit"},
	],
	"uncommon": [
		{"name": "Critical Hit", "desc": "10% chance to double damage"},
		{"name": "Lag", "desc": "Do plus 5 damage but lagged by 4 seconds"},
		{"name": "Damagee", "desc": "+3 Damage per hit"},
		{"name": "Health Pack", "desc": "+40 HP"}
	],
	"rare": [
		{"name": "Risk Taker", "desc": "Do +10 Dmg but take 2X damage in return"},
		{"name": "Fireball", "desc": "Add a fireball attack"},
		{"name": "Second chance", "desc": "Respawn with 10 HP after death. Works once"},
		{"name": "Wavey", "desc": "+10 HP after each wave"}
	],
	"legendary": [
		{"name": "Turtle", "desc": "+100 Health but speed is 60%"},
		{"name": "LEGEND", "desc": "You now do 2X damage to enemies"}
	]
}

var rarity_chances = {
	"common": 0.45,
	"uncommon": 0.30,
	"rare": 0.18,
	"legendary": 0.07
}

@onready var cards = [$Card1, $Card2, $Card3]

func get_random_powerups(count: int = 3) -> Array:
	var selected = []
	for i in range(count):
		var rarity = get_random_rarity()
		var list = powerups[rarity]
		var item = list[randi() % list.size()]
		item["rarity"] = rarity
		selected.append(item)
	return selected

func get_random_rarity() -> String:
	var roll = randf()
	var acc = 0.0
	for rarity in rarity_chances.keys():
		acc += rarity_chances[rarity]
		if roll <= acc:
			return rarity
	return "common"

func show_powerups():
	$"../AnimationPlayer".play("select_power")
	var chosen = get_random_powerups(3)
	for i in range(3):
		var card = cards[i]
		var data = chosen[i]
		card.get_node("Power").text = data.name
		card.get_node("Label").text = data.desc
		set_color_by_rarity(card.get_node("Power"), data.rarity)

func set_color_by_rarity(label: Label, rarity: String):
	match rarity:
		"common":
			label.modulate = Color(0.6, 0.6, 0.6)
		"uncommon":
			label.modulate = Color(1, 1, 1)
		"rare":
			label.modulate = Color(0.2, 0.6, 1)
		"legendary":
			label.modulate = Color(1, 0.85, 0.2)

func _on_card_3_button_pressed() -> void:
	pass # Replace with function body.
