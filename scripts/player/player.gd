# Controla o movimento, animação e interações do jogador.
extends CharacterBody2D


# Referências aos elementos do jogador e à interface de interação.
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_label: Label = $InteractLabel
@onready var dialog_box: Control = $"Camera2D/CanvasLayer/UI/Dialog Box"
@onready var hp_bar: ProgressBar = $Camera2D/CanvasLayer/UI/HPBar
@onready var flashlight_dir: AnimationPlayer = $Flashlight/FlashlightDir
@onready var light_bar: ProgressBar = $Camera2D/CanvasLayer/UI/LightBar
@onready var light_collision: CollisionPolygon2D = $Flashlight/LightArea/CollisionPolygon2D
@onready var flashlight: PointLight2D = $Flashlight
@onready var damage_animation: AnimationPlayer = $DamageAnimationPlayer
@onready var hurt_audio: AudioStreamPlayer2D = $HurtAudio
@onready var step_audio: AudioStreamPlayer2D = $StepAudio
@onready var stam_bar: ProgressBar = $Camera2D/CanvasLayer/UI/StamBar
@export var inventory: Array[InvItem]
@onready var fade_anim: AnimationPlayer = $Camera2D/CanvasLayer/UI/Fade/fadeAnim
@onready var light_click: AudioStreamPlayer2D = $LightClick
@onready var oomph: AudioStreamPlayer2D = $Oomph
@onready var light_hum: AudioStreamPlayer2D = $LightHum

var is_dead := false

@export_category("Start Dialog")

# Define se um dialog deve ser mostrado automaticamente
# após o fade-in inicial da cena.
@export var start_dialog_enabled: bool = false

# Dialog mostrado automaticamente no início da cena.
# Pode ser configurado diretamente no Inspector.
@export var start_dialog: Array[DialogLine]


var flashlight_battery = 100.0


func fadein():
	fade_anim.play("fade")
	
	
func fadeout():
	fade_anim.play_backwards("fade")


func addItem(ItemID: int, Amount: int):
	# 1. Search the inventory to see if an item with this ID already exists
	var existing_item = null
	for item in inventory:
		if item.ItemID == ItemID:
			existing_item = item
			break # Stop looping immediately once found
	
	# 2. If it exists, just add to its amount
	if existing_item != null:
		existing_item.item_amount += Amount
	else:
		# 3. If it doesn't exist, create it and add it to the inventory
		var new_item = InvItem.new()
		new_item.ItemID = ItemID
		new_item.item_amount = Amount
		inventory.append(new_item)


var health = 100.0


const HURT_SOUNDS = [
	preload("res://sounds/player/ouch.wav"),
	preload("res://sounds/player/ouch2.wav"),
	preload("res://sounds/player/ouch3.wav"),
	preload("res://sounds/player/ouch4.wav")
]


# Stamina / sprinting
const STAMINA_MAX := 100.0
var stamina: float = STAMINA_MAX
var exhausted: bool = false

const SPRINT_MULT := 1.8
const EXHAUSTED_MULT := 0.45
const STAM_DEPLETION_RATE := 17.0 # per second while sprinting
const STAM_RECHARGE_RATE := 14.0  # per second when not exhausted
const STAM_SLOW_RECHARGE := 5.0  # per second when exhausted
const STAM_RECOVER_THRESHOLD := 25.0 # stamina needed to leave exhausted state


func take_damage(amount: float) -> void:
	health = max(0.0, health - amount)

	damage_animation.play("damage")
	hurt_audio.stream = HURT_SOUNDS.pick_random()
	hurt_audio.play()

	if health <= 0.0:
		die()


func _on_player_frame_changed() -> void:
	if input_dir_is_walking() and animated_sprite.frame in [0, 2]:
		step_audio.pitch_scale = randf_range(1.0,1.5)
		step_audio.play()


func input_dir_is_walking() -> bool:
	return can_move and velocity != Vector2.ZERO and animated_sprite.animation in ["up", "down", "left", "right"]

func die() -> void:
	if is_dead:
		return

	is_dead = true
	can_move = false
	velocity = Vector2.ZERO
	step_audio.stop()
	light_hum.stop()
	interact_label.visible = false
	set_process(false)
	set_physics_process(false)

	fadein()
	await fade_anim.animation_finished

	get_tree().change_scene_to_file("res://scenes/UI/game_over.tscn")

# Velocidade de movimento do jogador.
const SPEED := 50.0


# Define se o jogador pode se movimentar.
# Fica falso enquanto um dialog estiver aberto.
var can_move: bool = true


