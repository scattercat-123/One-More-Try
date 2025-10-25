extends Label

func _process(_delta: float) -> void:
	text = str(int($"..".value)) + "/" + str(int($"..".max_value))
