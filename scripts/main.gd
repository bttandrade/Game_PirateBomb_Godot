extends Node2D

@onready var sub_viewport1: SubViewport = $HBoxContainer/SubViewportContainer/SubViewport
@onready var sub_viewport2: SubViewport = $HBoxContainer/SubViewportContainer2/SubViewport
@onready var camera1: Camera2D = $HBoxContainer/SubViewportContainer/SubViewport/Camera2D
@onready var camera2: Camera2D = $HBoxContainer/SubViewportContainer2/SubViewport/Camera2D

@onready var h1_p1: Sprite2D = $CanvasLayer/HUDP1/Heart1P1
@onready var h2_p1: Sprite2D = $CanvasLayer/HUDP1/Heart2P1
@onready var h3_p1: Sprite2D = $CanvasLayer/HUDP1/Heart3P1

@onready var h1_p2: Sprite2D = $CanvasLayer/HUDP2/Heart1P2
@onready var h2_p2: Sprite2D = $CanvasLayer/HUDP2/Heart2P2
@onready var h3_p2: Sprite2D = $CanvasLayer/HUDP2/Heart3P2

@onready var game_world: Node2D = $HBoxContainer/SubViewportContainer/SubViewport/GameWorld

var p1
var p2

func _ready():
	var spawn1 = game_world.get_node("Spawn1")
	var spawn2 = game_world.get_node("Spawn2")

	p1 = GameManager.player1_scene.instantiate()
	p1.player_id = 1
	p1.global_position = spawn1.global_position
	p1.life_changed.connect(_on_p1_life_changed)
	game_world.add_child(p1)

	p2 = GameManager.player2_scene.instantiate()
	p2.player_id = 2
	p2.global_position = spawn2.global_position
	p2.life_changed.connect(_on_p2_life_changed)
	game_world.add_child(p2)
	
	sub_viewport2.world_2d = sub_viewport1.world_2d
	var remote_trasform = RemoteTransform2D.new()
	remote_trasform.remote_path = camera1.get_path()
	p1.add_child(remote_trasform)
	var remote_trasform2 = RemoteTransform2D.new()
	remote_trasform2.remote_path = camera2.get_path()
	p2.add_child(remote_trasform2)

func _on_p1_life_changed(lives: int) -> void:
	h1_p1.visible = lives >= 1
	h2_p1.visible = lives >= 2
	h3_p1.visible = lives >= 3

func _on_p2_life_changed(lives: int) -> void:
	h1_p2.visible = lives >= 1
	h2_p2.visible = lives >= 2
	h3_p2.visible = lives >= 3
