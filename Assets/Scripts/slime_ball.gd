extends CharacterBody3D

@onready var nav: NavigationAgent3D = $NavigationAgent3D
var target: Node3D = null
var player :CharacterBody3D
@export var speed: float = 2
var can_detect = false
func _ready():
	await get_tree().create_timer(0.1).timeout
	find_target()
	can_detect = true
	
func _process(delta):
	if not is_instance_valid(target):
		find_target()
		return
	rotation_degrees.z += 3
	nav.target_position = target.global_position
	if nav.is_navigation_finished():
		return
	var next_pos = nav.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

func find_target():
	var enemies = get_tree().get_nodes_in_group("Player")
	if enemies.size() > 0:
		target = enemies.pick_random()
		nav.target_position = target.global_position
		

func _on_area_area_entered(area: Area3D) -> void:
			$ball.modulate = "#b83e3e"
			$area/CollisionShape3D.disabled = true
			await get_tree().create_timer(0.1).timeout
			queue_free()

func _on_timer_timeout() -> void:
	queue_free()
