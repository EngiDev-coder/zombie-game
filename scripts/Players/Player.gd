extends CharacterBody2D

@export_group("Movement")
@export var speed: float = 300
@export var jump_force: float = -450
@export var gravity: float = 900

@export_group("Combat")
@export var fire_rate: float = 0.1
@export var hurt_pause_time: float = 0.5  

@export_group("Health & Regen")
@export var attributes: Resource
@export var max_health: float = 120.0
@export var regen_delay: float = 2.0   
@export var regen_speed: float = 5.0

# ---------------- SIGNALS ----------------
signal health_changed(new_health)
signal player_died

# ---------------- NODE REFERENCES ----------------
@onready var sprite_pivot: Node2D = $PlayerAnimationPivot  
@onready var animation: AnimatedSprite2D = $PlayerAnimationPivot/PlayerAnimation
@onready var fire_timer: Timer = $FireTimer
@onready var muzzle: Marker2D = $PlayerAnimationPivot/GunMuzzle 

# ---------------- STATE VARIABLES ----------------
var health: float 
var is_dead := false
var is_hurting := false 
var move_dir := 0
var facing_dir := 1  
var is_firing := false
var bullet_scene: PackedScene 
var time_since_last_hit: float = 0.0

@onready var sfx: Dictionary = {
	"jump": $Jump,
	"hurt": $Hurt,
	"death": $Death
}

# ---------------- READY ----------------
func _ready():
	add_to_group("player")
	health = float(max_health)
	health_changed.emit(health)
	_set_flash_pct(0.0)
	
# ---------------- HEALTH & REGEN ----------------
func _handle_regeneration(delta):
	if is_dead or health >= max_health: return
	
	time_since_last_hit += delta
	
	if time_since_last_hit >= regen_delay:
		var old_health = health
		# Using regen_speed * delta ensures it's smooth
		health = move_toward(health, float(max_health), regen_speed * delta)
		
		if health != old_health:
			# DEBUG PRINT: This will show you exactly what is happening in the console
			health_changed.emit(health)

func take_hit(amount: int):
	if is_dead or is_hurting or not is_inside_tree(): return 
	
	health -= amount
	health = max(health, 0)
	time_since_last_hit = 0.0 
	
	health_changed.emit(health)
	play_sfx("hurt")
	
	_set_flash_color(Color.WHITE)
	var flash_tween = create_tween()
	_set_flash_pct(1.0)
	flash_tween.tween_method(_set_flash_pct, 1.0, 0.0, 0.15)
	
	if health <= 0:
		die()
	else:
		is_hurting = true
		is_firing = false
		fire_timer.stop()
		velocity = Vector2.ZERO 
		animation.play("hurt")
		await get_tree().create_timer(hurt_pause_time).timeout
		if not is_dead:
			is_hurting = false

func die():
	if is_dead: return
	is_dead = true
	_set_flash_color(Color.RED)
	_set_flash_pct(0.7) 
	velocity = Vector2.ZERO
	set_physics_process(false) 
	animation.play("dead")
	play_sfx("death")
	await animation.animation_finished
	player_died.emit()
	# queue_free() # Removed so game over screen can show the body

# ---------------- PHYSICS PROCESS ----------------
func _physics_process(delta):
	if not is_inside_tree(): return

	_handle_regeneration(delta)

	if is_hurting:
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	# This line handles keyboard; the helper functions below handle UI buttons
	var input_dir := Input.get_action_strength("RightButton") - Input.get_action_strength("LeftButton")
	
	# Only use input_dir if buttons aren't being pressed
	if move_dir == 0:
		var temp_dir = int(sign(input_dir))
		if temp_dir != 0:
			facing_dir = temp_dir
		velocity.x = temp_dir * speed
	else:
		velocity.x = move_dir * speed
		facing_dir = move_dir
	
	if not is_on_floor():
		velocity.y += gravity * delta
		if is_firing:
			fire_stop()
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_force
		play_sfx("jump")
	
	sprite_pivot.scale.x = facing_dir
	
	move_and_slide()
	_keep_inside_viewport()
	_update_animation()

# ---------------- ANIMATION & FIRING ----------------
func _update_animation():
	if is_dead or is_hurting: return
	if not is_on_floor(): animation.play("jump")
	elif is_firing: animation.play("shot_run" if (move_dir != 0 or velocity.x != 0) else "shot")
	elif move_dir == 0 and velocity.x == 0: animation.play("idle")
	else: animation.play("run")

func fire_start():
	if bullet_scene == null or is_firing or is_hurting or not is_on_floor(): return
	is_firing = true
	fire_timer.start(fire_rate)

func fire_stop():
	is_firing = false
	fire_timer.stop()

func _on_FireTimer_timeout():
	if not is_inside_tree() or not is_firing or is_hurting: return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.direction = Vector2(facing_dir, 0)
	get_tree().current_scene.add_child(bullet)

# ---------------- HELPERS ----------------
func _set_flash_pct(pct: float):
	if material is ShaderMaterial: material.set_shader_parameter("flash_modifier", pct)
	if sprite_pivot.material is ShaderMaterial: sprite_pivot.material.set_shader_parameter("flash_modifier", pct)

func _set_flash_color(color: Color):
	if material is ShaderMaterial: material.set_shader_parameter("flash_color", color)
	if sprite_pivot.material is ShaderMaterial: sprite_pivot.material.set_shader_parameter("flash_color", color)

func play_sfx(sound_name: String):
	if sfx.has(sound_name) and sfx[sound_name] != null: sfx[sound_name].play()

func _keep_inside_viewport():
	var rect: Rect2 = get_viewport().get_visible_rect()
	global_position.x = clampf(global_position.x, rect.position.x + 16, rect.position.x + rect.size.x - 16)

# ---------------- BUTTON FUNCTIONS (FIXES THE ERROR) ----------------
func move_left(): 
	move_dir = -1

func move_right(): 
	move_dir = 1

func stop_moving(): 
	move_dir = 0
