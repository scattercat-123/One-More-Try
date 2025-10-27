extends Node2D
@onready var bg_music: AudioStreamPlayer = $AudioStreamPlayer
@export var parallax_strength: float = 0.05
@onready var night_sky: Sprite2D = $"Night-sky"
var screen_size: Vector2
var base_position: Vector2
var game_scene : PackedScene
var start_hover = false

func _ready():
	game_scene = preload("res://Assets/Scenes/world.tscn")
	screen_size = get_viewport().size
	base_position = night_sky.position
	bg_music.play(Global.music_bg_intro)

func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var offset = (mouse_pos - screen_size / 2) * parallax_strength
	night_sky.position = base_position + offset
