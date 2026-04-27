extends Node2D

@export var gun_scenes: Array[PackedScene] = []  # Drag all gun scenes here
@export var spawn_interval = 5.0
@export var min_x = 100
@export var max_x = 1180
@export var ground_y = 120

var timer = 0.0

func _process(delta):
	timer += delta
	if timer >= spawn_interval:
		timer = 0
		spawn_gun()

func spawn_gun():
	if gun_scenes.size() == 0:
		return
	var gun_scene = gun_scenes[randi() % gun_scenes.size()]
	var gun = gun_scene.instantiate()
	gun.position = Vector2(randi_range(min_x, max_x), ground_y)
	get_parent().add_child(gun)