# Lista de objetos com os quais o jogador pode interagir atualmente.
var nearby_interactions: Array[ObjectInteraction] = []


func _ready() -> void:
	SaveData.save_progress()
	# Conecta os sinais do Dialog Box aos métodos responsáveis
	# por bloquear e liberar o movimento do jogador.
	dialog_box.dialog_opened.connect(_on_dialog_opened)
	dialog_box.dialog_closed.connect(_on_dialog_closed)
	animated_sprite.frame_changed.connect(_on_player_frame_changed)

	# Inicia o fade-in da cena.
	fadeout()

	# Mostra o dialog inicial somente depois que o fade-in terminar.
	if start_dialog_enabled and not start_dialog.is_empty():
		await fade_anim.animation_finished
		_show_start_dialog()


func _show_start_dialog() -> void:
	# Não faz nada caso o dialog já esteja aberto.
	if dialog_box.dialog_enabled:
		return

	# Abre o dialog configurado no Inspector.
	# "self" é enviado como a origem do dialog,
	# assim como nas interações normais.
	dialog_box.open(start_dialog, self)


func _process(_delta: float) -> void:
	hp_bar.value = health

	# Update stamina UI
	if is_instance_valid(stam_bar):
		stam_bar.value = stamina

	# Remove da lista qualquer objeto que não exista mais na cena.
	_clean_interaction_list()

	if Input.is_action_just_pressed("addCoin"):
		addItem(1,1)
	
	if Input.is_action_just_pressed("light_down") or Input.is_action_just_pressed("light_up") or Input.is_action_just_pressed("light_left") or Input.is_action_just_pressed("light_right") or Input.is_action_just_released("light_down") or Input.is_action_just_released("light_up") or Input.is_action_just_released("light_left") or Input.is_action_just_released("light_right"):
		light_click.play()
		
	var light_dir := Input.get_vector(
		"light_left",
		"light_right",
		"light_up",
		"light_down"
	)

	if light_dir != Vector2.ZERO and flashlight_battery > 0:
		flashlight.visible = true
		flashlight.enabled = true
		if !light_hum.playing: light_hum.play()
		light_collision.disabled = false
		flashlight_battery -= 0.5
	else:
		flashlight.visible = false
		flashlight.enabled = false
		light_hum.stop()
		light_collision.disabled = true
		if flashlight_battery < 100.0: flashlight_battery += 0.1

	light_bar.value = flashlight_battery

	# Procura o objeto de interação mais próximo do jogador.
	var interaction := _get_closest_interaction()

	# Mostra o indicador de interação somente quando:
	# - existe um objeto próximo;
	# - o jogador pode se movimentar.
	interact_label.visible = interaction != null and can_move


func _physics_process(_delta: float) -> void:
	# Enquanto o jogador não pode se mover,
	# sua velocidade é zerada.
	if not can_move:
		velocity = Vector2.ZERO
		animated_sprite.speed_scale = 1.0
		animated_sprite.play("idle")
		return

	# Obtém a direção de movimento através dos inputs configurados.
	var input_dir := Input.get_vector(
		"left",
		"right",
		"up",
		"down"
	)

	# Sprint / stamina logic
	var speed_multiplier := 1.0
	var is_sprinting := Input.is_action_pressed("sprint") and input_dir != Vector2.ZERO

	if is_sprinting and not exhausted and stamina > 0.0:
		# Sprinting: consume stamina and increase speed
		speed_multiplier = SPRINT_MULT
		stamina = max(0.0, stamina - STAM_DEPLETION_RATE * _delta)

		if stamina <= 0.0:
			exhausted = true
	else:
		if exhausted:
			# While exhausted, move slower and recharge slowly
			speed_multiplier = EXHAUSTED_MULT
			stamina = min(STAMINA_MAX, stamina + STAM_SLOW_RECHARGE * _delta)

			if stamina >= STAM_RECOVER_THRESHOLD:
				exhausted = false
		else:
			# Normal (not sprinting): recharge stamina at normal rate
			stamina = min(STAMINA_MAX, stamina + STAM_RECHARGE_RATE * _delta)

	# Speed up the walking animation while sprinting.
	animated_sprite.speed_scale = SPRINT_MULT if is_sprinting else 1.0

	# Aplica a velocidade na direção escolhida com multiplicador
	velocity = input_dir * SPEED * speed_multiplier

	# Atualiza a animação de acordo com a direção do movimento.
	update_animation(input_dir)

	# Move o jogador usando o sistema de física do Godot.
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	# Só continua se o botão de interação tiver sido pressionado.
	if not event.is_action_pressed("interact"):
		return

	# Não permite iniciar uma interação enquanto o jogador
	# estiver impedido de se movimentar.
	if not can_move:
		return

	# Não permite abrir outro dialog enquanto um já estiver ativo.
	if dialog_box.dialog_enabled:
		return

	# Procura o objeto de interação mais próximo.
	var interaction := _get_closest_interaction()

	# Se não houver nenhum objeto próximo, não faz nada.
	if interaction == null:
		return

	# Impede que o mesmo input seja processado por outros nodes.
	get_viewport().set_input_as_handled()

	# Executa a interação do objeto encontrado.
	interaction.interact()


