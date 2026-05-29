extends CharacterBody2D

const SPEED           := 200.0
const JUMP_FORCE      := -400.0
const GRAVITY         := 900.0
const KNOCKBACK_FORCE := Vector2(80.0, -200.0)
const BOMB_CARRY_OFFSET := Vector2(0, 20)
const MAX_LIVES       := 3
const DEATH_WAIT      := 1.0
const THROW_FORCE_MIN := 200.0
const THROW_FORCE_MAX := 600.0
const THROW_CHARGE_TIME := 1.5
const PICKUP_RADIUS := 60.0

var _throw_charge := 0.0
enum State { IDLE, RUN, JUMP, FALL, HIT, DEAD, ATTACK }
var current_state: State = State.IDLE

@export var bomb_scene: PackedScene
var _active_bomb:  Node = null
var _carried_bomb: Node = null
var _charging          := false
var _spawn_point       := Vector2.ZERO
var _lives             := MAX_LIVES

@onready var anim:      AnimatedSprite2D = $AnimatedSprite2D
@onready var charge_bar: AnimatedSprite2D = $ChargeBar
@onready var collision:  CollisionShape2D = $CollisionShape2D

@onready var heart1: Sprite2D = $"../CanvasLayer/Hearts/Heart1"
@onready var heart2: Sprite2D = $"../CanvasLayer/Hearts/Heart2"
@onready var heart3: Sprite2D = $"../CanvasLayer/Hearts/Heart3"

func _ready() -> void:
	add_to_group("player")
	_spawn_point = global_position
	charge_bar.hide()
	charge_bar.animation_finished.connect(_on_charge_finished)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD or current_state == State.HIT:
		_apply_gravity(delta)
		move_and_slide()
		return
	_apply_gravity(delta)
	_handle_movement()
	_handle_jump()
	_handle_bomb_charge(delta)
	_handle_attack()
	move_and_slide()
	_update_state()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func _handle_movement() -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_FORCE

func _throw_bomb() -> void:
	var bomb      = _carried_bomb
	_carried_bomb = null
	_active_bomb  = bomb

	var throw_pos = bomb.global_position
	remove_child(bomb)
	get_parent().add_child(bomb)
	bomb.global_position = throw_pos

	var t     := _throw_charge / THROW_CHARGE_TIME
	var force = lerp(THROW_FORCE_MIN, THROW_FORCE_MAX, t)

	var direction := -1.0 if anim.flip_h else 1.0

	bomb.throw(direction, force)
	_throw_charge = 0.0

func _handle_bomb_charge(delta: float) -> void:
	if _active_bomb != null and _carried_bomb == null:
		if Input.is_action_just_pressed("throw_bomb"):
			var dist = global_position.distance_to(_active_bomb.global_position)
			if dist <= PICKUP_RADIUS:
				_pick_up_bomb()
		return

	if _carried_bomb != null:
		if Input.is_action_just_pressed("throw_bomb") and not _charging:
			_charging     = true
			_throw_charge = 0.0
			charge_bar.show()
			charge_bar.play("charge")

		if Input.is_action_pressed("throw_bomb") and _charging:
			_throw_charge = min(_throw_charge + delta, THROW_CHARGE_TIME)

		elif Input.is_action_just_released("throw_bomb") and _charging:
			_charging = false
			charge_bar.stop()
			charge_bar.hide()
			_throw_bomb()
		return

	if Input.is_action_just_pressed("place_bomb") and not _charging:
		_charging = true
		charge_bar.show()
		charge_bar.play("charge")
	elif Input.is_action_just_released("place_bomb") and _charging:
		_cancel_charge()

func _on_charge_finished() -> void:
	if not _charging:
		return
	_charging = false
	charge_bar.hide()

	if _carried_bomb != null:
		_throw_bomb()
	else:
		_place_bomb()

func _cancel_charge() -> void:
	_charging = false
	charge_bar.stop()
	charge_bar.hide()

func _place_bomb() -> void:
	var bomb = bomb_scene.instantiate()
	bomb.global_position = global_position
	bomb.exploded.connect(_on_bomb_exploded)
	get_parent().add_child(bomb)
	_active_bomb = bomb

func _pick_up_bomb() -> void:
	_carried_bomb = _active_bomb
	_active_bomb  = null
	_carried_bomb.z_index = 2
	_carried_bomb.get_parent().remove_child(_carried_bomb)
	add_child(_carried_bomb)
	_carried_bomb.pick_up()
	_carried_bomb.position = BOMB_CARRY_OFFSET

func _drop_bomb() -> void:
	var bomb      = _carried_bomb
	bomb.z_index = -1
	_carried_bomb = null
	_active_bomb  = bomb

	var drop_pos = bomb.global_position
	remove_child(bomb)
	get_parent().add_child(bomb)
	bomb.drop(drop_pos)

	_change_state(_get_new_state())

func _on_bomb_exploded(_pos: Vector2) -> void:
	_active_bomb  = null
	_carried_bomb = null

func take_hit(bomb_position: Vector2) -> void:
	if current_state == State.HIT or current_state == State.DEAD:
		return

	if _carried_bomb != null:
		_drop_bomb()
		_cancel_charge()

	var direction = sign(global_position.x - bomb_position.x)
	if direction == 0:
		direction = 1
	velocity = Vector2(KNOCKBACK_FORCE.x * direction, KNOCKBACK_FORCE.y)

	_lives -= 1
	_update_hearts()

	if _lives <= 0:
		_change_state(State.DEAD)
	else:
		_change_state(State.HIT)

func _update_hearts() -> void:
	match _lives:
		2: heart3.hide()
		1: heart2.hide()
		0: heart1.hide()

func _respawn() -> void:
	_lives = MAX_LIVES
	heart1.show()
	heart2.show()
	heart3.show()
	global_position = _spawn_point
	velocity        = Vector2.ZERO
	_change_state(State.IDLE)

func _update_state() -> void:
	if current_state == State.ATTACK:
		return
	var new_state := _get_new_state()
	if new_state != current_state:
		_change_state(new_state)

func _get_new_state() -> State:
	if not is_on_floor():
		return State.JUMP if velocity.y < 0 else State.FALL
	elif abs(velocity.x) > 0:
		return State.RUN
	else:
		return State.IDLE

func _handle_attack() -> void:
	if Input.is_action_just_pressed("attack") and current_state != State.ATTACK:
		_change_state(State.ATTACK)

func _on_attack_finished() -> void:
	_change_state(_get_new_state())

func _change_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.IDLE: anim.play("idle")
		State.RUN:  anim.play("run")
		State.JUMP: anim.play("jump")
		State.FALL: anim.play("fall")
		State.ATTACK:
			anim.play("attack")
			anim.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)
		State.HIT:
			anim.play("hit")
			anim.animation_finished.connect(_on_hit_finished, CONNECT_ONE_SHOT)
		State.DEAD:
			anim.play("dead")
			anim.animation_finished.connect(_on_dead_finished, CONNECT_ONE_SHOT)

func _on_hit_finished() -> void:
	if not is_on_floor():
		await _wait_for_floor()
	_change_state(_get_new_state())

func _on_dead_finished() -> void:
	velocity.x = 0
	await get_tree().create_timer(DEATH_WAIT).timeout
	_respawn()

func _wait_for_floor() -> void:
	while not is_on_floor():
		_apply_gravity(get_physics_process_delta_time())
		move_and_slide()
		await get_tree().process_frame
