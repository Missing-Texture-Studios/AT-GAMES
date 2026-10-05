extends Node

const CLICK_SOUND = preload("res://sounds/UI/click.wav")
const BUZZER_SOUND = preload("res://sounds/UI/buzzer.wav")
const HOVER_SCALE := 1.04
const HOVER_DURATION := 0.12
const BASE_SCALE_META := &"hover_base_scale"
const HOVER_TWEEN_META := &"hover_tween"

var click_player: AudioStreamPlayer
var buzzer_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	click_player = _create_player(CLICK_SOUND)
	buzzer_player = _create_player(BUZZER_SOUND)
	get_tree().node_added.connect(_on_node_added)
	var current_scene := get_tree().current_scene
	if current_scene:
		_connect_buttons(current_scene)

func _create_player(sound: AudioStream) -> AudioStreamPlayer:
	var audio_player := AudioStreamPlayer.new()
	audio_player.stream = sound
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
	if not button.pressed.is_connected(_play_click):
		button.pressed.connect(_play_click)
	if button.has_meta(BASE_SCALE_META):
		return
	button.set_meta(BASE_SCALE_META, button.scale)
	button.mouse_entered.connect(_animate_button_hover.bind(button, true))
	button.mouse_exited.connect(_animate_button_hover.bind(button, false))

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

func _play_click() -> void:
	click_player.play()

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var current_scene := get_tree().current_scene
	if current_scene and _clicked_disabled_button(current_scene):
		buzzer_player.play()

func _clicked_disabled_button(node: Node) -> bool:
	if node is BaseButton and node.disabled and node.is_visible_in_tree():
		var button := node as BaseButton
		var local_mouse_position := button.get_global_transform_with_canvas().affine_inverse() * get_viewport().get_mouse_position()
		if button.get_rect().has_point(local_mouse_position):
			return true
	for child in node.get_children():
		if _clicked_disabled_button(child):
			return true
	return false