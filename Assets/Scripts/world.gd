extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $player/GUI/GUI_BAR/health_bar
@onready var stamina_bar: ProgressBar = $player/GUI/GUI_BAR/stamina_bar
@onready var player_camera: Camera3D = $player/Camera3D
@onready var cutscene_camera: Camera3D = $cutscene_camera
@onready var markers_parent: Node3D = $Spawning_markers
@onready var spawn_timer: Timer = $SpawnTimer

@export var fireball_scene: PackedScene = preload("res://Assets/Scenes/fireball_enemy.tscn")
@export var possessed_scene: PackedScene = preload("res://Assets/Scenes/possessed_enemy.tscn")

# total enemies that should spawn for each wave (wave 1 -> enemies_per_wave[0], wave 2 -> [1], etc.)
var enemies_per_wave := [10, 20, 35]

# concurrent cap per wave (how many may be alive at once for that wave)
var max_enemies_per_wave := [6, 10, 20]

# spawn weights for enemy types (index 0 -> fireball, index 1 -> possessed)
var enemies_chance_spawn := [60, 40]

# how much harder enemies gain chance each wave (tunable)
var enemies_per_wave_chance_to_spawn: int = 10

# runtime tracking
var spawned_this_wave := 0    # how many we have spawned so far (cumulative) this wave
var last_wave := 0           # used to detect a wave change
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

	# ensure the timer is stopped until the appropriate wave starts
	spawn_timer.stop()
	spawn_timer_started = false

func _process(_delta: float) -> void:
	# reset per-wave counters when the wave actually changes
	if Global.wave != last_wave:
		spawned_this_wave = 0
		last_wave = Global.wave
		spawn_timer_started = false
		# ensure timer isn't left running from previous wave
		if spawn_timer and not spawn_timer.is_stopped():
			spawn_timer.stop()

	# tutorial special-case (keeps your original behavior)
	if Global.wave == 1 and once == true:
		Global.enemies_left = 2
		once = false

	# If wave finished (we spawned the full quota AND there are no alive enemies), advance wave
	# Do not advance from wave 1 (your original logic excluded wave 1)
	if Global.wave != 1:
		# compute total enemies for this wave safely
		var wave_idx = min(Global.wave - 1, enemies_per_wave.size() - 1)
		var total_for_wave = enemies_per_wave[wave_idx] if wave_idx >= 0 else 0

		# only advance if we've spawned all enemies for the wave AND there are none left alive
		if total_for_wave > 0 and spawned_this_wave >= total_for_wave and Global.enemies_left == 0:
			# advance exactly once
			Global.wave += 1
			# stop spawn timer (it will be restarted when appropriate by the code that starts spawning)
			if spawn_timer and not spawn_timer.is_stopped():
				spawn_timer.stop()
			spawn_timer_started = false

	# original one-off dialog after first wave
	if once2 == false and Global.wave == 1 and Global.enemies_left == 0:
		Dialogic.start("after_first_wave")
		once2 = true

	# Start the spawn timer automatically when wave >= 2 and it hasn't started yet
	# (you said spawning begins from wave 2)
	if Global.wave >= 2 and not spawn_timer_started:
		# sanity: only start if there are markers and the wave index is valid
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

# --------- spawn helpers ----------
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

# Weighted index picker for any length weights array
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

# spawn `count` enemies right now, respecting weighted chances biased by wave number
func spawn_batch(count: int, wave_num: int) -> void:
	if markers.size() == 0:
		return

	# build modified chances (harder types gain extra chance with each wave)
	var modified_chances = enemies_chance_spawn.duplicate()
	for i in range(modified_chances.size()):
		var difficulty_factor = i * enemies_per_wave_chance_to_spawn * max(wave_num - 1, 0)
		modified_chances[i] = float(modified_chances[i]) + float(difficulty_factor)

	# spawn `count` enemies (respecting available markers)
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
			# fallback for additional types; treat as possessed for now
			spawn_possessed_enemy_at(marker)

		# track how many we've spawned this wave
		spawned_this_wave += 1

# --------- timer callback ----------
# Attach this to your SpawnTimer's timeout() signal (or keep the node name SpawnTimer and it will be called)
func _on_spawn_timer_timeout() -> void:
	# only spawn from wave 2 up to the number of waves defined
	if Global.wave < 2 or Global.wave > enemies_per_wave.size():
		# if we're outside wave range, stop the timer and mark as not started
		if spawn_timer_started:
			spawn_timer.stop()
			spawn_timer_started = false
		return

	# safety: if no markers, don't try to spawn
	if markers.size() == 0:
		return

	var wave_idx = min(Global.wave - 1, enemies_per_wave.size() - 1)
	var total_for_wave = enemies_per_wave[wave_idx]
	var max_simultaneous = max_enemies_per_wave[min(wave_idx, max_enemies_per_wave.size() - 1)]

	# how many we still need to spawn overall this wave
	var remaining_total = max(0, total_for_wave - spawned_this_wave)
	# how many open "slots" (concurrent cap minus currently alive)
	var open_slots = max(0, max_simultaneous - Global.enemies_left)

	# spawn at most the smaller of those (so we don't exceed total_for_wave or the concurrent cap)
	var to_spawn = min(remaining_total, open_slots)

	if to_spawn > 0:
		spawn_batch(to_spawn, Global.wave)

	# If we still need to spawn more for this wave, keep the timer running; otherwise stop it
	if spawned_this_wave < total_for_wave:
		# restart timer for next batch tick
		spawn_timer.start()
		spawn_timer_started = true
	else:
		# finished spawning for this wave
		spawn_timer_started = false
		# don't forcibly stop the timer if it's already stopped; safe call:
		if spawn_timer.is_stopped() == false:
			spawn_timer.stop()
  
