extends Area2D
@onready var player = get_tree().get_first_node_in_group("player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body != player: return
	$"../Wrath".stop()
	player.can_move = false
	$"../CanvasLayer/ColorRect/AnimationPlayer".play("fade")
	await $"../CanvasLayer/ColorRect/AnimationPlayer".animation_finished
	Loading.load_scene("res://scenes/maps/level_3.tscn")
