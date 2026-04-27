extends Area2D

@export var speed = 600
@export var direction = Vector2.RIGHT
@export var damage = 10.0
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
func _ready() -> void:
	animation.play("shoot")
	$shoot.play()
	animation.flip_h = direction.x < 0
	# Connect signal correctly in Godot 4
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
