extends CharacterBody2D

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var muzzle: Marker2D = $Muzzle
@onready var screech_audio: AudioStreamPlayer2D = $ScreechAudio
@onready var shoot_audio: AudioStreamPlayer2D = $ShootAudio

const SCREECH_SOUNDS: Array[AudioStream] = [
	preload("res://sounds/slime/screech.wav"),
	preload("res://sounds/slime/screech2.wav"),
	preload("res://sounds/slime/screech3.wav")
]
const SHOOT_SOUNDS: Array[AudioStream] = [
	preload("res://sounds/shooter/shoot1.wav"),
	preload("res://sounds/shooter/shoot2.wav"),
	preload("res://sounds/shooter/shoot3.wav")
]

@export_group("Movement")

@export var speed: float = 70.0
@export var acceleration: float = 360.0
@export var stalking_range: float = 320.0
@export var shooting_range: float = 180.0
@export var fleeing_range: float = 90.0
@export var flee_clearance: float = 25.0
@export var flee_speed_multiplier: float = 0.75
@export var flash_fade_duration: float = 3.0

@export_group("Combat")

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 200.0
@export var projectile_damage: float = 10.0
@export var shot_interval: float = 1.5

var has_fired: bool = false
var is_being_flashed: bool = false

enum STATES {
	IDLE,
	STALKING,
	SHOOTING,
	FLEEING
}

var state: STATES = STATES.IDLE

func _ready() -> void:
	add_to_group("darkEnemies")
	shoot_timer.one_shot = false
	shoot_timer.wait_time = shot_interval
	if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	_play_animation("move")

func _process(delta: float) -> void:
	if not is_being_flashed:
		return

	modulate.a = maxf(modulate.a - delta / maxf(flash_fade_duration, 0.01), 0.0)
	if is_zero_approx(modulate.a):
		queue_free()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		shoot_timer.stop()
		move_and_slide()
		return

	var target_point := _get_player_aim_point()
	var distance := global_position.distance_to(target_point)
	var direction := global_position.direction_to(target_point)
	var target_velocity := Vector2.ZERO
	if not _has_line_of_sight(target_point):
		if distance > stalking_range:
			has_fired = false
		state = STATES.IDLE
		shoot_timer.stop()
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		_update_animation(Vector2.ZERO)
		move_and_slide()
		return

	if distance > stalking_range:
		has_fired = false
		state = STATES.IDLE
	elif state == STATES.FLEEING:
		if distance >= fleeing_range + flee_clearance:
			state = STATES.SHOOTING
		else:
			var flee_direction := -direction
			if flee_direction == Vector2.ZERO:
				flee_direction = Vector2.RIGHT
			target_velocity = flee_direction * speed * flee_speed_multiplier
	elif has_fired:
		if distance <= fleeing_range:
			state = STATES.FLEEING
			var flee_direction := -direction
			if flee_direction == Vector2.ZERO:
				flee_direction = Vector2.RIGHT
			target_velocity = flee_direction * speed * flee_speed_multiplier
		else:
			state = STATES.SHOOTING
	elif distance <= shooting_range:
		state = STATES.SHOOTING
	else:
		state = STATES.STALKING
		target_velocity = direction * speed

	if distance <= shooting_range and state != STATES.IDLE:
		if shoot_timer.is_stopped():
			shoot_timer.start()
	else:
		shoot_timer.stop()

	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	_update_animation(direction)
	move_and_slide()

func _update_animation(direction: Vector2) -> void:
	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0
	if state != STATES.SHOOTING or animated_sprite.animation != "shoot":
		_play_animation("move")

func _play_animation(animation_name: String) -> void:
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

func _on_shoot_timer_timeout() -> void:
	if state == STATES.IDLE or state == STATES.STALKING or not is_instance_valid(player):
		return
	var target_point := _get_player_aim_point()
	if global_position.distance_to(target_point) > shooting_range + 12.0:
		return
	if not _has_line_of_sight(target_point):
		return
	if projectile_scene == null:
		push_warning("Configure Projectile Scene no Inspector!")
		return

	var projectile = projectile_scene.instantiate()
	var direction = muzzle.global_position.direction_to(target_point)
	projectile.global_position = muzzle.global_position
	projectile.direction = direction
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.target = player
	get_tree().current_scene.add_child(projectile)
	_play_random_sound(shoot_audio, SHOOT_SOUNDS)
	has_fired = true
	animated_sprite.play("shoot")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "shoot":
		_play_animation("move")

func _get_player_aim_point() -> Vector2:
	var hitbox := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hitbox != null:
		return hitbox.global_position
	return player.global_position

func _has_line_of_sight(target_point: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target_point)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == player

func stunned(value: bool) -> void:
	if value and not is_being_flashed:
		_play_random_sound(screech_audio, SCREECH_SOUNDS)
	is_being_flashed = value

func _play_random_sound(audio_player: AudioStreamPlayer2D, sounds: Array[AudioStream]) -> void:
	audio_player.stream = sounds.pick_random()
	audio_player.play()
