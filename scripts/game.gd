extends Node2D

@onready var sub_viewport1: SubViewport = $HBoxContainer/SubViewportContainer/SubViewport
@onready var sub_viewport2: SubViewport = $HBoxContainer/SubViewportContainer2/SubViewport
@onready var camera1: Camera2D          = $HBoxContainer/SubViewportContainer/SubViewport/Camera2D
@onready var camera2: Camera2D          = $HBoxContainer/SubViewportContainer2/SubViewport/Camera2D
@onready var game_world: Node2D         = $HBoxContainer/SubViewportContainer/SubViewport/GameWorld

@onready var h1_p1: Sprite2D = $CanvasLayer/HUDP1/Heart1P1
@onready var h2_p1: Sprite2D = $CanvasLayer/HUDP1/Heart2P1
@onready var h3_p1: Sprite2D = $CanvasLayer/HUDP1/Heart3P1

@onready var h1_p2: Sprite2D = $CanvasLayer/HUDP2/Heart1P2
@onready var h2_p2: Sprite2D = $CanvasLayer/HUDP2/Heart2P2
@onready var h3_p2: Sprite2D = $CanvasLayer/HUDP2/Heart3P2
@onready var pause_menu: CanvasLayer = $PauseMenu

var p1
var p2

func _ready() -> void:
	p1 = GameManager.player1_scene.instantiate()
	p1.player_id       = 1
	p1.global_position = game_world.get_node("Spawn1").global_position
	p1.life_changed.connect(_on_p1_life_changed)
	game_world.add_child(p1)

	p2 = GameManager.player2_scene.instantiate()
	p2.player_id       = 2
	p2.global_position = game_world.get_node("Spawn2").global_position
	p2.life_changed.connect(_on_p2_life_changed)
	game_world.add_child(p2)

	sub_viewport2.world_2d = sub_viewport1.world_2d

	var rt1 = RemoteTransform2D.new()
	rt1.remote_path = camera1.get_path()
	p1.add_child(rt1)

	var rt2 = RemoteTransform2D.new()
	rt2.remote_path = camera2.get_path()
	p2.add_child(rt2)

func _on_p1_life_changed(lives: int) -> void:
	h1_p1.visible = lives >= 1
	h2_p1.visible = lives >= 2
	h3_p1.visible = lives >= 3

func _on_p2_life_changed(lives: int) -> void:
	h1_p2.visible = lives >= 1
	h2_p2.visible = lives >= 2
	h3_p2.visible = lives >= 3

func _on_pause_btn_pressed() -> void:
	get_tree().paused = true
	pause_menu.get_node("ColorRect").visible = true

func _on_resume_btn_pressed() -> void:
	get_tree().paused = false
	pause_menu.get_node("ColorRect").visible = false

func _on_return_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_pause") or event.is_action_pressed("p2_pause"):
		if get_tree().paused:
			_on_resume_btn_pressed()
		else:
			_on_pause_btn_pressed()
