extends Node

# ── Health ────────────────────────────────────────────────
var player_health: int = 5
var max_player_health: int = 5
# Permanent health — only saved when training is completed
var permanent_health: int = 5
var permanent_max_health: int = 5

# ── Race 1 Stats (improved by Training 1) ─────────────────
var race1_speed: float = 100.0
var race1_jump_modifier: float = 1.0
var training1_increases: int = 0

# ── Race 2 Stats (improved by Training 2) ─────────────────
var race2_speed: float = 100.0
var race2_jump_modifier: float = 1.0
var training2_increases: int = 0

# ── Shared stat level tracker ─────────────────────────────
var run_stat_level: int = 0

# ── Rolls ─────────────────────────────────────────────────
var max_rolls: int = 1
var rolls_remaining: int = 1

# ── Training flags ────────────────────────────────────────
var has_trained_once: bool = false

# ── Coins ─────────────────────────────────────────────────
var coins: int = 0

# ── Crown ─────────────────────────────────────────────────
var owns_crown: bool = false
var crown_equipped: bool = false

# ── Race progress ─────────────────────────────────────────
var race1_best_place: int = 0
var race2_best_place: int = 0
var has_raced_once: bool = false
var has_raced_race2_once: bool = false
var last_race_results: Array = []
var last_race_id: int = 1

# ── Tutorial flags ────────────────────────────────────────
var shown_tutorial: bool = false
var shown_race_tutorial: bool = false

# ── Opponent speeds ───────────────────────────────────────
var opponent_speeds: Array = [130.0, 160.0, 145.0]

# ── Ready ─────────────────────────────────────────────────

func _ready() -> void:
	rolls_remaining = max_rolls

# ── Unlock helpers ────────────────────────────────────────

func race2_unlocked() -> bool:
	return race1_best_place >= 1 and race1_best_place <= 2

func training1_unlocked() -> bool:
	return has_raced_once

func training2_unlocked() -> bool:
	return has_raced_race2_once

func training1_maxed() -> bool:
	return training1_increases >= 5

func training2_maxed() -> bool:
	return training2_increases >= 5

# ── Stat increases ────────────────────────────────────────

func apply_training1_stat() -> void:
	run_stat_level += 1
	race1_speed += 8.0
	race1_jump_modifier += 0.1

func apply_training2_stat() -> void:
	run_stat_level += 1
	race2_speed += 8.0
	race2_jump_modifier += 0.1

# ── Coins ─────────────────────────────────────────────────

func add_coins(amount: int) -> void:
	coins += amount

# ── Rolls ─────────────────────────────────────────────────

func reset_rolls_for_race() -> void:
	rolls_remaining = max_rolls

# ── Race results ──────────────────────────────────────────

func record_race_result(place: int, race_id: int) -> void:
	has_raced_once = true
	if race_id == 1:
		if race1_best_place == 0 or place < race1_best_place:
			race1_best_place = place
	elif race_id == 2:
		has_raced_race2_once = true
		if race2_best_place == 0 or place < race2_best_place:
			race2_best_place = place
