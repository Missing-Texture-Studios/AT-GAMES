extends CharacterBody2D

signal defeated
@onready var hp_bar: ProgressBar = $DeathFade/Control/HPBar

enum STATES {
	IDLE,
	STALKING,
	WINDUP,
	CHARGE,
	RECOVERY,
	ENRAGED,
	DEFEATED
}

const PRESENCE_SOUNDS: Array[AudioStream] = [
	preload("res://sounds/denial/sob1.wav"),
	preload("res://sounds/denial/sob2.wav"),
	preload("res://sounds/denial/sob3.wav"),
	preload("res://sounds/denial/sob4.wav")
]
const WARNING_SOUNDS: Array[AudioStream] = [
	preload("res://sounds/slime/screech.wav"),
	preload("res://sounds/slime/screech2.wav"),
	preload("res://sounds/slime/screech3.wav")
]
const CHARGE_SOUNDS: Array[AudioStream] = [
	preload("res://sounds/shooter/shoot1.wav"),
	preload("res://sounds/shooter/shoot2.wav"),
	preload("res://sounds/shooter/shoot3.wav")
]
const IMPACT_SOUNDS: Array[AudioStream] = [
	preload("res://sounds/denial/growl1.wav"),
	preload("res://sounds/denial/growl2.wav"),
	preload("res://sounds/denial/growl3.wav"),
	preload("res://sounds/denial/growl4.wav")
]

@export_group("Combat")
@export var max_health: float = 120.0
@export var flashlight_damage: float = 18.0
@export var flashlight_damage_interval: float = 0.4
@export var charge_damage: float = 20.0
@export var attack_range: float = 112.0
@export var stalking_range: float = 320.0
@export var windup_duration: float = 0.85
@export var charge_duration: float = 0.55
@export var recovery_duration: float = 2.1
@export var enraged_recovery_duration: float = 1.55
@export var attack_cooldown: float = 0.55
@export var enraged_transition_duration: float = 1.4

@export_group("Movement")
@export var stalking_speed: float = 40.0
@export var enraged_speed: float = 54.0
@export var acceleration: float = 260.0
@export var charge_speed: float = 300.0
@export var enraged_charge_speed: float = 350.0
@export var enraged_threshold: float = 0.5

@export_group("Distortion")
@export var minimum_distortion_strength: float = 1.5
@export var maximum_distortion_strength: float = 7.0
@export var minimum_distortion_speed: float = 8.0
@export var maximum_distortion_speed: float = 22.0
@export var enraged_distortion_bonus: float = 2.0
@export var windup_distortion_bonus: float = 2.5
@export var charge_distortion_bonus: float = 5.0
@export var damage_distortion_spike: float = 3.5
@export var death_distortion_bonus: float = 8.0
@export var distortion_response: float = 7.0

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var charge_hitbox: Area2D = $ChargeHitbox
@onready var charge_hitbox_shape: CollisionShape2D = $ChargeHitbox/CollisionShape2D
@onready var blood: CPUParticles2D = $Blood
@onready var boss_audio: AudioStreamPlayer2D = $BossAudio
@onready var death_fade_overlay: ColorRect = $DeathFade/ColorRect
@onready var phase_light: PointLight2D = $PointLight2D

var health: float = 0.0
var state: STATES = STATES.IDLE
var is_enraged: bool = false
var is_flashlight_exposed: bool = false
var player_in_range: bool = false
var player_damaged_this_charge: bool = false
var state_elapsed: float = 0.0
var attack_cooldown_remaining: float = 0.0
var flashlight_damage_elapsed: float = 0.0
var damage_spike: float = 0.0
var current_distortion_strength: float = 1.5
var current_distortion_speed: float = 8.0
var charge_direction: Vector2 = Vector2.ZERO
var is_defeated: bool = false
var base_sprite_color: Color
var shader_material: ShaderMaterial
var damage_flash_tween: Tween


func _ready() -> void:
	if Level1Puzzle.boss_defeated:
		queue_free()
		return
	if not defeated.is_connected(Level1Puzzle.mark_boss_defeated):
		defeated.connect(Level1Puzzle.mark_boss_defeated)

	health = max_health
	base_sprite_color = animated_sprite.modulate
	animated_sprite.sprite_frames = animated_sprite.sprite_frames.duplicate(true)
	shader_material = animated_sprite.material as ShaderMaterial
	if shader_material != null:
		shader_material = shader_material.duplicate() as ShaderMaterial
		animated_sprite.material = shader_material
		current_distortion_strength = float(shader_material.get_shader_parameter("strength"))
		current_distortion_speed = float(shader_material.get_shader_parameter("speed"))

	var circle_shape := detection_shape.shape as CircleShape2D
	if circle_shape != null:
		circle_shape.radius = stalking_range
	charge_hitbox.monitoring = false
	charge_hitbox_shape.disabled = true
	animated_sprite.play("idle")
	_update_phase_visuals()


