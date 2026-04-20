extends RigidBody2D
 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
 
var direction: float = -1.0
var speed: float = 150.0
var lifetime: float = 10.0
 
func _ready() -> void:
	if speed > 0.0:
		# Rolling — play rolling animation
		sprite.play("rolling")
		# Flip sprite if rolling right
		sprite.flip_h = direction > 0
		linear_velocity = Vector2(speed * direction, 0)
	else:
		# Falling — play falling animation
		sprite.play("falling")
 
func setup(dir: float, spd: float = 150.0) -> void:
	direction = dir
	speed = spd
 
func _physics_process(_delta: float) -> void:
	# Only control horizontal velocity when rolling
	# When falling let gravity handle everything
	if speed > 0.0:
		linear_velocity.x = speed * direction
 
func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return

	# Destroy when reaching ground Y position
	if global_position.y >= 580:
		queue_free()
		return

	# Destroy if barely moving — means it landed
	if linear_velocity.length() < 5.0 and global_position.y > 400:
		queue_free()
 
func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.take_damage()
		queue_free()
