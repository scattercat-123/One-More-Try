extends CharacterBody3D
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
var can_move=false
var enabled = true
var facing: String
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var player: CharacterBody3D = $"../player"
var flip_speed = 20
@export var speed := 1
var health = 16
var once = false
func _ready() -> void:
	Dialogic.signal_event.connect(signaling)
	Global.enemies_left = 1

func _process(delta: float) -> void:
	if can_move:
		rotation_degrees.y = 0
		if enabled:
			navigator(delta)
	else:
		rotation_degrees.y = 90
	if health <= 0:
		visible = false
		queue_free()
		Global.enemies_left = 0
		if once == false:
			Global.wave = 2
			Dialogic.start("after_first_wave")
			once = true

func _physics_process(delta: float) -> void:
	var direction = velocity.normalized()
	if direction.x > 0:
		sprite.rotation_degrees.y = shortest_angle_deg(sprite.rotation_degrees.y, 0, flip_speed)
	else:
		sprite.rotation_degrees.y = shortest_angle_deg(sprite.rotation_degrees.y, 180, flip_speed)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if direction.length() > 0.01:
		playwalk(direction)
	else:
		sprite.stop()
	move_and_slide()
	
func signaling(arg):
	if arg == "fight_first_enemy":
		can_move = true

func navigator(_delta):
	var target_pos = player.global_position
	target_pos.y = global_position.y
	nav.target_position = target_pos
	var next_pos = nav.get_next_path_position()
	next_pos.y = global_position.y
	var direction = (next_pos - global_position).normalized()
	velocity = direction * speed

func playwalk(dir: Vector3) -> void: #RUNNING logic
	var tolerance = 0.3

	var dx = dir.x
	var dz = dir.z
	if abs(dx) < tolerance:
		dx = 0
	if abs(dz) < tolerance:
		dz = 0

	if dz < 0 and abs(dx) > 0:
		sprite.play("up_left_right_run")
		facing = "up_right"
	elif dz > 0 and abs(dx) > 0:
		sprite.play("down_left_right_run")
		facing = "down_right"
	elif abs(dx) > 0 and dz == 0:
		sprite.play("right_left_run")
		facing = "right"
	elif dz < 0:
		facing = "up"
		sprite.play("up_run")
	elif dz > 0:
		facing = "down"
		sprite.play("down_run")

func shortest_angle_deg(current: float, target: float, step: float) -> float:
	var diff = fmod((target - current + 180), 360) - 180
	return current + clamp(diff, -step, step)

func _on_hitbox_area_entered(area: Area3D) -> void:
	health = health - Global.player_dmg