func _process(delta: float) -> void:
	hp_bar.value = (health / max_health)*hp_bar.max_value
	if is_defeated:
		return
	state_elapsed += delta
	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)
	_update_flashlight_damage(delta)
	_update_distortion(delta)
	_update_telegraph_visual()


func _physics_process(delta: float) -> void:
	if is_defeated:
		return
	if not is_instance_valid(player):
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	var target_point := _get_player_aim_point()
	var offset := target_point - global_position
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.0 else Vector2.ZERO
	var target_velocity := Vector2.ZERO

	if not is_enraged and health <= max_health * enraged_threshold:
		_enter_enraged()

	match state:
		STATES.IDLE:
			if distance <= stalking_range:
				_change_state(STATES.STALKING)
				target_velocity = direction * _current_stalking_speed()
		STATES.STALKING:
			if distance > stalking_range:
				_change_state(STATES.IDLE)
			elif distance <= attack_range and attack_cooldown_remaining <= 0.0:
				_change_state(STATES.WINDUP)
			else:
				target_velocity = direction * _current_stalking_speed()
		STATES.WINDUP:
			if state_elapsed >= _current_windup_duration():
				charge_direction = direction
				_change_state(STATES.CHARGE)
		STATES.CHARGE:
			target_velocity = charge_direction * _current_charge_speed()
			if state_elapsed >= _current_charge_duration():
				_change_state(STATES.RECOVERY)
		STATES.RECOVERY:
			if state_elapsed >= _current_recovery_duration():
				attack_cooldown_remaining = attack_cooldown
				_change_state(STATES.STALKING)
		STATES.ENRAGED:
			if state_elapsed >= enraged_transition_duration:
				_change_state(STATES.STALKING)
		STATES.DEFEATED:
			return

	if state == STATES.CHARGE:
		velocity = target_velocity
	else:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	_update_animation(direction)
	move_and_slide()


func _change_state(next_state: STATES) -> void:
	if state == next_state:
		return
	var previous_state := state
	state = next_state
	state_elapsed = 0.0

	match state:
		STATES.IDLE:
			velocity = Vector2.ZERO
			animated_sprite.play("idle")
		STATES.STALKING:
			if previous_state == STATES.IDLE:
				_play_random_sound(PRESENCE_SOUNDS)
			player_in_range = true
		STATES.WINDUP:
			# SHADER HOOK: windup distortion builds over the warning interval.
			velocity = Vector2.ZERO
			_update_phase_visuals()
			_play_random_sound(WARNING_SOUNDS)
		STATES.CHARGE:
			# SHADER HOOK: charge uses the maximum temporary distortion overlay.
			player_damaged_this_charge = false
			charge_hitbox_shape.set_deferred("disabled", false)
			charge_hitbox.set_deferred("monitoring", true)
			_update_phase_visuals()
			_play_random_sound(CHARGE_SOUNDS)
		STATES.RECOVERY:
			# SHADER HOOK: reduce attack distortion while retaining the health baseline.
			charge_hitbox.set_deferred("monitoring", false)
			charge_hitbox_shape.set_deferred("disabled", true)
			velocity = Vector2.ZERO
			_update_phase_visuals()
			_play_random_sound(PRESENCE_SOUNDS)
		STATES.ENRAGED:
			# SHADER HOOK: the persistent baseline rises for the enraged phase.
			velocity = Vector2.ZERO
			_update_phase_visuals()
			_play_random_sound(WARNING_SOUNDS)


func _enter_enraged() -> void:
	is_enraged = true
	_change_state(STATES.ENRAGED)


func _current_stalking_speed() -> float:
	return enraged_speed if is_enraged else stalking_speed


func _current_windup_duration() -> float:
	return windup_duration * (0.85 if is_enraged else 1.0)


func _current_charge_duration() -> float:
	return charge_duration * (0.9 if is_enraged else 1.0)


func _current_charge_speed() -> float:
	return enraged_charge_speed if is_enraged else charge_speed


func _current_recovery_duration() -> float:
	return enraged_recovery_duration if is_enraged else recovery_duration


