extends Node

const CHARACTERS := [
	preload("res://entities/bald_pirate.tscn"),
	preload("res://entities/big_guy.tscn"),
	preload("res://entities/captain.tscn")
]

var current_character: PackedScene

func _ready() -> void:
	randomize()
	current_character = CHARACTERS[randi() % CHARACTERS.size()]
