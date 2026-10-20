extends StaticBody2D
@onready var player = get_tree().get_first_node_in_group("player")
@export var speed = 1.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !player.can_move: return
	if !player.is_dead:
		global_position.x += speed


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
	if body.has_method("destroy"):
		body.destroy()
