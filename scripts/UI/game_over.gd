extends Control
@onready var fade_anim: AnimationPlayer = $Fade/fadeAnim


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade_anim.play_backwards("fade")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_quit_button_up() -> void:
	fade_anim.play("fade")
	await fade_anim.animation_finished
	get_tree().paused = false
	Loading.load_scene("res://scenes/UI/menu.tscn")


func _on_retry_button_up() -> void:
	fade_anim.play("fade")
	await fade_anim.animation_finished
	get_tree().paused = false
	Loading.load_scene(SaveData.level)
