extends Node2D

@onready var punch_tutorial = $FixedScreenInputs/PunchTutorialLabel
@onready var panda           = $World/PandaPlayer
@onready var boss            = $World/Boss
@onready var camera          = $Camera2D
@onready var player_hearts   = $FixedScreenInputs/HUD/PlayerHearts
@onready var boss_hearts_hud = $FixedScreenInputs/HUD/BossHearts
@onready var coin_label      = $FixedScreenInputs/HUD/CoinLabel
@onready var roll_label      = $FixedScreenInputs/HUD/RollLabel
@onready var intro_label     = $FixedScreenInputs/IntroLabel
@onready var countdown_label = $FixedScreenInputs/CountdownLabel
@onready var victory_label   = $FixedScreenInputs/VictoryLabel
@onready var defeat_label    = $FixedScreenInputs/DefeatLabel
@onready var quit_button     = $FixedScreenInputs/QuitButton
@onready var end_label = $FixedScreenInputs/EndLabel

var player_heart_sprites: Array = []
var boss_heart_sprites: Array   = []
var fight_over: bool            = false

func _ready() -> void:
	end_label.hide()
	punch_tutorial.hide()
	victory_label.hide()
	defeat_label.hide()
	intro_label.hide()
	countdown_label.hide()
	quit_button.hide()

	# Use permanent health
	GameData.player_health     = GameData.permanent_health
	GameData.max_player_health = GameData.permanent_max_health
	panda.health               = GameData.permanent_health

	# Freeze player until fight starts
	panda.frozen = true

	player_heart_sprites = player_hearts.get_children()
	boss_heart_sprites   = boss_hearts_hud.get_children()

	_update_player_hearts()
	_update_boss_hearts()
	_update_coin_label()
	_update_roll_label()

	# Connect signals
	panda.died.connect(_on_player_died)
	panda.health_changed.connect(_update_player_hearts)
	panda.rolls_changed.connect(_update_roll_label)
	boss.defeated.connect(_on_boss_defeated)
	panda.get_node("PunchHitbox").body_entered.connect(_on_punch_hit)

	# Connect quit button
	quit_button.pressed.connect(_on_quit_pressed)

	# Start intro sequence
	_start_intro()

func _start_intro() -> void:
	intro_label.text = "How dare you take my crown!"
	intro_label.show()
	await get_tree().create_timer(2.5).timeout
	intro_label.hide()

	countdown_label.show()
	countdown_label.text = "3"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "Defend Your Crown!"
	await get_tree().create_timer(1.0).timeout
	countdown_label.hide()

	panda.frozen = false
	boss.start_fight()

	punch_tutorial.show()
	await get_tree().create_timer(3.0).timeout
	punch_tutorial.hide()

func _process(_delta: float) -> void:
	if not fight_over:
		_update_player_hearts()
		_update_boss_hearts()

# ── Combat ────────────────────────────────────────────────

func _on_punch_hit(body) -> void:
	if body == boss:
		boss.take_hit()

# ── Outcome ───────────────────────────────────────────────

func _on_boss_defeated() -> void:
	fight_over = true
	end_label.show()
	victory_label.text = "I guess you get to keep your crown..."
	victory_label.show()
	quit_button.show()

func _on_player_died() -> void:
	fight_over = true
	end_label.show()
	defeat_label.text = "Better luck next time champ..."
	defeat_label.show()
	quit_button.show()

func _on_quit_pressed() -> void:
	get_tree().quit()

# ── HUD ───────────────────────────────────────────────────

func _update_player_hearts() -> void:
	for i in player_heart_sprites.size():
		player_heart_sprites[i].visible = i < GameData.player_health

func _update_boss_hearts() -> void:
	for i in boss_heart_sprites.size():
		boss_heart_sprites[i].visible = i < boss.health

func _update_coin_label() -> void:
	coin_label.text = str(GameData.coins)

func _update_roll_label() -> void:
	roll_label.text = "Rolls: " + str(GameData.rolls_remaining)
