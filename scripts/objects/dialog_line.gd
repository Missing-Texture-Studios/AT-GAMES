# Representa uma única linha de dialog.
# Cada recurso DialogLine corresponde a uma fala exibida pelo sistema.

class_name DialogLine
extends Resource

enum Presentation { PLAIN, ACTION, QUOTE, THOUGHT }


@export_category("Dialog")

# Índice único usado para identificar esta linha.
# Outros elementos do sistema podem usar este índice
# para pular diretamente para esta linha.
@export var index: int = 0

# Nome do personagem que está falando.
@export var dialog_name: String = ""

# Retrato do personagem que será exibido na caixa de dialog.
# null (padrão) = retrato do jogador. Para esconder o retrato,
# use hide_portrait = true em vez de deixar null.
@export var dialog_portrait: Texture2D

# Quando true, esconde o retrato e/ou o nome.
# Se ambos estiverem escondidos, o texto é centralizado.
@export var hide_portrait: bool = false
@export var hide_name: bool = false

# Texto da fala.
# @export_multiline permite escrever textos maiores
# diretamente no Inspector.
@export_multiline var dialog_text: String = ""
@export var presentation: Presentation = Presentation.PLAIN

# Índice da próxima linha quando o dialog avança normalmente.
# -1 significa que não existe próxima linha e o dialog será fechado.
@export var next_index: int = -1


@export_category("Responses")

# Define se esta linha possui opções de resposta.
@export var has_responses: bool = false

# Primeira opção de resposta.
@export var response_1: DialogResponse

# Segunda opção de resposta.
@export var response_2: DialogResponse

@export var responses: Array[DialogResponse] = []
