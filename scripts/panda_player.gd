extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED := 150.0
const JUMP_VELOCITY := -330.0
const ROLL_SPEED := 300.0
const ROLL_DURATION := 0.5

var is_rolling := false
var roll_timer := 0.0
var is_punching := false
var is_hurt := false
var race_mode := false
var race_speed := 0.0
var health: int = 5
var frozen: bool = false

# Set higher in training scenes for a bigger jump
var jump_modifier: float = 1.0

signal died
signal health_changed
signal rolls_changed

func _ready() -> void:
	add_to_group("player")
	health = GameData.player_health
	$CrownSprite.visible = GameData.crown_equipped

func _physics_process(delta: float) -> void:
	if frozen:
		velocity.x = 0
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_hurt or is_punching:
		move_and_slide()
		return

	if is_rolling:
		roll_timer -= delta
		if roll_timer <= 0.0:
			is_rolling = false

	if race_mode:
		velocity.x = race_speed
		sprite.flip_h = false

		if Input.is_action_just_pressed("jump") and is_on_floor() and not is_rolling:
			velocity.y = JUMP_VELOCITY * jump_modifier

		if Input.is_action_just_pressed("roll") and is_on_floor() and not is_rolling:
			if GameData.rolls_remaining > 0:
				is_rolling = true
				roll_timer = ROLL_DURATION
				GameData.rolls_remaining -= 1
				emit_signal("rolls_changed")

		if is_rolling:
			velocity.x = ROLL_SPEED

		update_animations()
		move_and_slide()
		return

	# Normal mode (training, boss fight)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_rolling:
		velocity.y = JUMP_VELOCITY * jump_modifier

	if Input.is_action_just_pressed("roll") and is_on_floor() and not is_rolling:
		if GameData.rolls_remaining > 0:
			is_rolling = true
			roll_timer = ROLL_DURATION
			GameData.rolls_remaining -= 1
			emit_signal("rolls_changed")

	if Input.is_action_just_pressed("punch") and is_on_floor() and not is_rolling:
		start_punch()
		move_and_slide()
		return

	if is_rolling:
		var roll_dir = -1.0 if sprite.flip_h else 1.0
		velocity.x = roll_dir * ROLL_SPEED
	else:
		var direction := Input.get_axis("left", "right")
		velocity.x = direction * SPEED
		if direction > 0:
			sprite.flip_h = false
		elif direction < 0:
			sprite.flip_h = true

	update_animations()
	move_and_slide()

func start_punch() -> void:
	is_punching = true
	velocity.x = 0
	sprite.play("punch")
	$PunchHitbox.monitoring = true    
	await sprite.animation_finished
	$PunchHitbox.monitoring = false  
	is_punching = false
	update_animations()

func take_damage() -> void:
	if is_hurt:
		return
	health -= 1
	GameData.player_health = health
	emit_signal("health_changed")
	is_hurt = true
	var dir = -1.0 if sprite.flip_h else 1.0
	velocity = Vector2(-dir * 80, -60)
	if health <= 0:
		sprite.play("died")
		await sprite.animation_finished
		emit_signal("died")
		return
	sprite.play("hurt")
	await sprite.animation_finished
	is_hurt = false

func update_animations() -> void:
	if is_rolling:
		sprite.play("roll")
	elif is_on_floor():
		if abs(velocity.x) > 10:
			sprite.play("run")
		else:
			sprite.play("idle")
	else:
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")
