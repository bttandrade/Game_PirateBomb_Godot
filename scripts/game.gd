extends Node2D

@onready var sub_viewport1: SubViewport = $HBoxContainer/SubViewportContainer/SubViewport
@onready var sub_viewport2: SubViewport = $HBoxContainer/SubViewportContainer2/SubViewport
@onready var camera1: Camera2D          = $HBoxContainer/SubViewportContainer/SubViewport/Camera2D
@onready var camera2: Camera2D          = $HBoxContainer/SubViewportContainer2/SubViewport/Camera2D

@onready var h1_p1: Sprite2D = $CanvasLayer/HUDP1/Heart1P1
@onready var h2_p1: Sprite2D = $CanvasLayer/HUDP1/Heart2P1
@onready var h3_p1: Sprite2D = $CanvasLayer/HUDP1/Heart3P1

@onready var h1_p2: Sprite2D = $CanvasLayer/HUDP2/Heart1P2
@onready var h2_p2: Sprite2D = $CanvasLayer/HUDP2/Heart2P2
@onready var h3_p2: Sprite2D = $CanvasLayer/HUDP2/Heart3P2
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var end_game: CanvasLayer = $EndGame
@onready var item_spawner: Node2D = $ItemSpawner

var p1
var p2
var game_world: Node2D

func _ready() -> void:
	var map = GameManager.map_scene.instantiate()
	$HBoxContainer/SubViewportContainer/SubViewport.add_child(map)
	game_world = map
	set_camera_limits(map)
	
	var spawn_points = []
	for node in game_world.get_node("ItemSpawns").get_children():
		spawn_points.append(node.global_position)

	item_spawner.setup(spawn_points, game_world)
	
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
	if lives <= 0:
		_show_end_game(2)

func _on_p2_life_changed(lives: int) -> void:
	h1_p2.visible = lives >= 1
	h2_p2.visible = lives >= 2
	h3_p2.visible = lives >= 3
	if lives <= 0:
		_show_end_game(1)

func _show_end_game(winner: int) -> void:
	await get_tree().create_timer(1.0).timeout
	
	get_tree().paused = true
	
	end_game.get_node("P1/Victory").visible = winner == 1
	end_game.get_node("P1/Defeat").visible = winner == 2
	end_game.get_node("P2/Victory").visible = winner == 2
	end_game.get_node("P2/Defeat").visible = winner == 1
	end_game.visible = true
	
	await get_tree().create_timer(2.5).timeout
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

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

func set_camera_limits(map):
	var top_limit
	var left_limit
	var right_limit
	var bottom_limit
	
	if map.name == "GameWorld1":
		top_limit = -256
		left_limit = 0
		right_limit = 1920
		bottom_limit = 640
	elif map.name == "GameWorld2":
		top_limit = 0
		left_limit = 0
		right_limit = 1920
		bottom_limit = 896
	else:
		top_limit = -256
		left_limit = 0
		right_limit = 1920
		bottom_limit = 640
	
	camera1.limit_top = top_limit
	camera1.limit_left = left_limit
	camera1.limit_right = right_limit
	camera1.limit_bottom = bottom_limit
	
	camera2.limit_top = top_limit
	camera2.limit_left = left_limit
	camera2.limit_right = right_limit
	camera2.limit_bottom = bottom_limit
	
