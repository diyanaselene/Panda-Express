extends Node2D
 
@onready var panda_slots = [
	$Podium/Panda1st,
	$Podium/Panda2nd,
	$Podium/Panda3rd,
	$Podium/Panda4th,
]
 
@onready var press_space = $HUD/PressSpaceLabel
 
# Matches exact node names from Race1 scene
const SPRITE_FRAMES = {
	"PandaPlayer": preload("res://assets/sprites/frames/panda_frames.tres"),
	"rival_fat":   preload("res://assets/sprites/frames/rival_fat_frames.tres"),
	"rival_short": preload("res://assets/sprites/frames/rival_short_frames.tres"),
	"rival_tall":  preload("res://assets/sprites/frames/rival_tall_frames.tres"),
}
 
var can_continue: bool = false
 
func _ready() -> void:
	press_space.text = "Press SPACE to continue"

	for slot in panda_slots:
		slot.visible = false

	var results = GameData.last_race_results
	print("Race results: ", results)

	for i in min(results.size(), 4):
		var r = results[i]
		var slot = panda_slots[i]

		print("Place ", i + 1, " → ", r["name"])

		if SPRITE_FRAMES.has(r["name"]):
			slot.sprite_frames = SPRITE_FRAMES[r["name"]]
			slot.visible = true
			slot.play("idle")
		else:
			slot.visible = true
			slot.play("idle")

		# Show crown sprite on player's panda if crown is equipped
		if r["is_player"] and GameData.crown_equipped:
			var crown = slot.get_node_or_null("CrownSprite")
			if crown:
				crown.visible = true

	await get_tree().create_timer(1.0).timeout
	can_continue = true
 
	await get_tree().create_timer(1.0).timeout
	can_continue = true
 
func _input(event: InputEvent) -> void:
	if not can_continue:
		return
	if event.is_action_pressed("ui_accept"):
		_continue()
 
func _continue() -> void:
	var go_to_boss = (
		GameData.last_race_id == 2 and
		GameData.race2_best_place >= 1 and
		GameData.race2_best_place <= 2
	)
	if go_to_boss:
		get_tree().change_scene_to_file("res://scenes/boss_fight.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
 
