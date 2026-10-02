extends Label
@onready var menu_anim: AnimationPlayer = $"../MenuAnim"
@onready var any_key_anim: AnimationPlayer = $AnyKeyAnim
@onready var title_anim: AnimationPlayer = $"../Title/TitleAnim"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		title_anim.play("move")
		menu_anim.play("move")
		any_key_anim.play("move")
		await any_key_anim.animation_finished
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
