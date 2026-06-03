extends Area2D

signal collected(type: String, player: Node)

@export var type: String = "life"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim.play(type)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		emit_signal("collected", type, body)
		queue_free()
