extends Node2D

@onready var heart_container  = $HUD/HeartContainer
@onready var coin_label       = $HUD/CoinLabel
@onready var roll_label       = $HUD/RollLabel
@onready var tutorial_label   = $HUD/TutorialLabel

@onready var race_popup       = $RacePopup
@onready var race2_button     = $RacePopup/Race2Button
@onready var race2_lock       = $RacePopup/Race2Lock

@onready var train_popup      = $TrainPopup
@onready var train1_button    = $TrainPopup/Train1Button
@onready var train1_lock      = $TrainPopup/Train1Lock
@onready var train2_button    = $TrainPopup/Train2Button
@onready var train2_lock      = $TrainPopup/Train2Lock

@onready var shop_popup       = $ShopPopup
@onready var shop_coin_label  = $ShopPopup/ShopCoinLabel
@onready var message_label    = $ShopPopup/MessageLabel
@onready var roll_price       = $ShopPopup/PriceLabels/RollPrice
@onready var heart_price      = $ShopPopup/PriceLabels/HeartPrice
@onready var crown_price      = $ShopPopup/PriceLabels/CrownPrice
@onready var roll_button      = $ShopPopup/RollSprite
@onready var heart_button     = $ShopPopup/HeartItem
@onready var crown_button     = $ShopPopup/CrownItem

const COST_ROLL   = 5
const COST_HEART  = 10
const COST_CROWN  = 20
const MAX_ROLLS   = 3
const MAX_HEARTS  = 5

var heart_sprites: Array = []

func _ready() -> void:
	race_popup.hide()
	train_popup.hide()
	shop_popup.hide()
	message_label.hide()
	tutorial_label.hide()

	# Sync with permanent health
	GameData.player_health     = GameData.permanent_health
	GameData.max_player_health = GameData.permanent_max_health

	heart_sprites = heart_container.get_children()
	_update_hearts()
	_update_coins()
	_update_roll_label()
	_update_locks()

	# Show tutorial once
	if not GameData.shown_tutorial:
		GameData.shown_tutorial = true
		tutorial_label.show()
		await get_tree().create_timer(3.0).timeout
		tutorial_label.hide()

func _update_hearts() -> void:
	for i in heart_sprites.size():
		heart_sprites[i].visible = i < GameData.player_health

func _update_coins() -> void:
	coin_label.text = str(GameData.coins)

func _update_roll_label() -> void:
	roll_label.text = "Rolls: " + str(GameData.rolls_remaining)

func _update_locks() -> void:
	var race2_open = GameData.race2_unlocked()
	race2_button.disabled = not race2_open
	race2_lock.visible    = not race2_open

	var t1_open = GameData.training1_unlocked()
	train1_button.disabled = not t1_open
	train1_lock.visible    = not t1_open

	var t2_open = GameData.training2_unlocked()
	train2_button.disabled = not t2_open
	train2_lock.visible    = not t2_open

# ── Main buttons ──────────────────────────────────────────

func _on_race_button_pressed() -> void:
	_update_locks()
	race_popup.show()

func _on_train_button_pressed() -> void:
	_update_locks()
	train_popup.show()

func _on_shop_button_pressed() -> void:
	_open_shop()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

# ── Race popup ────────────────────────────────────────────

func _on_race1_button_pressed() -> void:
	GameData.last_race_id = 1
	get_tree().change_scene_to_file("res://scenes/race1.tscn")

func _on_race2_button_pressed() -> void:
	if not GameData.race2_unlocked():
		return
	GameData.last_race_id = 2
	get_tree().change_scene_to_file("res://scenes/race2.tscn")

func _on_race_close_pressed() -> void:
	race_popup.hide()

# ── Train popup ───────────────────────────────────────────

func _on_train1_button_pressed() -> void:
	if not GameData.training1_unlocked():
		return
	get_tree().change_scene_to_file("res://scenes/training1.tscn")

func _on_train2_button_pressed() -> void:
	if not GameData.training2_unlocked():
		return
	get_tree().change_scene_to_file("res://scenes/training2.tscn")

func _on_train_close_pressed() -> void:
	train_popup.hide()

# ── Shop popup ────────────────────────────────────────────

func _open_shop() -> void:
	message_label.hide()
	# Sync health before opening
	GameData.permanent_max_health = GameData.permanent_health
	_update_shop_labels()
	_update_shop_buttons()
	shop_popup.show()

func _update_shop_labels() -> void:
	shop_coin_label.text = "Coins: " + str(GameData.coins)
	heart_price.text = "MAX" if GameData.permanent_health >= MAX_HEARTS else str(COST_HEART) + " coins"
	heart_price.text = "MAX" if GameData.permanent_max_health >= MAX_HEARTS else str(COST_HEART) + " coins"

	if GameData.owns_crown:
		crown_price.text = "Unequip" if GameData.crown_equipped else "Equip"
	else:
		crown_price.text = str(COST_CROWN) + " coins"

func _update_shop_buttons() -> void:
	roll_button.modulate  = Color(0.4, 0.4, 0.4) if GameData.max_rolls >= MAX_ROLLS else Color.WHITE
	heart_button.modulate = Color(0.4, 0.4, 0.4) if GameData.permanent_health >= MAX_HEARTS else Color.WHITE
	crown_button.modulate = Color.WHITE

func _show_message(text: String) -> void:
	message_label.text = text
	message_label.show()
	await get_tree().create_timer(2.0).timeout
	message_label.hide()

func _on_shop_close_pressed() -> void:
	shop_popup.hide()
	_update_coins()
	_update_hearts()
	_update_roll_label()

func _on_roll_sprite_pressed() -> void:
	if GameData.max_rolls >= MAX_ROLLS:
		_show_message("Max rolls reached!")
		return
	if GameData.coins < COST_ROLL:
		_show_message("Not enough money!")
		return
	GameData.coins -= COST_ROLL
	GameData.max_rolls += 1
	GameData.rolls_remaining = GameData.max_rolls
	_update_shop_labels()
	_update_shop_buttons()
	_update_roll_label()
	_show_message("Extra roll purchased!")

func _on_heart_item_pressed() -> void:
	if GameData.permanent_health >= MAX_HEARTS:
		_show_message("Max hearts reached!")
		return
	if GameData.coins < COST_HEART:
		_show_message("Not enough money!")
		return
	GameData.coins -= COST_HEART
	GameData.permanent_health += 1
	GameData.permanent_max_health = GameData.permanent_health
	GameData.max_player_health = GameData.permanent_health
	GameData.player_health = GameData.permanent_health
	_update_hearts()
	_update_shop_labels()
	_update_shop_buttons()
	_show_message("Extra heart purchased!")

func _on_crown_item_pressed() -> void:
	if not GameData.owns_crown:
		if GameData.coins < COST_CROWN:
			_show_message("Not enough money!")
			return
		GameData.coins -= COST_CROWN
		GameData.owns_crown = true
		GameData.crown_equipped = true
		_update_shop_labels()
		_update_shop_buttons()
		_show_message("Crown purchased and equipped!")
	else:
		GameData.crown_equipped = not GameData.crown_equipped
		_update_shop_labels()
		_show_message("Crown equipped!" if GameData.crown_equipped else "Crown unequipped!")
