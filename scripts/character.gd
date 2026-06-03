extends CharacterBody2D

class_name Character

const SPEED             := 200.0
const JUMP_FORCE        := -400.0
const GRAVITY           := 900.0
const KNOCKBACK_FORCE   := Vector2(80.0, -200.0)
const ATTACK_KNOCKBACK  := Vector2(250.0, -150.0)
const MAX_LIVES         := 3
const PICKUP_RADIUS     := 40.0
const THROW_FORCE_MIN   := 200.0
const THROW_FORCE_MAX   := 600.0
const THROW_CHARGE_TIME := 1.5
const ATTACK_RANGE := 40.0
const MAX_BOMBS := 3

var  attack_hit_frame := 3

enum State { IDLE, RUN, JUMP, FALL, HIT, DEAD, ATTACK }
var current_state: State = State.IDLE

@export var player_id: int = 1
@export var bomb_scene: PackedScene
@export var is_demo: bool = false
@onready var audio_attack: AudioStreamPlayer = $AudioAttack
@onready var audio_hit: AudioStreamPlayer = $AudioHit

var _active_bombs: Array = []
var _carried_bomb: Node = null
var _charging          := false
var _throw_charge      := 0.0
var _spawn_point       := Vector2.ZERO
var _lives             := MAX_LIVES
var _bomb_count := 1

var _input_left:       String
var _input_right:      String
var _input_jump:       String
var _input_place_bomb: String
var _input_throw_bomb: String
var _input_attack:     String

@onready var anim:         AnimatedSprite2D = $AnimatedSprite2D
@onready var charge_bar:   AnimatedSprite2D = $ChargeBar
@onready var collision:    CollisionShape2D = $CollisionShape2D
@onready var atk_hitbox:   Area2D           = $AttackHitbox

signal life_changed(lives: int)

func _ready() -> void:
	add_to_group("player")
	_spawn_point = global_position
	charge_bar.hide()
	charge_bar.animation_finished.connect(_on_charge_finished)
	atk_hitbox.monitoring = false

	var p := "p%d_" % player_id
	_input_left       = p + "left"
	_input_right      = p + "right"
	_input_jump       = p + "jump"
	_input_place_bomb = p + "place_bomb"
	_input_throw_bomb = p + "throw_bomb"
	_input_attack     = p + "attack"

func _physics_process(delta: float) -> void:
	if is_demo:
		_apply_gravity(delta)
		move_and_slide()
		return
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
	var direction := Input.get_axis(_input_left, _input_right)
	if direction != 0:
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func _handle_jump() -> void:
	if Input.is_action_just_pressed(_input_jump) and is_on_floor():
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.stream = load("res://sounds/jump.mp3")
		player.volume_db = -10.0
		player.pitch_scale = 0.8
		player.play()
		player.finished.connect(player.queue_free)
		velocity.y = JUMP_FORCE

func _handle_attack() -> void:
	if Input.is_action_just_pressed(_input_attack) and current_state != State.ATTACK:
		audio_attack.play(0.1)
		_change_state(State.ATTACK)

func _activate_hitbox() -> void:
	var dir := -1.0 if anim.flip_h else 1.0
	atk_hitbox.position.x = abs(atk_hitbox.position.x) * dir

func _check_hitbox_damage() -> void:
	while current_state == State.ATTACK:
		if anim.animation == "attack" and anim.frame == attack_hit_frame:
			var hitbox_global_pos = atk_hitbox.global_position
			for body in get_tree().get_nodes_in_group("player"):
				if body == self:
					continue
				var dist = hitbox_global_pos.distance_to(body.global_position)
				if dist <= ATTACK_RANGE:
					body.take_hit(global_position)
			return
		await get_tree().process_frame

func _on_attack_finished() -> void:
	_change_state(_get_new_state())

