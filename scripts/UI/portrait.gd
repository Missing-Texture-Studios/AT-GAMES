extends AnimatedSprite2D
@export var blink_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_blink_timer_timeout() -> void:
	blink_timer.wait_time = randf_range(3,6)
	play("blink")
