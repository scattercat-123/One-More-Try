extends Node3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $player/GUI/GUI_BAR/health_bar
@onready var stamina_bar: ProgressBar = $player/GUI/GUI_BAR/stamina_bar
@onready var damage_audio: AudioStreamPlayer = $SFX/Damage_Audio
@onready var damage_rect: ColorRect = $Damager2
@onready var player_camera: Camera3D = $player/Camera3D
@onready var cutscene_camera: Camera3D = $cutscene_camera

func _ready() -> void:
	Dialogic.start("woke_up_from_island")
	Dialogic.signal_event.connect(signaling)
	health_bar.value = 100
	stamina_bar.value = 100
	damage_rect.visible = false
	player_camera.make_current()
	
func _process(delta: float) -> void:
	pass

func signaling(arg):
	if arg == "cough":
		await get_tree().create_timer(0.75).timeout
		animation_player.play("cough")
		damaging(30)
	if arg == "monster_saw":
		animation_player.play("monster_saw")
		cutscene_camera.make_current()
		await get_tree().create_timer(8.0).timeout
		player_camera.make_current()
		
func damaging(dmg : float):
	var target_value = health_bar.value - dmg
	target_value = clamp(target_value, 0, health_bar.max_value)

	damage_audio.play()
	var tween = create_tween()
	tween.tween_property(health_bar, "value", target_value, 1)
	damage_rect.visible = true
	await  get_tree().create_timer(0.2).timeout
	damage_rect.visible = false
