extends CanvasLayer

@export var health_bar: StatBar
@export var player_container: Node2D

var active_player = null

func _physics_process(_delta):
	# Watch for player switches
	if player_container and player_container.active_player != active_player:
		_connect_to_player(player_container.active_player)

func _connect_to_player(new_player):
	# Disconnect from old player if they exist
	if active_player and active_player.is_connected("health_changed", _on_hp_update):
		active_player.health_changed.disconnect(_on_hp_update)
	
	active_player = new_player
	
	if active_player:
		# Connect to the player's built-in signal
		active_player.health_changed.connect(_on_hp_update)
		# Sync immediately
		_on_hp_update(active_player.health)

func _on_hp_update(current_hp):
	if health_bar and active_player:
		health_bar.update_bar(current_hp, active_player.max_health)
