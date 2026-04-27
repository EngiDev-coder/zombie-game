extends Control

signal restart_requested
signal quit_requested

func _on_restart_button_pressed():
	restart_requested.emit()

func _on_quit_button_pressed():
	quit_requested.emit()
