extends Node2D

@onready var bg_music: AudioStreamPlayer = $AudioStreamPlayer
@export var parallax_strength: float = 0.05
@onready var night_sky: Sprite2D = $"Night-sky"

var screen_size: Vector2
var base_position: Vector2

var fade_in_time := 3# seconds to fully fade
var fade_elapsed := 0.0
var fading_in := false
var start_hover = false

func _ready():
	if Global.debug_mode: # devs wanna skip cutscene for fasat debuging and testing.
		get_tree().change_scene_to_file("res://Assets/Scenes/tutorial_cutscene.tscn")
	screen_size = get_viewport().size
	base_position = night_sky.position
	
	bg_music.volume_db = -80
	await get_tree().create_timer(3.0).timeout
	bg_music.play()
	fade_elapsed = 0.0
	fading_in = true

func _process(delta: float) -> void:
	# bg eeffect
	var mouse_pos = get_viewport().get_mouse_position()
	var offset = (mouse_pos - screen_size / 2) * parallax_strength
	night_sky.position = base_position + offset
	
	# muic fade in
	if fading_in:
		fade_elapsed += delta
		var t = fade_elapsed / fade_in_time
		bg_music.volume_db = lerp(-80.0, -20.0, clamp(t, 0, 1))
		if t >= 1.0:
			fading_in = false
