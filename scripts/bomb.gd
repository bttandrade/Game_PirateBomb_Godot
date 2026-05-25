extends RigidBody2D

signal exploded(bomb_position: Vector2)

const FUSE_TIME := 2.0
const EXPLOSION_RADIUS := 80.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var timer := 0.0
var exploding := false

func _ready() -> void:
	anim.play("fuse")
	anim.animation_finished.connect(on_animation_finished)

func _physics_process(delta: float) -> void:
	if exploding:
		return
	timer += delta
	if timer >= FUSE_TIME:
		explode()

func explode() -> void:
	exploding = true
	freeze = true
	anim.play("explode")
	emit_signal("exploded", global_position)
	for player in get_tree().get_nodes_in_group("player"):
		var dist = global_position.distance_to(player.global_position)
		if dist <= EXPLOSION_RADIUS:
			player.take_hit()

func on_animation_finished() -> void:
	if anim.animation == "explode":
		queue_free()
