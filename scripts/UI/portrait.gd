extends AnimatedSprite2D
@export var blink_timer: Timer

func _ready():
	pass

func _process(_delta):
	offset = Vector2(0.0,0.0)

func _on_blink_timer_timeout() -> void:
	blink_timer.wait_time = randf_range(3,6)
	play("blink")
