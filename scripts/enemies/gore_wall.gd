extends StaticBody2D

var was_stunned = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func stunned(stun: bool):
	if was_stunned: return
	if stun:
		was_stunned = true
		$AnimationPlayer.play("fade")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
