extends Control
class_name StatBar

@export_group("Nodes")
@export var back_bar: TextureProgressBar
@export var front_bar: TextureProgressBar

@export_group("Layout Settings")
@export var bar_size: Vector2 = Vector2(1.0, 1.0)
@export var bar_position: Vector2 = Vector2(0, 0)

@export_group("Health Settings")
@export var is_health: bool = true
@export var low_hp_pulse: bool = true

var current_pct := 1.0
var front_tween: Tween
var back_tween: Tween
var pulse_tween: Tween = null

func _ready():
	# Initialize layout
	position = bar_position
	scale = bar_size
	pivot_offset = size / 2
	
	if front_bar:
		_update_color(front_bar.value / front_bar.max_value)

#func _input(event):
	## Test touch/click damage
	#var is_click = (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed()
	#if is_click:
		#update_bar(back_bar.value - 10, 100)

func update_bar(current: float, max_value: float):
	var pct = clamp(current / max_value, 0.0, 1.0)
	front_bar.max_value = max_value
	back_bar.max_value = max_value

	var is_damage = pct < current_pct

	if is_damage:
		if front_tween and front_tween.is_running(): front_tween.kill()
		if back_tween and back_tween.is_running(): back_tween.kill()

		# Front snaps (Notification effect)
		front_bar.value = current
		
		# Back slides slowly
		back_tween = create_tween()
		back_tween.tween_property(back_bar, "value", current, 0.45)
		
		# SHAKE ON EVERY HIT
		_shake()
		_on_damage()

	elif pct > current_pct:
		# Heal logic
		if front_tween and front_tween.is_running(): front_tween.kill()
		if back_tween and back_tween.is_running(): back_tween.kill()
		front_tween = create_tween().set_parallel()
		front_tween.tween_property(front_bar, "value", current, 0.25)
		front_tween.tween_property(back_bar, "value",  current, 0.25)
		_on_heal()

	current_pct = pct
	_update_color(pct)

	if is_health:
		_check_low_hp_pulse(pct)

# --- COLOR LOGIC ---

func _update_color(pct: float):
	if pct > 0.6:
		front_bar.tint_progress = Color("00ff00") # BRIGHT GREEN
	elif pct > 0.25:
		front_bar.tint_progress = Color("ffff00") # BRIGHT YELLOW
	else:
		front_bar.tint_progress = Color("ff0000") # BRIGHT RED

# --- VIBES ---

func _shake():
	var tw = create_tween()
	# Shakes the whole control node
	tw.tween_property(self, "position", bar_position + Vector2(6, 0), 0.04)
	tw.tween_property(self, "position", bar_position - Vector2(6, 0), 0.04)
	tw.tween_property(self, "position", bar_position, 0.04)

func _flash(flash_color: Color):
	modulate = flash_color
	var t = create_tween()
	t.tween_property(self, "modulate", Color(1,1,1), 0.2)

func _on_damage():
	_flash(Color(1.5, 1.5, 1.5)) # Brightening flash

func _on_heal():
	_flash(Color(0.5, 1.5, 0.5)) 

func _check_low_hp_pulse(pct: float) -> void:
	# Pulse only happens when health is low (below 25%)
	if pct <= 0.25 and pct > 0:
		if pulse_tween == null or not pulse_tween.is_running():
			pulse_tween = create_tween().set_loops()
			pulse_tween.tween_property(self, "scale", bar_size * 1.1, 0.2)
			pulse_tween.tween_property(self, "scale", bar_size, 0.2)
	else:
		scale = bar_size
		if pulse_tween:
			pulse_tween.kill()
			pulse_tween = null
