extends Control
signal powerup_chosen

var card_1_hover = false
var card_2_hover = false
var card_3_hover = false
var powerups = {
	"common": [
		{"name": "Speed Boost", "desc": "Move 10% faster", "var": "Global.speed_boost", "var_type": "int"},
		{"name": "Extra Health", "desc": "+20 HP", "var": "Global.extra_health", "var_type": "int"},
		{"name": "Range", "desc": "More attack Range", "var": "Global.extra_range", "var_type": "int"},
		{"name": "Extra Dmg", "desc": "+2 Damage per hit", "var": "Global.extra_dmg", "var_type": "int"},
	],
	"uncommon": [
		{"name": "Critical Hit", "desc": "10% chance to double damage", "var": "Global.crit_hit", "var_type": "bool"},
		{"name": "Lag", "desc": "Do plus 5 damage but lagged by 4 seconds", "var": "Global.lag", "var_type": "bool"},
		{"name": "Damagee", "desc": "+3 Damage per hit", "var": "Global.extra_dmgee", "var_type": "int"},
		{"name": "Health Pack", "desc": "+40 HP", "var": "Global.health_pack", "var_type": "int"}
	],
	"rare": [
		{"name": "Risk Taker", "desc": "Do +10 Dmg but take 1.5X damage in return", "var": "Global.risk_taker", "var_type": "bool"},
		{"name": "Second chance", "desc": "Respawn with 20 HP after death. Works once", "var": "Global.second_chance", "var_type": "bool"},
		{"name": "Wavey", "desc": "+10 HP after each wave", "var": "Global.wavey", "var_type": "bool"}
	],
	"legendary": [
		{"name": "Turtle", "desc": "+100 Health but speed is 60%", "var": "Global.turle", "var_type": "bool"},
		{"name": "LEGEND", "desc": "You now do 2X damage to enemies", "var": "Global.LEGEND", "var_type": "bool"}
	]
}

var rarity_chances = {
	"common": 0.45,
	"uncommon": 0.30,
	"rare": 0.18,
	"legendary": 0.07
}

@onready var cards = [$CanvasLayer/Card1, $CanvasLayer/Card2, $CanvasLayer/Card3]

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
		card.set_meta("data", data)
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
func apply_powerup(card):
	var data = card.get_meta("data")
	if data == null:
		return
	mark_powerup_taken(data)
	var var_path = data["var"]
	var var_type = data["var_type"]

	var parts = var_path.split(".")
	var var_name = parts[1]
	match var_type:
		"int":
			Global.set(var_name, Global.get(var_name) + 1)
			print(Global.get(var_name))
		"bool":
			Global.set(var_name, true)
			print(Global.get(var_name))
			mark_powerup_taken(data)

	$"../AnimationPlayer".play("hide_power")
	
func mark_powerup_taken(data: Dictionary) -> void:
	var rarity = data.get("rarity", "")
	if rarity == "":
		return
	var list = powerups[rarity]
	for i in range(list.size()):
		var it = list[i]
		if it["name"] == data["name"] and it["var"] == data["var"]:
			list.remove_at(i)
			return

func _process(_delta: float) -> void:
	if card_1_hover and Input.is_action_just_pressed("click"):
		apply_powerup($CanvasLayer/Card1)
		emit_signal("powerup_chosen")
		Global.wave += 1
		$"../granted".play()
	elif card_2_hover and Input.is_action_just_pressed("click"):
		apply_powerup($CanvasLayer/Card2)
		emit_signal("powerup_chosen")
		Global.wave += 1
		$"../granted".play()
	elif card_3_hover and Input.is_action_just_pressed("click"):
		apply_powerup($CanvasLayer/Card3)
		emit_signal("powerup_chosen")
		Global.wave += 1
		$"../granted".play()


func _on_card_1_mouse_entered() -> void:
	card_1_hover = true

func _on_card_1_mouse_exited() -> void:
	card_1_hover = false

func _on_card_2_mouse_entered() -> void:
	card_2_hover = true

func _on_card_2_mouse_exited() -> void:
	card_2_hover = false

func _on_card_3_mouse_entered() -> void:
	card_3_hover = true

func _on_card_3_mouse_exited() -> void:
	card_3_hover = false