func _handle_bomb_charge(delta: float) -> void:
	if current_state == State.ATTACK:
		return

	if _carried_bomb == null and Input.is_action_just_pressed(_input_throw_bomb):
		for bomb in _active_bombs:
			var dist = global_position.distance_to(bomb.global_position)
			if dist <= PICKUP_RADIUS:
				_pick_up_bomb(bomb)
				return

	if _carried_bomb != null:
		if Input.is_action_just_pressed(_input_place_bomb):
			_drop_bomb()
			return

		if Input.is_action_just_pressed(_input_throw_bomb) and not _charging:
			_charging     = true
			_throw_charge = 0.0
			charge_bar.show()
			charge_bar.play("charge")

		if Input.is_action_pressed(_input_throw_bomb) and _charging:
			_throw_charge = min(_throw_charge + delta, THROW_CHARGE_TIME)

		elif Input.is_action_just_released(_input_throw_bomb) and _charging:
			_charging = false
			charge_bar.stop()
			charge_bar.hide()
			_throw_bomb()
			return

	if Input.is_action_just_pressed(_input_place_bomb) and not _charging:
		_charging = true
		charge_bar.show()
		charge_bar.play("charge")
	elif Input.is_action_just_released(_input_place_bomb) and _charging:
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
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.stream = load("res://sounds/fuse.mp3")
		player.play(0.3)
		
		await get_tree().create_timer(1.8).timeout
		player.stop()
		player.stream = load("res://sounds/explosion.mp3")
		player.play()
		player.finished.connect(player.queue_free)

func _cancel_charge() -> void:
	_charging = false
	charge_bar.stop()
	charge_bar.hide()

func _place_bomb() -> void:
	if _bomb_count <= 0:
		return
	_bomb_count -= 1
	var bomb = bomb_scene.instantiate()
	bomb.global_position = global_position
	bomb.exploded.connect(_on_bomb_exploded.bind(bomb))
	get_parent().add_child(bomb)
	_active_bombs.append(bomb)

func _pick_up_bomb(bomb: Node) -> void:
	_carried_bomb = bomb
	_carried_bomb.z_index = 2
	_active_bombs.erase(bomb)
	_carried_bomb.get_parent().remove_child(_carried_bomb)
	add_child(_carried_bomb)
	_carried_bomb.pick_up()
	_carried_bomb.position = Vector2(0, 20)

func _drop_bomb() -> void:
	var bomb      = _carried_bomb
	_carried_bomb = null
	_active_bombs.append(bomb)
	var drop_pos  = bomb.global_position
	bomb.z_index  = -1
	remove_child(bomb)
	get_parent().add_child(bomb)
	bomb.drop(drop_pos)
	_change_state(_get_new_state())

func _throw_bomb() -> void:
	var bomb      = _carried_bomb
	bomb.z_index  = -1
	_carried_bomb = null
	_active_bombs.append(bomb)
	var throw_pos = bomb.global_position
	remove_child(bomb)
	get_parent().add_child(bomb)
	bomb.global_position = throw_pos
	var t         := _throw_charge / THROW_CHARGE_TIME
	var force     = lerp(THROW_FORCE_MIN, THROW_FORCE_MAX, t)
	var direction := -1.0 if anim.flip_h else 1.0
	bomb.throw(direction, force)
	_throw_charge = 0.0

func _on_bomb_exploded(_pos: Vector2, bomb: Node) -> void:
	_active_bombs.erase(bomb)
	_bomb_count += 1
	if _carried_bomb == bomb:
		_carried_bomb = null

func collect_life() -> void:
	if _lives < MAX_LIVES:
		_lives += 1
		_update_hearts()

func collect_bomb() -> void:
	if _bomb_count + _active_bombs.size() < MAX_BOMBS:
		_bomb_count += 1

func take_hit(source_position: Vector2) -> void:
	if current_state == State.HIT or current_state == State.DEAD:
		return
	
	audio_hit.play()
	
	if _carried_bomb != null:
		_drop_bomb()
		_cancel_charge()
	
	var direction = sign(global_position.x - source_position.x)
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
	emit_signal("life_changed", _lives)

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

func _change_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.IDLE:   anim.play("idle")
		State.RUN:    anim.play("run")
		State.JUMP:   anim.play("jump")
		State.FALL:   anim.play("fall")
		State.ATTACK:
			_activate_hitbox()
			_check_hitbox_damage()
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

func _wait_for_floor() -> void:
	while not is_on_floor():
		_apply_gravity(get_physics_process_delta_time())
		move_and_slide()
		await get_tree().process_frame
		
		
