extends Node

const CHARACTERS := [
	preload("res://entities/bald_pirate.tscn"),
	preload("res://entities/big_guy.tscn"),
	preload("res://entities/captain.tscn")
]

var player1_scene: PackedScene
var player2_scene: PackedScene

func _ready() -> void:
	randomize()
	var shuffled = CHARACTERS.duplicate()
	shuffled.shuffle()
	player1_scene = shuffled[0]
	player2_scene = shuffled[1]
