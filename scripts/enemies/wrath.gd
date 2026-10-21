extends RigidBody2D
@onready var player = get_tree().get_first_node_in_group("player")
@export var speed = 1.0
var is_stopped = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if player.is_dead:
		return
	if not player.can_move or is_stopped:
		linear_velocity = Vector2.ZERO
		return

	linear_velocity.x += speed * delta

func stop():
	speed = 0.0
	is_stopped = true
	linear_velocity = Vector2.ZERO

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
	if body.has_method("destroy"):
		body.destroy()
