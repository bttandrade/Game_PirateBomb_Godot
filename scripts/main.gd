extends Node2D

@onready var spawn: Marker2D = $PlayerSpawn

func _ready() -> void:
	var player = GameManager.current_character.instantiate()
	player.global_position = spawn.global_position
	add_child(player)