func add_interaction(interaction: ObjectInteraction) -> void:
	# Evita adicionar o mesmo objeto mais de uma vez.
	if interaction in nearby_interactions:
		return

	# Adiciona o objeto à lista de interações disponíveis.
	nearby_interactions.append(interaction)


func remove_interaction(interaction: ObjectInteraction) -> void:
	# Remove o objeto da lista de interações disponíveis.
	nearby_interactions.erase(interaction)


func _clean_interaction_list() -> void:
	# Percorre a lista de trás para frente para poder remover
	# elementos com segurança durante o loop.
	for i in range(nearby_interactions.size() - 1, -1, -1):
		var interaction := nearby_interactions[i]

		# Remove referências a objetos que já foram destruídos
		# ou removidos da cena.
		if not is_instance_valid(interaction):
			nearby_interactions.remove_at(i)


func _get_closest_interaction() -> ObjectInteraction:
	# Se não houver objetos próximos, retorna null.
	if nearby_interactions.is_empty():
		return null

	# Variáveis usadas para armazenar o objeto mais próximo
	# e a distância até ele.
	var closest: ObjectInteraction = null
	var closest_distance := INF

	# Verifica todos os objetos disponíveis para interação.
	for interaction in nearby_interactions:
		var distance := global_position.distance_squared_to(
			interaction.global_position
		)

		# Se este objeto estiver mais perto que o anterior,
		# ele passa a ser o objeto selecionado.
		if distance < closest_distance:
			closest_distance = distance
			closest = interaction

	# Retorna o objeto mais próximo.
	return closest


func update_animation(input_dir: Vector2) -> void:
	var light_dir := Input.get_vector(
		"light_left",
		"light_right",
		"light_up",
		"light_down"
	)

	var facing_dir := light_dir if light_dir != Vector2.ZERO else input_dir

	# When the player is standing still and the flashlight is down, use idle.
	if input_dir == Vector2.ZERO and light_dir != Vector2.ZERO and light_dir.y > 0:
		animated_sprite.play("idle")
		flashlight_dir.play("down")
		return

	# Standing still while aiming in a non-down direction should freeze on the second frame
	# of the walking animation to act like a pose, not a walking cycle.
	if input_dir == Vector2.ZERO:
		if light_dir != Vector2.ZERO:
			facing_dir = light_dir

			if abs(facing_dir.x) > abs(facing_dir.y):
				var anim_name := "right" if facing_dir.x > 0 else "left"
				animated_sprite.play(anim_name)
				animated_sprite.frame = 1
				animated_sprite.stop()
				flashlight_dir.play(anim_name)
				return

			if facing_dir.y < 0:
				animated_sprite.play("up")
				animated_sprite.frame = 1
				animated_sprite.stop()
				flashlight_dir.play("up")
				return

		if light_dir == Vector2.ZERO:
			animated_sprite.play("idle")
			flashlight_dir.play("down")
			return

	# Walking animation follows the current flashlight direction when it is active.
	if abs(facing_dir.x) > abs(facing_dir.y):
		if facing_dir.x > 0:
			animated_sprite.play("right")
			flashlight_dir.play("right")
		else:
			animated_sprite.play("left")
			flashlight_dir.play("left")
	else:
		if facing_dir.y > 0:
			animated_sprite.play("down")
			flashlight_dir.play("down")
		else:
			animated_sprite.play("up")
			flashlight_dir.play("up")


func _on_dialog_opened() -> void:
	# Impede o jogador de se movimentar enquanto o dialog estiver aberto.
	can_move = false

	# Garante que qualquer movimento anterior seja interrompido.
	velocity = Vector2.ZERO


func _on_dialog_closed() -> void:
	# Libera novamente o movimento quando o dialog for fechado.
	can_move = true
