extends Control

signal start_game()

@onready var buttons_v_box = %ButtonsVBox

func _ready() -> void:
	
	focus_button()
	

func _onstartButtonPressed():
	
	# Hide main menu
	hide()

	# Call startCountdown in main
	get_tree().get_root().get_node("Main").startCountdown()


func _on_quit_button_pressed() -> void:
	
	get_tree().quit()
	
	
func _on_visibility_changed() -> void:
	
	if visible:
		focus_button()


func focus_button() -> void:
	
	if buttons_v_box:
		var button: Button = buttons_v_box.get_child(0)
		if button is Button:
			button.grab_focus()
