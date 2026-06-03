extends Node

const ITEM_SCENE := preload("res://entities/item.tscn")
const MIN_INTERVAL := 5.0
const MAX_INTERVAL := 15.0
const MAX_ITEMS    := 5

var _spawn_points: Array = []
var _active_items: int   = 0
var _game_world: Node2D

func setup(spawn_points: Array, game_world: Node2D) -> void:
	_spawn_points = spawn_points
	_game_world   = game_world
	_schedule_next()

func _schedule_next() -> void:
	var wait = randf_range(MIN_INTERVAL, MAX_INTERVAL)
	await get_tree().create_timer(wait).timeout
	_spawn_item()

func _spawn_item() -> void:
	if _active_items >= MAX_ITEMS or _spawn_points.is_empty():
		_schedule_next()
		return

	var pos  = _spawn_points.pick_random()
	var item = ITEM_SCENE.instantiate()
	
	item.type = "life" if randf() > 0.5 else "bomb"
	if item.type == "bomb":
		item.position.y = -10	
		item.scale = Vector2(0.5, 0.5)
	item.global_position = pos
	item.collected.connect(_on_item_collected)
	_game_world.add_child(item)
	_active_items += 1
	_schedule_next()

func _on_item_collected(type: String, player: Node) -> void:
	_active_items -= 1
	
	var audio = AudioStreamPlayer.new()
	add_child(audio)
	audio.stream = load("res://sounds/pick.mp3")
	audio.play()
	audio.finished.connect(audio.queue_free)
		
	if type == "life":
		player.collect_life()
	else:
		player.collect_bomb()
