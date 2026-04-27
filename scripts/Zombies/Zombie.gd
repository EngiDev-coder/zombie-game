extends CharacterBody2D

# ---------------- CONFIGURATION ----------------
@export_group("Movement")
@export var speed: float = 60.0
@export var gravity: float = 900.0

@export_group("Combat")
@export var attack_range: float = 45.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0

@export_group("Health")
@export var max_health: float = 140.0

# ---------------- NODE REFERENCES ----------------
# At the top
@onready var health_bar = $ZombieHealthBar
@onready var sprite_pivot: Node2D = $SpritePivot
@onready var animation: AnimatedSprite2D = $SpritePivot/AnimatedSprite2D
@onready var attack_pivot: Node2D = $AttackPivot
@onready var attack_collision: CollisionShape2D = $AttackPivot/AttackArea/AttackPoint
@onready var sfx: Dictionary = {
	"death": $Sounds/Death,
	"hurt": $Sounds/Hurt,
	"attack": $Sounds/Attack
}

var player: CharacterBody2D = null
var initial_attack_pos: Vector2 

# ---------------- STATE VARIABLES ----------------
var health: float
var is_attacking: bool = false
var is_waiting: bool = false
var is_dead: bool = false
var has_hit_this_swing: bool = false 

# ---------------- READY ----------------
func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	initial_attack_pos = attack_pivot.position
	attack_collision.disabled = true
	_play_animation("idle")
	
	# Initialize flash to 0
	_set_flash_pct(0.0)

#-------------- FLASH HELPERS --------------#
func _set_flash_pct(pct: float):
	# Checks both the Body and the Pivot for the material
	if material is ShaderMaterial:
		material.set_shader_parameter("flash_modifier", pct)
	if sprite_pivot.material is ShaderMaterial:
		sprite_pivot.material.set_shader_parameter("flash_modifier", pct)

func _set_flash_color(color: Color):
	if material is ShaderMaterial:
		material.set_shader_parameter("flash_color", color)
	if sprite_pivot.material is ShaderMaterial:
		sprite_pivot.material.set_shader_parameter("flash_color", color)

# ---------------- SOUND HELPER ----------------
func play_sfx(sound_name: String):
	if sfx.has(sound_name) and sfx[sound_name] != null:
		sfx[sound_name].play()

# ---------------- PHYSICS PROCESS ----------------
func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0
		_apply_gravity(delta)
		move_and_slide()
		return
	
	_apply_gravity(delta)
	
	if player:
		var dir = sign(player.global_position.x - global_position.x)
		if dir != 0:
			sprite_pivot.scale.x = dir
			attack_pivot.scale.x = dir
			attack_pivot.position.x = initial_attack_pos.x * dir
			attack_pivot.position.y = initial_attack_pos.y
		
		var dist = global_position.distance_to(player.global_position)
		
		if is_attacking:
			velocity.x = 0
		elif is_waiting:
			velocity.x = 0
			_play_animation("idle")
		elif dist <= attack_range:
			attack()
		else:
			velocity.x = dir * speed
			_play_animation("run")
	else:
		velocity.x = 0
		_play_animation("idle")
	
	move_and_slide()

# ---------------- ATTACK LOGIC ----------------
func attack() -> void:
	is_attacking = true
	has_hit_this_swing = false 
	_play_animation("attack")
	play_sfx("attack")
	
	# Instead of a loop here, we let the Signal handle the hit
	# so it detects the player at the exact right frame.
	attack_collision.disabled = false
	
	await animation.animation_finished
	
	attack_collision.disabled = true
	is_attacking = false
	is_waiting = true
	
	await get_tree().create_timer(attack_cooldown).timeout
	is_waiting = false

# ---------------- DAMAGE SIGNALS ----------------
func _on_attackarea_body_entered(body: Node2D) -> void:
	if not is_dead and not has_hit_this_swing:
		if body.is_in_group("player") and body.has_method("take_hit"):
			has_hit_this_swing = true 
			body.take_hit(attack_damage)

# ---------------- UTILITY / HEALTH ----------------
func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func _play_animation(anim_name: String) -> void:
	if animation.animation != anim_name:
		animation.play(anim_name)

func take_damage(amount: float) -> void:
	if is_dead: return
	health -= amount
	if health_bar:
		health_bar.update_hp(health)
	
	if health <= 0: 
		die()
		return
	
	# 1. THE IMPACT DELAY
	# Zombie "freezes" for 0.1s before showing the hit
	await get_tree().create_timer(0.1).timeout
	if is_dead: return # Safety check
	
	# 2. THE REACTION
	_play_animation("hurt")
	play_sfx("hurt")
	
	# 3. THE SEMI-TRANSPARENT FLASH
	# Color(1,1,1, 0.6) = White at 60% opacity
	_set_flash_color(Color(1, 1, 1, 0.6)) 
	
	var flash_tween = create_tween()
	# Start at 0.7 intensity (not full solid white)
	_set_flash_pct(0.7) 
	# Fade back to 0.0 very quickly (0.07s)
	flash_tween.tween_method(_set_flash_pct, 0.7, 0.0, 0.07)

func die() -> void:
	if is_dead: return
	is_dead = true
	
	# Optional: Red tint on death
	_set_flash_color(Color.RED)
	_set_flash_pct(0.5)
	
	set_collision_layer_value(3, false)
	attack_collision.set_deferred("disabled", true)
	velocity.x = 0
	_play_animation("dead")
	play_sfx("death")
	
	await animation.animation_finished
	await get_tree().create_timer(0.1).timeout
	queue_free()
