extends CharacterBody2D

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var muzzle: Marker2D = $Muzzle

@export_group("Movement")

@export var speed: float = 60.0
@export var chase_range: float = 250.0

@export_group("Combat")

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 200.0
@export var projectile_damage: float = 10.0
@export var shoot_interval: float = 1.5

var player_in_shoot_range: bool = false
var player_in_flee_range: bool = false

enum STATES {
	IDLE,
	CHASING,
	SHOOTING,
	FLEEING
}

var state: STATES = STATES.IDLE
func _ready() -> void:
	shoot_timer.wait_time = shoot_interval
	if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
		
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var distance := global_position.distance_to(player.global_position)
	var direction := global_position.direction_to(player.global_position)
	
	# Prioridade 1: fugir se o jogador estiver perto demais.
	if player_in_flee_range:
		state = STATES.FLEEING
		velocity = -direction * speed
		
	# Prioridade 2: atirar se o jogador estiver no alcance.
	elif player_in_shoot_range:
		state = STATES.SHOOTING
		velocity = Vector2.ZERO
		
	# Prioridade 3: perseguir se o jogador estiver longe para atirar.
	elif distance <= chase_range:
		state = STATES.CHASING
		velocity = direction * speed
		
	# Prioridade 4: ficar parado se o jogador estiver longe.
	else:
		state = STATES.IDLE
		velocity = Vector2.ZERO
		
	# O temporizador só funciona enquanto estamos atirando.
	if state == STATES.SHOOTING:
		if shoot_timer.is_stopped():
			shoot_timer.start()
	else:
		shoot_timer.stop()
	_update_animation(direction)
	move_and_slide()
	
func _update_animation(direction: Vector2) -> void:
	# Ajuste o flip conforme a orientação original do seu sprite.
	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0
	match state:
		STATES.IDLE:
			_play_animation("idle")
		STATES.CHASING:
			_play_animation("run")
		STATES.SHOOTING:
			_play_animation("idle")
		STATES.FLEEING:
			_play_animation("run")
			
func _play_animation(animation_name: String) -> void:
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
		
func _on_shoot_timer_timeout() -> void:
	
	
	if state != STATES.SHOOTING:
		return
	if not is_instance_valid(player):
		return
	if projectile_scene == null:
		push_warning("Configure Projectile Scene no Inspector!")
		return
		
	var projectile = projectile_scene.instantiate()
	
	# A posição inicial é o ponto de saída do projétil.
	projectile.global_position = muzzle.global_position
	# A direção é calculada novamente no momento do disparo.
	
	var direction = muzzle.global_position.direction_to(player.global_position)
	
	# Configura o projétil antes de adicioná-lo à cena.
	projectile.direction = direction
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.target = player
	
	get_tree().current_scene.add_child(projectile)
	
func _on_shoot_range_body_entered(body: Node2D) -> void:
	if body == player:
		player_in_shoot_range = true
		
func _on_shoot_range_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_shoot_range = false
		
func _on_flee_range_body_entered(body: Node2D) -> void:
	if body == player:
		player_in_flee_range = true
		
func _on_flee_range_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_flee_range = false
