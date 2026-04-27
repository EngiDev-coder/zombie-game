# Main.gd
extends Node

@onready var player_container = $PlayerContainer
@onready var left_button = $UI/LeftButton
@onready var right_button = $UI/RightButton
@onready var fire_button = $UI/FireButton
@onready var jump_button = $UI/JumpButton
@onready var camera = $Camera2D
@onready var ui_manager = $UIManager

func _ready():
# Connect all players to the UI Manager
	for player in player_container.get_children():
		player.player_died.connect(ui_manager.show_restart)




	# Connect button signals
	left_button.pressed.connect(_on_left_pressed)
	left_button.released.connect(_on_left_released)

	right_button.pressed.connect(_on_right_pressed)
	right_button.released.connect(_on_right_released)

	fire_button.pressed.connect(_on_fire_pressed)
	fire_button.released.connect(_on_fire_released)
	
	
	
	
# Left movement
func _on_left_pressed():
	player_container.move_left()

func _on_left_released():
	player_container.stop_moving()

# Right movement
func _on_right_pressed():
	player_container.move_right()

func _on_right_released():
	player_container.stop_moving()

# Fire
func _on_fire_pressed():
	player_container.fire_start()

func _on_fire_released():
	player_container.fire_stop()
	
	
func _input(event):
	# Listen for the "Back" button (Escape)
	if event.is_action_pressed("pause"):
		ui_manager.toggle_pause()
