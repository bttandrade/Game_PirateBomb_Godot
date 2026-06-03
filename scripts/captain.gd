extends Character

func _ready() -> void:
	$AudioAttack.stream = load("res://sounds/cap_atta.mp3")
	$AudioHit.stream = load("res://sounds/cap_hit.mp3")
	super._ready()
	attack_hit_frame = 4
