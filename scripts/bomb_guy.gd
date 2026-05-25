extends CharacterBody2D

const SPEED := 200.0
const JUMP_FORCE := -400.0
const GRAVITY := 900.0

enum State { IDLE, RUN, JUMP, FALL, HIT }
var current_state: State = State.IDLE

@export var bomb_scene: PackedScene

var active_bomb: Node = null
var charging = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var charge_bar: AnimatedSprite2D = $ChargeBar

func _ready() -> void:
	add_to_group("player")
	charge_bar.hide()
	charge_bar.animation_finished.connect(on_charge_finished)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	movement()
	jump()
	bomb_charge(delta)
	move_and_slide()
	update_state()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func movement() -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_FORCE

func bomb_charge(_delta: float) -> void:
	if active_bomb != null:
		return

	if Input.is_action_just_pressed("place_bomb") and not charging:
		charging = true
		charge_bar.show()
		charge_bar.play("charge")

	elif Input.is_action_just_released("place_bomb") and charging:
		cancel_charge()

func on_charge_finished() -> void:
	if not charging:
		return
	charging = false
	charge_bar.hide()
	place_bomb()

func cancel_charge() -> void:
	charging = false
	charge_bar.stop()
	charge_bar.hide()

func place_bomb() -> void:
	var bomb = bomb_scene.instantiate()
	bomb.global_position = global_position
	bomb.exploded.connect(on_bomb_exploded)
	get_parent().add_child(bomb)
	active_bomb = bomb

func on_bomb_exploded(_pos: Vector2) -> void:
	active_bomb = null

func take_hit() -> void:
	change_state(State.HIT)

func update_state() -> void:
	if current_state == State.HIT:
		return
	var new_state := get_new_state()
	if new_state != current_state:
		change_state(new_state)

func get_new_state() -> State:
	if not is_on_floor():
		return State.JUMP if velocity.y < 0 else State.FALL
	elif abs(velocity.x) > 0:
		return State.RUN
	else:
		return State.IDLE

func change_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.IDLE: anim.play("idle")
		State.RUN:  anim.play("run")
		State.JUMP: anim.play("jump")
		State.FALL: anim.play("fall")
		State.HIT:
			anim.play("hit")
			anim.animation_finished.connect(on_hit_finished, CONNECT_ONE_SHOT)

func on_hit_finished() -> void:
	change_state(get_new_state())
