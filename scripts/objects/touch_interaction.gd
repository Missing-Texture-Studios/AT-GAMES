# Representa um objeto do cenário que mostra um dialog ao ser tocado.
class_name TouchDialog
extends StaticBody2D


@export_category("Interaction")

# Lista de linhas de dialog que este objeto irá abrir.
# As linhas podem ser configuradas diretamente no Inspector.
@export var dialog: Array[DialogLine]


# Área usada para detectar quando o jogador toca no objeto.
@onready var interaction_area: Area2D = $Area2D

# Referência ao jogador atualmente utilizado pela cena.
var player: CharacterBody2D

# Impede que o dialog seja acionado mais de uma vez.
var triggered: bool = false


func _ready() -> void:
	# Procura o primeiro node que pertence ao grupo "player".
	player = get_tree().get_first_node_in_group("player")

	# Caso nenhum jogador seja encontrado, mostra um erro
	# e interrompe a configuração deste objeto.
	if player == null:
		push_error(
			"%s could not find a player in the 'player' group."
			% name
		)
		return

	# Conecta o sinal para detectar quando o jogador entra
	# na área de toque.
	interaction_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# Ignora qualquer corpo que não seja o jogador.
	if body != player:
		return

	# Impede que o dialog seja acionado novamente.
	if triggered:
		return

	# Não faz nada caso este objeto não tenha nenhum dialog configurado.
	if dialog.is_empty():
		return

	# Não tenta abrir o dialog enquanto outro já estiver ativo.
	if player.dialog_box.dialog_enabled:
		return

	triggered = true

	# Abre o dialog no Dialog Box do jogador.
	# "self" é enviado como a origem do dialog,
	# permitindo que respostas executem métodos neste objeto.
	player.dialog_box.open(dialog, self)

	# Espera o dialog terminar antes de remover o objeto.
	await player.dialog_box.dialog_closed

	# Remove este objeto da cena.
	queue_free()
