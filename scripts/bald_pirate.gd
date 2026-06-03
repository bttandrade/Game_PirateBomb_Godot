extends Character

func _ready() -> void:
	$AudioAttack.stream = load("res://sounds/bald_atta.mp3")
	$AudioHit.stream = load("res://sounds/bald_hit.mp3")
	super._ready()
	attack_hit_frame = 4