func _update_flashlight_damage(delta: float) -> void:
	if state != STATES.RECOVERY or not is_flashlight_exposed:
		flashlight_damage_elapsed = 0.0
		return

	flashlight_damage_elapsed += delta
	if flashlight_damage_elapsed < flashlight_damage_interval:
		return
	flashlight_damage_elapsed -= flashlight_damage_interval
	_take_flashlight_damage()


func _take_flashlight_damage() -> void:
	if state != STATES.RECOVERY or is_defeated:
		return

	health = maxf(health - flashlight_damage, 0.0)
	# SHADER HOOK: add a brief damage spike over the persistent health progression.
	damage_spike = maxf(damage_spike, damage_distortion_spike)
	_play_damage_feedback()
	_play_random_sound(IMPACT_SOUNDS)
	if health <= 0.0:
		_defeat()


func _play_damage_feedback() -> void:
	if damage_flash_tween != null and damage_flash_tween.is_running():
		damage_flash_tween.kill()
	animated_sprite.self_modulate = Color(1.0, 0.15, 0.15, 1.0)
	damage_flash_tween = create_tween()
	damage_flash_tween.tween_property(animated_sprite, "self_modulate", Color.WHITE, 0.22)
	blood.restart()
	blood.emitting = true


func _update_distortion(delta: float) -> void:
	if shader_material == null:
		return

	var progression := clampf(1.0 - health / maxf(max_health, 1.0), 0.0, 1.0)
	var persistent_strength := lerpf(minimum_distortion_strength, maximum_distortion_strength, progression)
	var persistent_speed := lerpf(minimum_distortion_speed, maximum_distortion_speed, progression)
	if is_enraged:
		persistent_strength += enraged_distortion_bonus

	var temporary_strength := 0.0
	var temporary_speed := 0.0
	match state:
		STATES.IDLE, STATES.STALKING:
			# SHADER HOOK: subtle idle/stalking distortion remains tied to fight progress.
			temporary_strength = 0.15
		STATES.WINDUP:
			# SHADER HOOK: progressively build distortion throughout the readable telegraph.
			var buildup := clampf(state_elapsed / maxf(_current_windup_duration(), 0.01), 0.0, 1.0)
			temporary_strength = windup_distortion_bonus * buildup
			temporary_speed = 5.0 * buildup
		STATES.CHARGE:
			temporary_strength = charge_distortion_bonus
			temporary_speed = 10.0
		STATES.RECOVERY:
			# SHADER HOOK: exposed recovery drops only the temporary attack layer.
			temporary_strength = 0.2
		STATES.ENRAGED:
			temporary_strength = 1.0
		STATES.DEFEATED:
			temporary_strength = death_distortion_bonus

	damage_spike = move_toward(damage_spike, 0.0, delta * 8.0)
	var strength_target := persistent_strength + temporary_strength + damage_spike
	var speed_target := persistent_speed + temporary_speed + damage_spike * 2.0
	var blend := 1.0 - exp(-distortion_response * delta)
	current_distortion_strength = lerpf(current_distortion_strength, strength_target, blend)
	current_distortion_speed = lerpf(current_distortion_speed, speed_target, blend)
	shader_material.set_shader_parameter("strength", current_distortion_strength)
	shader_material.set_shader_parameter("speed", current_distortion_speed)


func _update_telegraph_visual() -> void:
	if state == STATES.WINDUP:
		var pulse := 0.5 + 0.5 * sin(state_elapsed * 18.0)
		animated_sprite.modulate = base_sprite_color.lerp(Color(1.0, 0.28, 0.38, 1.0), pulse * 0.7)
		phase_light.color = Color(1.0, 0.2, 0.12, 1.0)
		phase_light.energy = 1.2 + pulse * 1.4
	elif state == STATES.CHARGE:
		animated_sprite.modulate = Color(1.0, 0.72, 0.72, 1.0)
		phase_light.color = Color(1.0, 0.05, 0.02, 1.0)
		phase_light.energy = 3.2
	elif state == STATES.RECOVERY:
		animated_sprite.modulate = base_sprite_color.lerp(Color(0.5, 1.0, 0.72, 1.0), 0.55)
		phase_light.color = Color(0.35, 1.0, 0.62, 1.0)
		phase_light.energy = 1.6
	elif is_enraged:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		animated_sprite.modulate = base_sprite_color.lerp(Color(1.0, 0.04, 0.02, 1.0), 0.42 + pulse * 0.18)
		phase_light.color = Color(1.0, 0.0, 0.0, 1.0)
		phase_light.energy = 2.5 + pulse * 1.7
	else:
		animated_sprite.modulate = base_sprite_color
		phase_light.color = Color(1.0, 0.08, 0.05, 1.0)
		phase_light.energy = 0.75
	animated_sprite.speed_scale = 1.55 if is_enraged else 1.0


