extends Node2D
@onready var wave: Label = $Wave
@onready var enimies_left: Label = $"Enimies Left"
var once = false
func _ready() -> void:
	enimies_left.visible = false
	$boss.visible = false
func _process(_delta: float) -> void:
	wave.text = "Wave: " + str(Global.wave) + "/" + str(Global.total_waves)
	enimies_left.text = "Enemies Left:" + str(Global.enemies_left)
	if Global.wave == 4:
		$boss.text = "BOSS IS HERE"
	if Global.wave > 1 and once == false:
		enimies_left.visible = true
		$boss.visible = true
		once = true
