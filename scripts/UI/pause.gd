extends Control
@onready var fade_anim: AnimationPlayer = $Panel/Fade/fadeAnim
@onready var music_slider: HSlider = $Panel/OptionsPanel/MusSlider
@onready var sfx_slider: HSlider = $Panel/OptionsPanel/SFXSlider
@onready var vsync_checkbox: CheckBox = $Panel/OptionsPanel/VSyncCheckBox
@onready var fullscreen_checkbox: CheckBox = $Panel/OptionsPanel/FullscreenCheckBox
@onready var options: Button = $Panel/Options
@onready var opts_anim: AnimationPlayer = $Panel/OptionsPanel/AnimationPlayer
var opts_open = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_slider.set_value_no_signal(Settings.music_volume)
	sfx_slider.set_value_no_signal(Settings.sfx_volume)
	vsync_checkbox.set_pressed_no_signal(Settings.vsync_enabled)
	fullscreen_checkbox.set_pressed_no_signal(Settings.fullscreen_enabled)
	music_slider.value_changed.connect(Settings.set_music_volume)
	sfx_slider.value_changed.connect(Settings.set_sfx_volume)
	vsync_checkbox.toggled.connect(Settings.set_vsync_enabled)
	fullscreen_checkbox.toggled.connect(Settings.set_fullscreen_enabled)

func _on_options_button_up() -> void:
	if opts_open:
		opts_anim.play_backwards("slide")
		opts_open = false
	else:
		opts_anim.play("slide")
		opts_open = true

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
