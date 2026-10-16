extends Area2D

@export var speed: float = 200.0
@export var damage: float = 10.0

var direction: Vector2 = Vector2.ZERO
var target: Node2D = null

@onready var lifetime: Timer = $Lifetime

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	lifetime.one_shot = true
	lifetime.wait_time = 5.0
	lifetime.timeout.connect(queue_free)
	lifetime.start()
	
func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
func _on_body_entered(body: Node2D) -> void:
	if body != target:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	elif "health" in body:
		body.health -= damage
	queue_free()
