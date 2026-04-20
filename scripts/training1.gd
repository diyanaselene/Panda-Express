extends Node2D

@onready var panda           = $World/PandaPlayer
@onready var camera          = $Camera2D
@onready var heart_container = $FixedScreenInputs/HUD/HeartContainer
@onready var score_label     = $FixedScreenInputs/HUD/ScoreLabel
@onready var stat_label      = $FixedScreenInputs/HUD/StatLabel
@onready var coin_label      = $FixedScreenInputs/HUD/CoinLabel
@onready var roll_label      = $FixedScreenInputs/HUD/RollLabel
@onready var max_stat_notice = $FixedScreenInputs/MaxStatNotice
@onready var death_notice    = $FixedScreenInputs/DeathNotice
@onready var spawn_timer     = $SpawnTimer
@onready var pause_button    = $FixedScreenInputs/Buttons/PauseButton
@onready var resume_button   = $FixedScreenInputs/Buttons/ResumeButton

const BARREL_SCENE = preload("res://scenes/barrel.tscn")
const COIN_SCENE   = preload("res://scenes/coin.tscn")

const SCORE_RATE: float         = 60.0
const SCORE_PER_INCREASE: float = 300.0
const MAX_INCREASES: int        = 5
const MIN_SPAWN_INTERVAL: float = 2.5

var score: float            = 0.0
var session_increases: int  = 0
var heart_sprites: Array    = []
var alive: bool             = true
var coins_this_session: int = 0
var coin_timer: float       = 0.0
var coin_interval: float    = 2.5
var max_reached: bool       = false
var was_already_maxed: bool = false

# Snapshots — restored if player leaves without completing
var stat_snapshot_speed: float = 0.0
var stat_snapshot_jump: float  = 0.0
var stat_snapshot_level: int   = 0
var stat_snapshot_t1: int      = 0

func _ready() -> void:
	resume_button.hide()
	death_notice.hide()
	max_stat_notice.hide()

	was_already_maxed = GameData.training1_increases >= MAX_INCREASES

	# Snapshot stats before training starts
	stat_snapshot_speed = GameData.race1_speed
	stat_snapshot_jump  = GameData.race1_jump_modifier
	stat_snapshot_level = GameData.run_stat_level
	stat_snapshot_t1    = GameData.training1_increases

	# Enter training with current hearts — do NOT restore to full
	panda.health = GameData.permanent_health
	GameData.player_health = GameData.permanent_health
	GameData.max_player_health = GameData.permanent_max_health

	GameData.has_trained_once = true

	if was_already_maxed:
		max_stat_notice.text = "Max Training 1 Reached!"
		max_stat_notice.show()
		spawn_timer.stop()
		max_reached = true
		coin_timer = 99999.0

	heart_sprites = heart_container.get_children()
	_update_hearts()
	_update_score_label()
	_update_stat_label()
	_update_coin_label()
	_update_roll_label()

	panda.jump_modifier = 1.8
	panda.died.connect(_on_player_died)
	panda.rolls_changed.connect(_update_roll_label)

func _process(delta: float) -> void:
	if not alive:
		return

	_update_hearts()
	camera.global_position = panda.global_position
	_update_coin_label()

	if not max_reached:
		score += SCORE_RATE * delta
		_update_score_label()
		_check_stat_increase()

		if spawn_timer.wait_time > MIN_SPAWN_INTERVAL:
			spawn_timer.wait_time = max(
				MIN_SPAWN_INTERVAL,
				spawn_timer.wait_time - 0.005 * delta
			)

		coin_timer -= delta
		if coin_timer <= 0.0:
			_spawn_coin()
			coin_timer = coin_interval

func _spawn_barrel() -> void:
	if not alive or max_reached:
		return

	var barrel = BARREL_SCENE.instantiate()
	var from_right = randi() % 2 == 0

	if from_right:
		barrel.global_position = Vector2(1170, panda.global_position.y)
		barrel.setup(-1.0)
	else:
		barrel.global_position = Vector2(-20, panda.global_position.y)
		barrel.setup(1.0)

	get_tree().current_scene.add_child(barrel)

