extends Node

const CHARACTERS := [
	preload("res://entities/bald_pirate.tscn"),
	preload("res://entities/big_guy.tscn"),
	preload("res://entities/captain.tscn")
]

const MAPS := [
	preload("res://scenes/game_world1.tscn"),
	preload("res://scenes/game_world2.tscn"),
	preload("res://scenes/game_world3.tscn")
]

var player1_scene: PackedScene
var player2_scene: PackedScene
var map_scene: PackedScene

func _ready() -> void:
	randomize()
	var shuffled = CHARACTERS.duplicate()
	shuffled.shuffle()
	player1_scene = shuffled[0]
	player2_scene = shuffled[1]
	
	var shuffled_maps = MAPS.duplicate()
	shuffled_maps.shuffle()
	map_scene = shuffled_maps[0]

func randomize_match() -> void:
	var shuffled_chars = CHARACTERS.duplicate()
	shuffled_chars.shuffle()
	player1_scene = shuffled_chars[0]
	player2_scene = shuffled_chars[1]

	var shuffled_maps = MAPS.duplicate()
	shuffled_maps.shuffle()
	map_scene = shuffled_maps[0]
