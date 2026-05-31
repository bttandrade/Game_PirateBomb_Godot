extends Control

func _on_credits_btn_pressed() -> void:
	pass

func _on_quit_btn_pressed() -> void:
	get_tree().quit()

func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_controls_btn_pressed() -> void:
	$Tutorial.visible = true
