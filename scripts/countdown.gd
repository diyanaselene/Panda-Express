extends Label
 
signal countdown_finished
 
var count := 3
var timer: Timer
 
func _ready() -> void:
	text = "3"
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.timeout.connect(_on_tick)
	timer.start()
 
func _on_tick() -> void:
	count -= 1
	if count > 0:
		text = str(count)
	elif count == 0:
		text = "GO!"
	else:
		text = ""
		timer.stop()
		emit_signal("countdown_finished")
