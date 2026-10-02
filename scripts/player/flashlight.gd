extends Area2D
@onready var enemy = get_tree().get_first_node_in_group("darkEnemies")
var enemy_in = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body != enemy: return
	if body.has_method("stunned"):
		body.stunned(true)


func _on_body_exited(body: Node2D) -> void:
	if body != enemy: return
	if body.has_method("stunned"):
		body.stunned(false)
