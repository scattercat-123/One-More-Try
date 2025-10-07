extends Node2D
@onready var wave: Label = $Wave
@onready var enimies_left: Label = $"Enimies Left"

func _ready() -> void:
	Dialogic.signal_event.connect(signaling)
	enimies_left.visible = false

func _process(delta: float) -> void:
	wave.text = "Wave: " + str(Global.wave) + "/" + str(Global.total_waves)
	enimies_left.text = "Enemies Left:" + str(Global.enemies_left)
	
func signaling(arg):
	if arg == "fight_first_enemy":
		enimies_left.visible = true
