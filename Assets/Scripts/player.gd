extends CharacterBody3D
@onready var sprite: AnimatedSprite3D = $sprite
@onready var slash_sprite: AnimatedSprite3D = $slash
@onready var attack_area: CollisionShape3D = $"Areas for hitting/player_hitbox/CollisionShape3D"
@onready var stamina_bar: ProgressBar = $GUI/GUI_BAR/stamina_bar
@onready var health_bar: ProgressBar = $GUI/GUI_BAR/health_bar
var is_slashing = false
const SPEED = 1.7
var SPEED_ACTUAL
var flip_speed = 20
var flip_right = true
var running = false
var facing : String
var is_rolling:= false
var can_move = false
var player_dmg : int
var player_health : int
@export var rolling_cooldown = 0.7
@export var roll_dis: int = 3
var is_rolling_cooldown = false
var last_dir: Vector3 = Vector3.FORWARD
@onready var debug_label_speed: Label3D = $debug_label_speed
@onready var notices: Label3D = $Notices
@onready var camera: Camera3D = $Camera3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func health_baring(health : float):
	var target_value = health
	target_value = clamp(target_value, 0, health_bar.max_value)
	var tween = create_tween()
	tween.tween_property(health_bar, "value", target_value, 1)

func _ready() -> void:
	notices.visible = false
	attack_area.disabled = true
	SPEED_ACTUAL= SPEED
	player_dmg = 10
	player_health = 100
	if Global.debug_mode:
		can_move = true
		debug_label_speed.visible = true
	Dialogic.signal_event.connect(signaling)

func _process(_delta: float) -> void:
	var speed_factor :float = (1.0 + (Global.speed_boost * 0.20))
	SPEED_ACTUAL = SPEED * speed_factor
	debug_label_speed.text = str(SPEED_ACTUAL)
	player_health = (100 + Global.extra_health) - Global.damage
	Global.player_health = player_health + (Global.extra_health * 20) + (Global.health_pack * 40)
	player_dmg = 10 + (Global.extra_dmg)*2 + (Global.extra_dmgee)* 3
	Global.player_dmg = player_dmg
	health_bar.max_value = 100 + (Global.extra_health * 20) + (Global.health_pack * 40)
	Global.max_health = health_bar.max_value 
	health_baring(player_health)

	if stamina_bar.value < stamina_bar.max_value:
		stamina_bar.value += Global.stamina_regen
	if Global.player_health <= 0 and Global.second_chance == false and Global.has_died == false:
		$SFX/death.play()
		Global.has_died = true
		Dialogic.end_timeline()
		animation_player.play("Change")
		await get_tree().create_timer(1.5).timeout
		$"../cutscene_camera".make_current()
		$"../AnimationPlayer".play("spectate")
		$SFX/womp.play()
		await get_tree().create_timer(6.25).timeout
		animation_player.play("Change")
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://Assets/Scenes/game_over.tscn")
	
	elif Global.player_health <= 0 and Global.second_chance:
		player_health = 20
		Global.second_chance = false
		$SFX/Respawned.play()
		new_notice("You have used your second chance powerup!")

func _physics_process(delta: float) -> void:
	if not is_slashing and not is_rolling:
		if flip_right:
			sprite.rotation_degrees.y = shortest_angle_deg(sprite.rotation_degrees.y, 0, flip_speed)
		else:
			sprite.rotation_degrees.y = shortest_angle_deg(sprite.rotation_degrees.y, 180, flip_speed)
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		last_dir = direction
	if Input.is_action_just_pressed("roll") and not is_rolling and can_move and not is_rolling_cooldown and stamina_bar.value > 30:
		stamina_bar.value = stamina_bar.value - 25
		await roll(last_dir)
	if can_move and not is_slashing and not is_rolling:
		if direction:
			velocity.x = direction.x * SPEED_ACTUAL
			velocity.z = direction.z * SPEED_ACTUAL
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED_ACTUAL)
			velocity.z = move_toward(velocity.z, 0, SPEED_ACTUAL)
	
		if input_dir.x > 0:
			flip_right = true
		elif input_dir.x < 0:
			flip_right = false
		if direction.length() == 0:
			playidle()
		elif direction.length() > 0:
			playwalk(direction)
			
	if Input.is_action_just_pressed("click") and is_slashing == false and not is_rolling:
		sprite.stop()
		stamina_bar.value = stamina_bar.value - 5
		await slash(facing)
	move_and_slide()
	
