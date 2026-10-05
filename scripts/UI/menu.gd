extends Node2D
var opts_open = false
@onready var menu_anim: AnimationPlayer = $CanvasLayer/Control/MenuAnim
@onready var music_slider: HSlider = $CanvasLayer/Control/OptionsPanel/MusSlider
@onready var sfx_slider: HSlider = $CanvasLayer/Control/OptionsPanel/SFXSlider
@onready var vsync_checkbox: CheckBox = $CanvasLayer/Control/OptionsPanel/VSyncCheckBox
@onready var fullscreen_checkbox: CheckBox = $CanvasLayer/Control/OptionsPanel/FullscreenCheckBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menu_anim.play_backwards("fade")
	music_slider.set_value_no_signal(Settings.music_volume)
	sfx_slider.set_value_no_signal(Settings.sfx_volume)
	vsync_checkbox.set_pressed_no_signal(Settings.vsync_enabled)
	fullscreen_checkbox.set_pressed_no_signal(Settings.fullscreen_enabled)
	music_slider.value_changed.connect(Settings.set_music_volume)
	sfx_slider.value_changed.connect(Settings.set_sfx_volume)
	vsync_checkbox.toggled.connect(Settings.set_vsync_enabled)
	fullscreen_checkbox.toggled.connect(Settings.set_fullscreen_enabled)


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


func _on_new_game_button_up() -> void:
	menu_anim.play("fade")
	await menu_anim.animation_finished
	Loading.load_scene("res://scenes/maps/level_1.tscn")