func _update_phase_visuals() -> void:
	match state:
		STATES.IDLE, STATES.STALKING:
			animated_sprite.speed_scale = 1.55 if is_enraged else 1.0
		STATES.WINDUP:
			animated_sprite.speed_scale = 1.0
		STATES.CHARGE:
			animated_sprite.speed_scale = 1.75 if is_enraged else 1.35
		STATES.RECOVERY:
			animated_sprite.speed_scale = 0.85
		STATES.ENRAGED:
			animated_sprite.speed_scale = 1.8


func _update_animation(direction: Vector2) -> void:
	if state == STATES.WINDUP or state == STATES.CHARGE or state == STATES.RECOVERY or state == STATES.ENRAGED:
		if state == STATES.RECOVERY or state == STATES.ENRAGED:
			animated_sprite.play("idle")
			return
	if direction == Vector2.ZERO:
		animated_sprite.play("idle")
	elif absf(direction.x) > absf(direction.y):
		animated_sprite.play("right" if direction.x > 0.0 else "left")
	else:
		animated_sprite.play("down" if direction.y > 0.0 else "up")


func _get_player_aim_point() -> Vector2:
	var hitbox := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hitbox != null:
		return hitbox.global_position
	return player.global_position


func can_be_damaged() -> bool:
	return state == STATES.RECOVERY and not is_defeated


func get_hud_phase_label() -> String:
	var phase_name := "OBSERVANDO"
	match state:
		STATES.IDLE:
			phase_name = "OBSERVANDO"
		STATES.STALKING:
			phase_name = "PERSEGUINDO"
		STATES.WINDUP:
			phase_name = "PREPARANDO INVESTIDA"
		STATES.CHARGE:
			phase_name = "INVESTIDA"
		STATES.RECOVERY:
			phase_name = "RECUPERAÇÃO"
		STATES.ENRAGED:
			phase_name = "FÚRIA DESPERTA"
		STATES.DEFEATED:
			phase_name = "DERROTADA"
	if is_enraged and state not in [STATES.ENRAGED, STATES.DEFEATED]:
		return "FÚRIA · " + phase_name
	return phase_name


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body != player:
		return
	player_in_range = true
	if state == STATES.IDLE:
		_change_state(STATES.STALKING)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body != player:
		return
	player_in_range = false
	if state == STATES.STALKING:
		_change_state(STATES.IDLE)


func _on_charge_hitbox_body_entered(body: Node2D) -> void:
	if body != player or state != STATES.CHARGE or player_damaged_this_charge:
		return
	player_damaged_this_charge = true
	_play_random_sound(IMPACT_SOUNDS)
	if player.has_method("take_damage"):
		player.take_damage(charge_damage)


func stunned(value: bool) -> void:
	is_flashlight_exposed = value
	if not value:
		flashlight_damage_elapsed = 0.0


func _play_random_sound(sounds: Array[AudioStream]) -> void:
	if sounds.is_empty():
		return
	# MANUAL AUDIO: Replace reused clips with dedicated Rising Sorrow cues when available.
	boss_audio.stream = sounds.pick_random()
	boss_audio.play()


func _defeat() -> void:
	if is_defeated:
		return
	is_defeated = true
	state = STATES.DEFEATED
	velocity = Vector2.ZERO
	charge_hitbox.set_deferred("monitoring", false)
	charge_hitbox_shape.set_deferred("disabled", true)
	detection_shape.set_deferred("disabled", true)
	collision_shape.set_deferred("disabled", true)
	blood.restart()
	blood.emitting = true
	# SHADER HOOK: death keeps the accumulated baseline and drives the death distortion layer.
	if shader_material != null:
		shader_material.set_shader_parameter("strength", current_distortion_strength + death_distortion_bonus)
		shader_material.set_shader_parameter("speed", current_distortion_speed + 14.0)
	_play_random_sound(WARNING_SOUNDS)
	defeated.emit()
	var fade_tween := create_tween()
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(death_fade_overlay, "color", Color.WHITE, 2.0)
	await fade_tween.finished
	get_tree().change_scene_to_file("res://scenes/maps/level_1_ending.tscn")
