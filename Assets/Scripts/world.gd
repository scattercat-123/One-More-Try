extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $player/GUI/GUI_BAR/health_bar
@onready var stamina_bar: ProgressBar = $player/GUI/GUI_BAR/stamina_bar
@onready var player_camera: Camera3D = $player/Camera3D
@onready var cutscene_camera: Camera3D = $cutscene_camera
@onready var markers_parent: Node3D = $Spawning_markers
@onready var spawn_timer: Timer = $SpawnTimer
@onready var powerup_gui = $player/GUI/Power_Ups
@export var fireball_scene: PackedScene = preload("res://Assets/Scenes/fireball_enemy.tscn")
@export var possessed_scene: PackedScene = preload("res://Assets/Scenes/possessed_enemy.tscn")

var enemies_per_wave := [0, 10, 20, 25]
var max_enemies_per_wave := [0, 10, 20]
var enemies_chance_spawn := [60, 40]
var enemies_per_wave_chance_to_spawn: int = 10
var shown_powerups_this_wave = false
var spawned_this_wave := 0    
var last_wave := 0           
var markers: Array = []
var once = true
var once2 = false
var spawn_timer_started := false

func _ready() -> void:
	if Global.debug_mode:
		$"Tutorial blockage/Area/CollisionShape3D2".disabled = true
		$"Tutorial blockage/Wall/CollisionShape3D".disabled = true
		$"Tutorial blockage".visible = true

	Dialogic.start("woke_up_from_island")
	Dialogic.signal_event.connect(signaling)

	health_bar.value = 100
	stamina_bar.value = 100
	player_camera.make_current()

	randomize()
	markers = markers_parent.get_children()

	spawn_timer.stop()
	spawn_timer_started = false

func _process(_delta: float) -> void:

	if Global.wave != last_wave:
		spawned_this_wave = 0
		last_wave = Global.wave
		spawn_timer_started = false

		if spawn_timer and not spawn_timer.is_stopped():
			spawn_timer.stop()

	if Global.wave == 1 and once == true:
		Global.enemies_left = 2
		once = false

	if Global.wave != 1:

		var wave_idx = min(Global.wave - 1, enemies_per_wave.size() - 1)
		var total_for_wave = enemies_per_wave[wave_idx] if wave_idx >= 0 else 0


	if once2 == false and Global.wave == 1 and Global.enemies_left == 0:
		Dialogic.start("after_first_wave")
		once2 = true

	if Global.wave >= 2 and not spawn_timer_started:
		if markers.size() > 0 and Global.wave <= enemies_per_wave.size():
			spawn_timer.start()
			spawn_timer_started = true
func signaling(arg):
	if arg == "cough":
		await get_tree().create_timer(0.5).timeout
		Global.damage = 30
		$Damage_Audio.play()
		$Damager.visible = true
		await get_tree().create_timer(0.3).timeout
		$Damager.visible = false

	if arg == "monster_saw":
		if Global.debug_mode == false:
			animation_player.play("monster_saw")
			cutscene_camera.make_current()
		await get_tree().create_timer(8.0).timeout
		player_camera.make_current()

func spawn_fireball_enemy_at(marker: Node3D) -> void:
	if marker == null:
		return
	var fb = fireball_scene.instantiate()
	get_parent().add_child(fb)
	fb.global_transform = marker.global_transform
	fb.scale = Vector3(2, 2, 2)
	Global.enemies_left += 1
func spawn_possessed_enemy_at(marker: Node3D) -> void:
	if marker == null:
		return
	var ps = possessed_scene.instantiate()
	get_parent().add_child(ps)
	ps.global_transform = marker.global_transform
	ps.scale = Vector3(2, 2, 2)
	Global.enemies_left += 1
func _pick_weighted_index(weights: Array) -> int:
	var sum := 0.0
	for w in weights:
		sum += float(w)
	if sum <= 0.0:
		return 0
	var r := randf() * sum
	var acc := 0.0
	for i in range(weights.size()):
		acc += float(weights[i])
		if r <= acc:
			return i
	return weights.size() - 1
func spawn_batch(count: int, wave_num: int) -> void:
	if markers.size() == 0:
		return
	var modified_chances = enemies_chance_spawn.duplicate()
	for i in range(modified_chances.size()):
		var difficulty_factor = i * enemies_per_wave_chance_to_spawn * max(wave_num - 1, 0)
		modified_chances[i] = float(modified_chances[i]) + float(difficulty_factor)

	for s in range(count):
		if markers.size() == 0:
			break
		var midx = randi() % markers.size()
		var marker: Node3D = markers[midx]

		var chosen = _pick_weighted_index(modified_chances)
		if chosen == 0:
			spawn_fireball_enemy_at(marker)
		elif chosen == 1:
			spawn_possessed_enemy_at(marker)
		else:
			spawn_possessed_enemy_at(marker)

		spawned_this_wave += 1

func _on_spawn_timer_timeout() -> void:
	if Global.wave < 2 or Global.wave > enemies_per_wave.size():
		if spawn_timer_started:
			spawn_timer.stop()
			spawn_timer_started = false
		return
	if markers.size() == 0:
		return
	var wave_idx = min(Global.wave - 1, enemies_per_wave.size() - 1)
	var total_for_wave = enemies_per_wave[wave_idx]
	var max_simultaneous = max_enemies_per_wave[min(wave_idx, max_enemies_per_wave.size() - 1)]
	var remaining_total = max(0, total_for_wave - spawned_this_wave)
	var open_slots = max(0, max_simultaneous - Global.enemies_left)
	var to_spawn = min(remaining_total, open_slots)
	if to_spawn > 0:
		spawn_batch(to_spawn, Global.wave)
	if not shown_powerups_this_wave and spawned_this_wave >= total_for_wave and Global.enemies_left == 0:
		shown_powerups_this_wave = true
		spawn_timer.stop()
		spawn_timer_started = false
		powerup_gui.show_powerups()
		print("Wave %d complete! Showing powerups..." % Global.wave)
	else:
		spawn_timer.start()
		spawn_timer_started = true

func _on_power_ups_powerup_selected() -> void:
	Global.wave += 1
	spawned_this_wave = 0
	shown_powerups_this_wave = false 