func signaling(arg):
	if arg == "fight_first_enemy":
		can_move = true
	if arg == "first_wave_powerups":
		$GUI/Power_Ups.show_powerups()
	if arg == "start_attack":
		$"../Tutorial blockage/Wall/CollisionShape3D".disabled = true
		$"../Tutorial blockage/Area/CollisionShape3D2".disabled = true
		$"../Tutorial blockage".visible = false

func slash(facing_dir):
	is_slashing = true
	attack_area.disabled = false
	var music_rand_int = randi_range(1,2)
	if music_rand_int == 1:
		$slash/slash_1.play()
	elif music_rand_int == 2:
		$slash/slash_2.play()

	if (facing_dir == "up_right" or facing_dir == "up") and flip_right:
		sprite.play("up_slash")
		slash_sprite.stop()
		slash_sprite.play("up_right_slash")
	elif (facing_dir == "down_right" or facing_dir == "right") and flip_right:
		sprite.play("right_slash")
		slash_sprite.stop()
		slash_sprite.play("down_right_slash")
	elif facing_dir == "down" and flip_right:
		sprite.play("down_slash")
		slash_sprite.stop()
		slash_sprite.play("down_left_slash")
	elif facing_dir == "up" and not flip_right:
		sprite.rotation_degrees.y = 0
		sprite.play("up_slash")
		slash_sprite.stop()
		slash_sprite.play("up_right_slash")
	elif (facing_dir == "up_right" or facing_dir == "right") and not flip_right:
		sprite.play("left_slash")
		slash_sprite.stop()
		slash_sprite.play("up_left_slash")
	elif (facing_dir == "down_right" or facing_dir == "right" or facing_dir == "down") and not flip_right:
		sprite.rotation_degrees.y = 0
		sprite.play("down_slash")
		slash_sprite.stop()
		slash_sprite.play("down_left_slash")
	await sprite.animation_finished
	attack_area.disabled = true
	is_slashing = false
	
func playwalk(dir) -> void: # runniing code
	if dir.z < 0 and abs(dir.x)> 0:
		sprite.play("up_right_run")
		facing = "up_right"
	elif dir.z > 0 and abs(dir.x) > 0:
		sprite.play("down_right_run")
		facing = "down_right"
	elif abs(dir.x) > 0 and dir.y == 0:
		sprite.play("left_right_run")
		facing = "right"
	elif dir.z < 0:
		facing = "up"
		sprite.play("up_run")
	elif dir.z > 0:
		facing = "down"
		sprite.play("down_run")

func playidle() -> void: #idle code
	if facing == "up_right":
		sprite.play("up_right_idle")
	elif facing == "down_right":
		sprite.play("down_right_idle")
	elif facing == "right":
		sprite.play("left_right_idle")
	elif facing == "up":
		sprite.play("up_idle")
	elif facing == "down":
		sprite.play("down_idle")
		
func shortest_angle_deg(current: float, target: float, step: float) -> float:
	var diff = fmod((target - current + 180), 360) - 180
	return current + clamp(diff, -step, step)

func new_notice(text: String):
	notices.visible = true
	notices.text = text
	await get_tree().create_timer(5.0).timeout
	notices.visible = false

func roll(dir) -> void: #roll
	is_rolling = true
	can_move = false

	var roll_duration = 0.3
	var roll_speed = roll_dis / roll_duration

	var roll_dir = dir.normalized()
	velocity = roll_dir * roll_speed
	play_anim_roll(dir)
	await get_tree().create_timer(roll_duration).timeout

	velocity = Vector3.ZERO
	is_rolling = false
	can_move = true
	is_rolling_cooldown = true
	await get_tree().create_timer(rolling_cooldown).timeout
	is_rolling_cooldown = false
	
func play_anim_roll(dir) -> void:
	if dir.z < 0 and abs(dir.x)> 0:
		sprite.play("up_right_roll")
	elif dir.z > 0 and abs(dir.x) > 0:
		sprite.play("down_right_roll")
	elif abs(dir.x) > 0 and dir.y == 0:
		sprite.play("roll_right")
	elif dir.z < 0:
		sprite.play("up_roll")
	elif dir.z > 0:
		sprite.play("down_roll")

func _on_hurtbox_area_entered(area: Area3D) -> void:
	$SFX/Damage_Audio.pitch_scale = 1
	$SFX/Damage_Audio.play()
	if area.is_in_group("Tutorial_blockage"):
		new_notice("Must Complete Tutorial to advance")
		$"../AnimationPlayer".play("must_complete_tutorial")
	if area.is_in_group("Fireball"):
		Global.damage += 3
	if area.is_in_group("Possessed_Jump"):
		Global.damage += 5
	if area.is_in_group("Possessed_Attack"):
		Global.damage += 7

func _on_ocean_body_entered(body: Node3D) -> void:
	player_health -= 9000
