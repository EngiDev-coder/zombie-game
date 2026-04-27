extends CanvasLayer

@onready var restart_menu = $RestartMenu
@onready var pause_menu = $PauseMenu
@onready var blur_overlay = $BlurOverlay 

static var is_restarting: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# These were the missing functions causing your errors:
	if restart_menu: _setup_initial_state(restart_menu)
	if pause_menu: _setup_initial_state(pause_menu)
	
	_setup_menu_signals()
	_handle_entrance_vibe()

# --- INITIAL SETUP (Fixes your Line 11-13 errors) ---

func _setup_initial_state(menu: Control):
	menu.hide()
	menu.position.y = -800 

func _setup_menu_signals():
	if pause_menu:
		if pause_menu.has_signal("resume_requested"): pause_menu.resume_requested.connect(toggle_pause)
		if pause_menu.has_signal("restart_requested"): pause_menu.restart_requested.connect(_on_restart_game)
	if restart_menu:
		if restart_menu.has_signal("restart_requested"): restart_menu.restart_requested.connect(_on_restart_game)

# --- THE BLUR VIBE LOGIC ---

func _handle_entrance_vibe():
	if not blur_overlay: return
	
	if is_restarting:
		_set_blur(5.0) # Start fully blurry
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.2) 
		# Suddenly snap back to 0 blur
		tween.tween_method(_set_blur, 5.0, 0.0, 0.4)
		is_restarting = false 
	else:
		_set_blur(0.0)

func _set_blur(amount: float):
	if blur_overlay and blur_overlay.material:
		blur_overlay.material.set_shader_parameter("blur_amount", amount)

func _on_restart_game():
	is_restarting = true 
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Smoothly go from clear to blurry
	tween.tween_method(_set_blur, 0.0, 5.0, 0.5)
	
	tween.tween_callback(func(): 
		get_tree().paused = false
		get_tree().reload_current_scene()
	)

# --- MENU ANIMATIONS (The Slam) ---

func show_restart():
	if not is_inside_tree(): return
	get_tree().paused = true
	_slam_animation(restart_menu)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func toggle_pause():
	if not is_inside_tree() or (restart_menu and restart_menu.visible): return
	var is_paused = !get_tree().paused
	get_tree().paused = is_paused
	if is_paused:
		_slam_animation(pause_menu)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_slide_out(pause_menu)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _slam_animation(menu: Control):
	if not menu: return
	menu.position.y = -800
	menu.show()
	var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(menu, "position:y", 0, 0.25)
	
	# Vertical bounce
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu, "position:y", 15, 0.1)
	tween.tween_property(menu, "position:y", 0, 0.1)

func _slide_out(menu: Control):
	if not menu: return
	var up_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	up_tween.tween_property(menu, "position:y", -800, 0.25)
	up_tween.tween_callback(menu.hide)
