extends Control

@onready var bar = $Bar

func _ready():
	# Keeps it on top of the zombie sprite
	z_index = 20
	hide()

func _process(_delta):
	# FIX: Control nodes use 'rotation' and 'scale'
	# Setting these to 0 and 1 every frame stops the parent from
	# rotating or flipping the bar.
	
	# 1. Stops rotation
	rotation = -get_parent().rotation
	
	# 2. Stops mirroring/flipping
	# This ensures the bar's scale is always 1, even if the zombie is -1
	var parent_scale = get_parent().scale
	scale = Vector2(1.0 / abs(parent_scale.x), 1.0 / abs(parent_scale.y))

func setup(max_hp: float):
	bar.max_value = max_hp
	bar.value = max_hp

func update_hp(current_hp: float):
	if current_hp < bar.max_value:
		show()
	bar.value = current_hp
	if current_hp <= 0:
		hide()
