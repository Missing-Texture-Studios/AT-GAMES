extends Control
@onready var fade_anim: AnimationPlayer = $Panel/Fade/fadeAnim


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_toggle()

func pause_toggle() -> void:
	if get_tree().paused:
		get_tree().paused = false
		visible = false
	else:
		get_tree().paused = true
		visible = true


func _on_quit_button_up() -> void:
	fade_anim.play("fade")
	await fade_anim.animation_finished
	get_tree().paused = false
	Loading.load_scene("res://scenes/UI/menu.tscn")
