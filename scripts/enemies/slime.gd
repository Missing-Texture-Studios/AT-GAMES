extends CharacterBody2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var growl_audio: AudioStreamPlayer2D = $GrowlAudio
@onready var bite_audio: AudioStreamPlayer2D = $BiteAudio
@onready var screech_audio: AudioStreamPlayer2D = $ScreechAudio
@onready var idle_growl_timer: Timer = $IdleGrowlTimer

const GROWL_SOUNDS = [
	preload("res://sounds/slime/growl.wav"),
	preload("res://sounds/slime/growl2.wav"),
	preload("res://sounds/slime/growl3.wav"),
	preload("res://sounds/slime/growl4.wav")
]
const BITE_SOUNDS = [
	preload("res://sounds/slime/bite.wav"),
	preload("res://sounds/slime/bite2.wav"),
	preload("res://sounds/slime/bite3.wav")
]
const SCREECH_SOUNDS = [
	preload("res://sounds/slime/screech.wav"),
	preload("res://sounds/slime/screech2.wav"),
	preload("res://sounds/slime/screech3.wav")
]

@export var speed = 30.0
@export var range = 150.0
@export var damage = 10.0
@export var health = 10.0
var player_inside_hitbox = false
var _stop_chomp = false
var _previous_state = null
var _attack_missed = false

enum STATES {
	IDLE,
	ROAMING,
	ATTACKING,
	STUNNED,
	DEAD
}
var state = STATES.IDLE

func _physics_process(_delta: float) -> void:
	if not player:
		return

	if player.dialog_box and player.dialog_box.dialog_enabled:
		if state != STATES.IDLE:
			state = STATES.IDLE
			_handle_state_change()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _previous_state != state:
		_handle_state_change()
	_previous_state = state

	if state == STATES.DEAD:
		return

	if state == STATES.STUNNED:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance = global_position.distance_to(player.global_position + Vector2(0,40))
	var direction = global_position.direction_to(player.global_position + Vector2(0,40))

	if direction.x > 0:
		animated_sprite.flip_h = true
	elif direction.x < 0:
		animated_sprite.flip_h = false

	if player_inside_hitbox:
		_attack_missed = false
		if state != STATES.ATTACKING:
			state = STATES.ATTACKING
			velocity = Vector2.ZERO
			_stop_chomp = false

		if state == STATES.ATTACKING and animated_sprite.animation != "chomp":
			animated_sprite.play("chomp")
	else:
		if state == STATES.ATTACKING and animated_sprite.animation == "chomp":
			_attack_missed = true
			velocity = Vector2.ZERO
			return
		if state == STATES.ATTACKING:
			# Let the current attack finish before continuing the pursuit.
			velocity = Vector2.ZERO
		else:
			if distance <= range:
				state = STATES.ROAMING
				velocity = velocity.move_toward(direction * speed, speed)
			else:
				state = STATES.IDLE
				velocity = velocity.move_toward(Vector2.ZERO, speed)

	move_and_slide()

func _handle_state_change() -> void:
	if state == STATES.IDLE:
		if idle_growl_timer.is_stopped():
			idle_growl_timer.start(randf_range(4.0, 9.0))
	else:
		idle_growl_timer.stop()

	if state == STATES.STUNNED:
		_stop_chomp = true
		velocity = Vector2.ZERO
		_play_random_sound(screech_audio, SCREECH_SOUNDS)
		if animated_sprite.animation != "ded" or animated_sprite.frame != animated_sprite.sprite_frames.get_frame_count("ded") - 1:
			animated_sprite.play("ded")
		return

	if _previous_state == STATES.STUNNED:
		animated_sprite.play_backwards("ded")
		return

	if state == STATES.ATTACKING and animated_sprite.animation != "chomp":
		_play_random_sound(bite_audio, BITE_SOUNDS)
		animated_sprite.play("chomp")
	elif state != STATES.ATTACKING and animated_sprite.animation == "chomp":
		animated_sprite.play("wiggle")

# Esta função roda AUTOMATICAMENTE toda vez que a animação muda de frame
func _on_animated_sprite_frame_changed() -> void:
	# Verifica se estamos atacando e se chegou no frame correto (10 ou 11, dependendo de onde quer o dano)
	if state == STATES.ATTACKING and animated_sprite.animation == "chomp" and animated_sprite.frame == 10:
		if player_inside_hitbox:
			if player.has_method("take_damage") and player.health>0:
				player.take_damage(damage)
			else:
				player.health -= damage

# Sinais do Hitbox
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == player:
		player_inside_hitbox = true

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body == player:
		player_inside_hitbox = false


func _ready() -> void:
	# Ensure we receive the animation_finished signal even if not connected in the scene
	if not animated_sprite.is_connected("animation_finished", Callable(self, "_on_animated_sprite_animation_finished")):
		animated_sprite.connect("animation_finished", Callable(self, "_on_animated_sprite_animation_finished"))


func _on_animated_sprite_animation_finished() -> void:
	if animated_sprite.animation == "ded":
		if state == STATES.STUNNED:
			animated_sprite.stop()
			animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("ded") - 1
			return
		animated_sprite.play("wiggle")
		return

	if animated_sprite.animation == "chomp":
		if state != STATES.ATTACKING:
			return
		if player_inside_hitbox:
			_play_random_sound(bite_audio, BITE_SOUNDS)
			animated_sprite.play("chomp")
			return
		if _attack_missed:
			_attack_missed = false
			var distance := global_position.distance_to(player.global_position + Vector2(0, 40))
			state = STATES.ROAMING if distance <= range else STATES.IDLE
			_handle_state_change()
			return
		state = STATES.ROAMING if global_position.distance_to(player.global_position + Vector2(0, 40)) <= range else STATES.IDLE
		_handle_state_change()
		return

func stunned(stun: bool):
	if stun:
		state = STATES.STUNNED
	else:
		state = STATES.ROAMING

	# Handle manual looping for the 'chomp' animation and stopping when requested
	if animated_sprite.animation == "chomp":
		if state == STATES.ATTACKING and not _stop_chomp:
			# Replay chomp to loop while still attacking
			animated_sprite.play("chomp")
		else:
			# Stop looping and transition out of attacking state
			if state == STATES.ATTACKING:
				state = STATES.ROAMING
			animated_sprite.play("wiggle")

func _play_random_sound(audio_player: AudioStreamPlayer2D, sounds: Array) -> void:
	audio_player.stream = sounds.pick_random()
	audio_player.play()

func _on_idle_growl_timer_timeout() -> void:
	if state != STATES.IDLE:
		return
	_play_random_sound(growl_audio, GROWL_SOUNDS)
	idle_growl_timer.start(randf_range(4.0, 9.0))
