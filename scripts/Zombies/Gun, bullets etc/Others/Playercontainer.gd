extends Node2D

@export var player_scenes: Array[PackedScene]
@export var bullet_scene: PackedScene

var active_player: CharacterBody2D

func _ready():
	spawn_random_player()

func spawn_random_player():
	if active_player:
		active_player.queue_free()

	var index = randi() % player_scenes.size()
	active_player = player_scenes[index].instantiate()
	active_player.bullet_scene = bullet_scene
	add_child(active_player)
	active_player.position = Vector2(0, 0)
	# Add to group dynamically
	active_player.add_to_group("player")


# -------- Movement ----------
func move_left():
	if active_player:
		active_player.move_left()

func move_right():
	if active_player:
		active_player.move_right()

func stop_moving():
	if active_player:
		active_player.stop_moving()

# -------- Firing ----------
func fire_start():
	if active_player:
		active_player.fire_start()

func fire_stop():
	if active_player:
		active_player.fire_stop()
