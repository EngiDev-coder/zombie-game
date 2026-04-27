extends Node2D

@export var zombie_scenes: Array[PackedScene]
@export var spawn_left: Node2D
@export var spawn_right: Node2D
@export var spawn_delay: float = 2.0

@onready var timer: Timer = Timer.new()

func _ready() -> void:
	if zombie_scenes.is_empty() or spawn_left == null or spawn_right == null:
		push_error("ZombieSpawner: Missing scenes or spawn points!")
		return

	timer.wait_time = spawn_delay
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(spawn_zombie)
	add_child(timer)

func spawn_zombie() -> void:
	# Pick a random zombie scene
	var zombie_scene: PackedScene = zombie_scenes.pick_random()
	var zombie: CharacterBody2D = zombie_scene.instantiate()
	# Pick left or right spawn point
	var spawn_point: Node2D = spawn_left if randf() < 0.5 else spawn_right
	zombie.global_position = spawn_point.global_position
	# Add to scene after setup to avoid errors
	get_tree().current_scene.add_child(zombie)

	# Assign player target if needed (optional)
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player != null and zombie.has_method("player"):
		zombie.player = player  # If your zombie script has a 'player' variable
