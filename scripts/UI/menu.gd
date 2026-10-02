extends Node2D
var opts_open = false
@onready var menu_anim: AnimationPlayer = $CanvasLayer/Control/MenuAnim

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menu_anim.play_backwards("fade")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_options_button_up() -> void:
	if opts_open:
		menu_anim.play_backwards("options")
		opts_open = false
	else:
		menu_anim.play("options")
		opts_open = true


func _on_quit_button_up() -> void:
	menu_anim.play("fade")
	await menu_anim.animation_finished
	get_tree().quit()
