extends Node

const CLICK_SOUND = preload("res://sounds/UI/click.wav")
const BUZZER_SOUND = preload("res://sounds/UI/buzzer.wav")
const HOVER_SOUND = preload("res://sounds/UI/hover.wav")

const SFX_BUS := "SFX"
const HOVER_SCALE := 1.04
const HOVER_DURATION := 0.12

const BASE_SCALE_META := &"hover_base_scale"
const HOVER_TWEEN_META := &"hover_tween"
const CUSTOM_DISABLED_META := &"custom_disabled"
const ORIGINAL_FOCUS_META := &"custom_original_focus"

var click_player: AudioStreamPlayer
var buzzer_player: AudioStreamPlayer
var hover_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	click_player = _create_player(CLICK_SOUND)
	buzzer_player = _create_player(BUZZER_SOUND)
	hover_player = _create_player(HOVER_SOUND)

	get_tree().node_added.connect(_on_node_added)

	var current_scene := get_tree().current_scene
	if current_scene:
		_connect_buttons(current_scene)


func _create_player(sound: AudioStream) -> AudioStreamPlayer:
	var audio_player := AudioStreamPlayer.new()
	audio_player.stream = sound
	audio_player.bus = SFX_BUS
	audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(audio_player)
	return audio_player


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node)


func _connect_buttons(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node)

	for child in node.get_children():
		_connect_buttons(child)


func _connect_button(button: BaseButton) -> void:
	if button.has_meta(BASE_SCALE_META):
		return

	button.set_meta(BASE_SCALE_META, button.scale)
	button.set_meta(CUSTOM_DISABLED_META, false)

	if not button.pressed.is_connected(_on_button_pressed.bind(button)):
		button.pressed.connect(_on_button_pressed.bind(button))

	button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_button_mouse_exited.bind(button))


func _on_button_pressed(button: BaseButton) -> void:
	if is_button_disabled(button):
		buzzer_player.play()
		return

	click_player.play()


func _on_button_mouse_entered(button: BaseButton) -> void:
	_play_hover()
	_animate_button_hover(button, true)


func _on_button_mouse_exited(button: BaseButton) -> void:
	_animate_button_hover(button, false)


func _play_hover() -> void:
	if not hover_player.playing:
		hover_player.play()


func _animate_button_hover(button: BaseButton, hovering: bool) -> void:
	if not is_instance_valid(button):
		return

	if button.has_meta(HOVER_TWEEN_META):
		var previous_tween: Tween = button.get_meta(HOVER_TWEEN_META)
		if previous_tween and previous_tween.is_running():
			previous_tween.kill()

	var base_scale: Vector2 = button.get_meta(BASE_SCALE_META)
	var target_scale := base_scale * HOVER_SCALE if hovering else base_scale

	var tween := button.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, HOVER_DURATION)

	button.set_meta(HOVER_TWEEN_META, tween)


func set_button_disabled(button: BaseButton, is_disabled: bool) -> void:
	if not is_instance_valid(button):
		return

	button.set_meta(CUSTOM_DISABLED_META, is_disabled)

	if is_disabled:
		if not button.has_meta(ORIGINAL_FOCUS_META):
			button.set_meta(ORIGINAL_FOCUS_META, button.focus_mode)

		button.focus_mode = Control.FOCUS_NONE
		_apply_disabled_style(button)
	else:
		button.remove_meta(ORIGINAL_FOCUS_META)
		_restore_button_style(button)


func is_button_disabled(button: BaseButton) -> bool:
	return button.get_meta(CUSTOM_DISABLED_META, false)


func _apply_disabled_style(button: BaseButton) -> void:
	# Copy the Disabled style overrides from the button's theme.
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var disabled_style := button.get_theme_stylebox("disabled")
		if disabled_style:
			button.add_theme_stylebox_override(style_name, disabled_style)

	var disabled_font_color := button.get_theme_color("font_disabled_color")
	button.add_theme_color_override("font_color", disabled_font_color)
	button.add_theme_color_override("font_hover_color", disabled_font_color)
	button.add_theme_color_override("font_pressed_color", disabled_font_color)
	button.add_theme_color_override("font_focus_color", disabled_font_color)


func _restore_button_style(button: BaseButton) -> void:
	for style_name in ["normal", "hover", "pressed", "focus"]:
		button.remove_theme_stylebox_override(style_name)

	for color_name in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_focus_color"
	]:
		button.remove_theme_color_override(color_name)

	if button.has_meta(ORIGINAL_FOCUS_META):
		button.focus_mode = button.get_meta(ORIGINAL_FOCUS_META)
