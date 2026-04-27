extends Control

# Signals that the UIManager will listen for
signal resume_requested
signal restart_requested
signal quit_requested

# Connect these functions to your 3 Buttons in the Editor
func _on_resume_button_pressed():
	resume_requested.emit()
	print("hi")

func _on_restart_button_pressed():
	restart_requested.emit()
	print("hi")
func _on_quit_button_pressed():
	quit_requested.emit()
	print("hi")
