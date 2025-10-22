extends CharacterBody3D

@onready var nav: NavigationAgent3D = $NavigationAgent3D
var target: Node3D = null
@export var speed: float = 4.0

var can_detect := false

func _ready():
	await get_tree().create_timer(0.2).timeout
	find_target()
	$glow.play()
	can_detect = true
	
func _process(delta):
	if not is_instance_valid(target):
		find_target()
		return
	nav.target_position = target.global_position
	if nav.is_navigation_finished():
		return
	var next_pos = nav.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
func find_target():
	var enemies = get_tree().get_nodes_in_group("Enemies")
	if enemies.size() > 0:
		target = enemies.pick_random()
		nav.target_position = target.global_position
	
func _on_hit_area_entered(area: Area3D) -> void:
	if not can_detect:
		return
	if area.is_in_group("Enemy_Areas"):
		queue_free()
