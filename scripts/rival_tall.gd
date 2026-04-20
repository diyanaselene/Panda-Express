extends CharacterBody2D
 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var raycast: RayCast2D = $RayCast2D
 
const JUMP_VELOCITY := -330.0
var speed: float = 0.0
var racing: bool = false
 
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if racing:
		velocity.x = speed
		if raycast.is_colliding() and is_on_floor():
			velocity.y = JUMP_VELOCITY
	move_and_slide()
	update_animations()
 
func update_animations() -> void:
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0 else "fall")
	elif racing:
		sprite.play("run")
	else:
		sprite.play("idle")
 
func start_race(race_speed: float) -> void:
	speed = race_speed
	racing = true
 
