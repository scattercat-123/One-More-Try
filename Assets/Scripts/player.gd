extends CharacterBody3D
@onready var sprite: AnimatedSprite3D = $sprite
@onready var slash_sprite: AnimatedSprite3D = $slash
@onready var attack_areas = {
	"up": $"Areas for hitting/Up",
	"down": $"Areas for hitting/Down",
	"right": $"Areas for hitting/Right",
	"up_right": $"Areas for hitting/Top_Right",
	"down_right": $"Areas for hitting/Bottom_Right",
	"left": $"Areas for hitting/Left",
	"up_left": $"Areas for hitting/Top_Left",
	"down_left": $"Areas for hitting/Bottom_Left"
	
}
@onready var stamina_bar: ProgressBar = $GUI/GUI_BAR/stamina_bar
var is_slashing = false
const SPEED = 1.7
var flip_speed = 20
var flip_right = true
var running = false
var facing : String
var is_rolling:= false
var can_move = false
@export var rolling_cooldown = 1.0
@export var roll_dis: int = 3
var is_rolling_cooldown = false
var last_dir: Vector3 = Vector3.FORWARD

func _ready() -> void:
	if Global.debug_mode:
		can_move = true
	Dialogic.signal_event.connect(signaling)

func _process(delta: float) -> void:
	if stamina_bar.value < stamina_bar.max_value:
		stamina_bar.value += Global.stamina_regen

func _physics_process(delta: float) -> void:
	if is_slashing == false:
		if flip_right:
			sprite.rotation_degrees.y = shortest_angle_deg(sprite.rotation_degrees.y, 0, flip_speed)
		else:
			sprite.rotation_degrees.y = shortest_angle_deg(sprite.rotation_degrees.y, 180, flip_speed)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		last_dir = direction
	if Input.is_action_just_pressed("roll") and not is_rolling and can_move and not is_rolling_cooldown and stamina_bar.value > 0:
		stamina_bar.value = stamina_bar.value - 25
		await roll(last_dir)
	if can_move and not is_slashing:
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	
		if input_dir.x > 0:
			flip_right = true
		elif input_dir.x < 0:
			flip_right = false
		if direction.length() == 0:
			playidle(facing)
		elif direction.length() > 0:
			playwalk(direction)
			
	if Input.is_action_just_pressed("click") and is_slashing == false:
		sprite.stop()
		stamina_bar.value = stamina_bar.value - 5
		await slash(facing)
	move_and_slide()
	
func signaling(arg):
	if arg == "fight_first_enemy":
		can_move = true
	if arg == "first_wave_powerups":
		$GUI/Power_Ups.show_powerups()

func slash(facing_dir):
	is_slashing = true
	for a in attack_areas.values():
		a.monitorable = false
	if (facing_dir == "up_right" or facing_dir == "up") and flip_right:
		sprite.play("up_slash")
		slash_sprite.stop()
		slash_sprite.play("up_right_slash")
		attack_areas["up_right"].monitorable = true
	elif (facing_dir == "down_right" or facing_dir == "right") and flip_right:
		sprite.play("right_slash")
		slash_sprite.stop()
		slash_sprite.play("down_right_slash")
		attack_areas["down_right"].monitorable = true
	elif facing_dir == "down" and flip_right:
		sprite.play("down_slash")
		slash_sprite.stop()
		slash_sprite.play("down_left_slash")
		attack_areas["down_left"].monitorable = true
	elif facing_dir == "up" and not flip_right:
		sprite.rotation_degrees.y = 0
		sprite.play("up_slash")
		slash_sprite.stop()
		slash_sprite.play("up_right_slash")
		attack_areas["up_left"].monitorable = true
	elif (facing_dir == "up_right" or facing_dir == "right") and not flip_right:
		sprite.play("left_slash")
		slash_sprite.stop()
		slash_sprite.play("up_left_slash")
		attack_areas["up_left"].monitorable = true
	elif (facing_dir == "down_right" or facing_dir == "right" or facing_dir == "down") and not flip_right:
		sprite.rotation_degrees.y = 0
		sprite.play("down_slash")
		slash_sprite.stop()
		slash_sprite.play("down_left_slash")
		attack_areas["down_left"].monitorable = true
	await sprite.animation_finished
	for a in attack_areas.values():
		a.monitorable = false
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

func playidle(facing) -> void: #idle code
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

func roll(dir) -> void: #roll
	is_rolling = true
	can_move = false

	var roll_duration = 0.3
	var roll_speed = roll_dis / roll_duration

	var roll_dir = dir.normalized()
	velocity = roll_dir * roll_speed
	play_anim_roll(dir)
	# Start coroutine
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