func _spawn_coin() -> void:
	var coin = COIN_SCENE.instantiate()
	coin.scale = Vector2(3.6, 3.6)
	var random_x = randf_range(30, 1120)
	var random_y = randf_range(330, 545)
	coin.global_position = Vector2(random_x, random_y)
	get_tree().current_scene.add_child(coin)
	coin.body_entered.connect(_on_coin_collected.bind(coin))

func _on_coin_collected(body, coin) -> void:
	if body == panda:
		coin.queue_free()
		coins_this_session += 1
		_update_coin_label()

func _check_stat_increase() -> void:
	if GameData.training1_increases >= MAX_INCREASES:
		return
	var next_threshold = SCORE_PER_INCREASE * (session_increases + 1)
	if score >= next_threshold:
		session_increases += 1
		GameData.training1_increases += 1
		GameData.apply_training1_stat()
		_update_stat_label()
		if GameData.training1_increases >= MAX_INCREASES:
			_on_max_reached()

func _on_max_reached() -> void:
	max_reached = true
	spawn_timer.stop()

	for barrel in get_tree().get_nodes_in_group("barrel"):
		barrel.queue_free()

	# Save coins and save current health permanently
	GameData.add_coins(coins_this_session)
	coins_this_session = 0
	GameData.permanent_health     = GameData.player_health
	GameData.permanent_max_health = GameData.max_player_health

	coin_timer = 99999.0

	max_stat_notice.text = "Max Training 1 Reached!"
	max_stat_notice.show()
	pause_button.hide()
	resume_button.hide()

func _on_player_died() -> void:
	if max_reached:
		return
	alive = false

	if was_already_maxed:
		GameData.add_coins(coins_this_session)
	else:
		# Restore stats snapshot — nothing saved
		GameData.race1_speed         = stat_snapshot_speed
		GameData.race1_jump_modifier = stat_snapshot_jump
		GameData.run_stat_level      = stat_snapshot_level
		GameData.training1_increases = stat_snapshot_t1

	# Restore full permanent health on death
	GameData.player_health     = GameData.permanent_max_health
	GameData.max_player_health = GameData.permanent_max_health
	GameData.permanent_health  = GameData.permanent_max_health

	death_notice.show()
	pause_button.hide()
	resume_button.hide()
	spawn_timer.stop()

func _update_hearts() -> void:
	for i in heart_sprites.size():
		heart_sprites[i].visible = i < GameData.player_health

func _update_score_label() -> void:
	score_label.text = str(int(score))

func _update_stat_label() -> void:
	stat_label.text = "Stats +" + str(GameData.training1_increases) + "/5"

func _update_coin_label() -> void:
	coin_label.text = str(GameData.coins + coins_this_session)

func _update_roll_label() -> void:
	roll_label.text = "Rolls: " + str(GameData.rolls_remaining)

# ── Buttons ───────────────────────────────────────────────

func _on_pause_button_pressed() -> void:
	get_tree().paused = true
	pause_button.hide()
	resume_button.show()

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	pause_button.show()
	resume_button.hide()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	if max_reached or was_already_maxed:
		GameData.permanent_health     = GameData.player_health
		GameData.permanent_max_health = GameData.max_player_health
		GameData.add_coins(coins_this_session)
	else:
		GameData.race1_speed         = stat_snapshot_speed
		GameData.race1_jump_modifier = stat_snapshot_jump
		GameData.run_stat_level      = stat_snapshot_level
		GameData.training1_increases = stat_snapshot_t1
		# Restore permanent health before restarting
		GameData.player_health       = GameData.permanent_health
		GameData.max_player_health   = GameData.permanent_max_health
	get_tree().change_scene_to_file("res://scenes/training1.tscn")

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	if max_reached or was_already_maxed:
		GameData.permanent_health     = GameData.player_health
		GameData.permanent_max_health = GameData.max_player_health
		GameData.add_coins(coins_this_session)
	else:
		GameData.race1_speed         = stat_snapshot_speed
		GameData.race1_jump_modifier = stat_snapshot_jump
		GameData.run_stat_level      = stat_snapshot_level
		GameData.training1_increases = stat_snapshot_t1
		GameData.player_health       = GameData.permanent_health
		GameData.max_player_health   = GameData.permanent_max_health
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
