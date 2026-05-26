extends RigidBody2D

signal exploded(bomb_position: Vector2)

const FUSE_TIME        := 3.0
const EXPLOSION_RADIUS := 80.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _timer     := 0.0
var _exploding := false
var _carried   := false

func _ready() -> void:
	anim.play("fuse")
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if _exploding:
		return
	_timer += delta
	if _timer >= FUSE_TIME:
		_explode()

func pick_up() -> void:
	_carried = true
	freeze   = true

func drop(drop_position: Vector2) -> void:
	_carried        = false
	freeze          = false
	global_position = drop_position

func _explode() -> void:
	_exploding = true
	freeze     = true
	show()
	anim.play("explode")
	emit_signal("exploded", global_position)
	for player in get_tree().get_nodes_in_group("player"):
		var dist = global_position.distance_to(player.global_position)
		if dist <= EXPLOSION_RADIUS:
			player.take_hit(global_position)

func _on_animation_finished() -> void:
	if anim.animation == "explode":
		queue_free()
