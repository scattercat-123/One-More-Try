extends Node3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player: CharacterBody3D = $player
signal sinked

func _ready() -> void:
	if Global.debug_mode == true:
		get_tree().change_scene_to_file("res://Assets/Scenes/world.tscn")

func _on_intro_intro_cutscene_starting_dialogues() -> void:
	animation_player.play("sinking")
	await get_tree().create_timer(1.0).timeout
	player.visible = false
	emit_signal("sinked")
