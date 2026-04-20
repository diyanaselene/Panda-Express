extends Area2D
 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
 
func _ready() -> void:
	sprite.play("spin")
