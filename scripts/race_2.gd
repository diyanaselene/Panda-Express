extends Node2D

@onready var panda           = $World/PandaPlayer
@onready var rival_tall      = $World/Rivals/rival_tall
@onready var rival_fat       = $World/Rivals/rival_fat
@onready var rival_short     = $World/Rivals/rival_short
@onready var finish_line     = $World/FinishLine
@onready var camera          = $Camera2D
@onready var countdown       = $FixedScreenInputs/CountdownLabel
@onready var heart_container = $FixedScreenInputs/HUD/HeartContainer
@onready var coin_label      = $FixedScreenInputs/HUD/CoinLabel
@onready var roll_label      = $FixedScreenInputs/HUD/RollLabel
@onready var pause_button    = $FixedScreenInputs/Buttons/PauseButton
@onready var resume_button   = $FixedScreenInputs/Buttons/ResumeButton

const PAST_CAMERA_X: float = 3776.0

var rivals: Array = []
var finish_order: Array = []
var race_active: bool = false
var coins_this_race: int = 0
var heart_sprites: Array = []
var panda_finished: bool = false
var ending: bool = false

func _ready() -> void:
	GameData.last_race_results = []
	GameData.last_race_id = 2

	# Use permanent health for race
	GameData.player_health     = GameData.permanent_health
	GameData.max_player_health = GameData.permanent_max_health

	rivals = [rival_tall, rival_fat, rival_short]
	panda.frozen = true
	panda.race_mode = false
	panda.race_speed = GameData.race2_speed
	panda.health = GameData.permanent_health
	resume_button.hide()

	countdown.countdown_finished.connect(_on_countdown_finished)
	finish_line.body_entered.connect(_on_finish_line_body_entered)

	for coin in $World/Coins.get_children():
		coin.body_entered.connect(_on_coin_collected.bind(coin))

	heart_sprites = heart_container.get_children()
	_update_hearts()
	_update_coin_label()
	_update_roll_label()

	panda.rolls_changed.connect(_update_roll_label)

func _process(_delta: float) -> void:
	if not panda_finished:
		camera.global_position = panda.global_position
	if panda_finished and not ending:
		if panda.global_position.x >= PAST_CAMERA_X:
			ending = true
			_end_race()

func _on_countdown_finished() -> void:
	panda.frozen = false
	race_active = true
	panda.race_mode = true
	panda.race_speed    = GameData.race2_speed
	panda.jump_modifier = GameData.race2_jump_modifier
	rival_tall.start_race(GameData.opponent_speeds[0])
	rival_fat.start_race(GameData.opponent_speeds[1])
	rival_short.start_race(GameData.opponent_speeds[2])

func _on_finish_line_body_entered(body) -> void:
	print("Finish line hit by: ", body.name, " race_active: ", race_active)
	if not race_active or body in finish_order:
		print("Skipping: ", body.name)
		return
	finish_order.append(body)
	print("Current finish order: ", finish_order.size(), " racers")
	if body == panda:
		camera.position_smoothing_enabled = false
		panda_finished = true

func _end_race() -> void:
	if not race_active:
		return
	race_active = false

	var finish_x = finish_line.global_position.x
	var unfinished = []
	for r in rivals:
		if r not in finish_order:
			unfinished.append(r)
	if panda not in finish_order:
		unfinished.append(panda)
	unfinished.sort_custom(func(a, b):
		return abs(a.global_position.x - finish_x) < abs(b.global_position.x - finish_x))
	for r in unfinished:
		finish_order.append(r)

	print("Finish order:")
	var results = []
	var player_place = 4
	for i in finish_order.size():
		var is_player = (finish_order[i] == panda)
		print(i, " → ", finish_order[i].name)
		results.append({
			"name": finish_order[i].name,
			"place": i + 1,
			"is_player": is_player
		})
		if is_player:
			player_place = i + 1

	GameData.add_coins(coins_this_race)
	GameData.record_race_result(player_place, 2)
	GameData.last_race_results = results

	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/results.tscn")

func _on_coin_collected(body, coin) -> void:
	if body == panda:
		coin.queue_free()
		coins_this_race += 1
		_update_coin_label()

func _update_hearts() -> void:
	for i in heart_sprites.size():
		heart_sprites[i].visible = i < GameData.player_health

func _update_coin_label() -> void:
	coin_label.text = str(GameData.coins + coins_this_race)

func _update_roll_label() -> void:
	roll_label.text = "Rolls: " + str(GameData.rolls_remaining)

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
	get_tree().change_scene_to_file("res://scenes/race2.tscn")

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
