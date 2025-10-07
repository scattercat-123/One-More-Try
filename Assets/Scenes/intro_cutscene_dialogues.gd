extends Node2D

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var overlap: ColorRect = $Overlap
@onready var color_rect: ColorRect = $ColorRect
signal intro_cutscene_starting_dialogues



func _ready() -> void:
	visible=true
	label.visible=true
	color_rect.visible=true
	overlap.visible=true
	await get_tree().create_timer(2).timeout
	label.text = "You, an adventurer seeking new horizons, set sail for lands unknown…"
	await get_tree().create_timer(3).timeout
	animation_player.play("text_change")
	await get_tree().create_timer(1.0).timeout
	label.text = "The wind howls, the waves crash… your boat is torn apart."
	await get_tree().create_timer(3).timeout
	animation_player.play("text_change")
	await get_tree().create_timer(1.0).timeout
	animation_player.play("hide")
	label.visible = false
	overlap.visible = false
	await get_tree().create_timer(5.0).timeout
	emit_signal("intro_cutscene_starting_dialogues")
	label.text = "You fight to survive… but the sea claims you."

func _on_tutorial_cutscene_sinked() -> void:
	animation_player.play("show")
	label.visible = true
	await get_tree().create_timer(3).timeout
	overlap.visible = false
	label.visible = false
	get_tree().change_scene_to_file("res://Assets/Scenes/world.tscn")
