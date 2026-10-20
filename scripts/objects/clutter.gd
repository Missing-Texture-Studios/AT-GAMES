extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func destroy():
	$AudioStreamPlayer2D.pitch_scale = randf_range(0.6,1.2)
	$AudioStreamPlayer2D.play()
	$CPUParticles2D.emitting = true
	await $CPUParticles2D.finished
	queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
