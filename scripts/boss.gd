extends CharacterBody2D

@onready var sprite        = $AnimatedSprite2D
@onready var attack_hitbox = $AttackHitbox

const ATTACK_RANGE: float    = 200.0
const ATTACK_COOLDOWN: float = 2.0

var max_health: int     = 8
var health: int         = 8
var is_alive: bool      = true
var is_attacking: bool  = false
var attack_timer: float = 0.0
var fight_started: bool = false

signal defeated

func _ready() -> void:
	add_to_group("boss")
	sprite.play("idle")
	attack_hitbox.monitoring = false
	attack_hitbox.body_entered.connect(_on_attack_hit)

func start_fight() -> void:
	fight_started = true

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Boss stays still
	velocity = Vector2.ZERO

	if not fight_started:
		move_and_slide()
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		move_and_slide()
		return

	attack_timer -= delta

	var dist = global_position.distance_to(player.global_position)

	if not is_attacking and attack_timer <= 0.0:
		if dist <= ATTACK_RANGE:
			start_attack(player)

	move_and_slide()

func start_attack(_player) -> void:
	is_attacking = true
	attack_timer = ATTACK_COOLDOWN
	sprite.play("attack")

	# Reset monitoring to allow re-detection each attack
	attack_hitbox.monitoring = false
	await get_tree().process_frame
	attack_hitbox.monitoring = true

	await get_tree().create_timer(0.3).timeout
	attack_hitbox.monitoring = false

	await sprite.animation_finished
	is_attacking = false
	if is_alive:
		sprite.play("idle")

func _on_attack_hit(body) -> void:
	if body.is_in_group("player"):
		# No knockback — just deal damage
		body.take_damage()

func take_hit() -> void:
	if not is_alive:
		return
	# Boss is invincible during attack
	if is_attacking:
		return
	health -= 1
	sprite.play("hit")
	await sprite.animation_finished
	if health <= 0:
		die()
	elif is_alive and not is_attacking:
		sprite.play("idle")

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	fight_started = false
	velocity = Vector2.ZERO
	attack_hitbox.monitoring = false
	sprite.play("die")
	await sprite.animation_finished
	# Freeze on last frame
	sprite.pause()
	emit_signal("defeated")
