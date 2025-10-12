extends Label

func _process(_delta: float) -> void:
	text = str(Global.player_health) + "/" + str(int(Global.max_health))
