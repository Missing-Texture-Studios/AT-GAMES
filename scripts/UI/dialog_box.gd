extends Control

# Sinais emitidos quando o sistema de dialog é aberto ou fechado.
signal dialog_opened
signal dialog_closed

# Referências aos elementos visuais do dialog.
@onready var portrait: TextureRect = $Panel/Portrait
@onready var dialog_name: Label = $"Panel/Dialog Name"
@onready var dialog_text: Label = $"Panel/Dialog Text"

# Referências às duas opções de resposta.
@onready var response_1: Label = $Panel/Response1
@onready var response_2: Label = $Panel/Response2

# Referências aos seletores que indicam qual resposta está selecionada.
@onready var selector_1: TextureRect = $Panel/Response1/Selector
@onready var selector_2: TextureRect = $Panel/Response2/Selector

# Controla as animações de abrir, revelar e fechar o dialog.
@onready var animation_player: AnimationPlayer = $AnimationPlayer


# Indica se o dialog está atualmente aberto.
var dialog_enabled: bool = false

# Lista de linhas que compõem o dialog atual.
var dialog: Array[DialogLine] = []

# Índice da linha atual dentro do array "dialog".
var current_index: int = 0

# Indica qual resposta está selecionada:
# 0 = resposta 1
# 1 = resposta 2
var selected_response: int = 0

# Indica se o texto está atualmente sendo revelado.
var is_revealing: bool = false

# Indica se o jogador pode interagir com o dialog.
var can_interact: bool = false

# Guarda o objeto que abriu o dialog.
# Isso permite que respostas executem métodos nesse objeto.
var dialog_source: Node = null


func _ready() -> void:
	# O dialog começa escondido.
	visible = false

	# As respostas começam escondidas.
	response_1.visible = false
	response_2.visible = false

	# Os seletores também começam escondidos.
	selector_1.visible = false
	selector_2.visible = false


func open(new_dialog: Array[DialogLine], source: Node = null) -> void:
	# Impede que outro dialog seja aberto enquanto um já estiver ativo.
	if dialog_enabled:
		return

	# Não abre um dialog vazio.
	if new_dialog.is_empty():
		return

	# Copia as linhas recebidas para o dialog atual.
	dialog = new_dialog.duplicate()

	# Guarda o objeto que iniciou o dialog.
	dialog_source = source

	# Começa pela primeira linha.
	current_index = 0

	# Seleciona a primeira resposta por padrão.
	selected_response = 0

	# Ativa o dialog, mas ainda não permite interação.
	dialog_enabled = true
	is_revealing = false
	can_interact = false

	# Torna a interface visível.
	visible = true

	# Informa ao player que o dialog foi aberto.
	dialog_opened.emit()

	# Mostra o conteúdo da primeira linha.
	_show_dialog(dialog[current_index])

	# Executa a animação de abertura.
	animation_player.play("Open")
	await animation_player.animation_finished

	# Se o dialog foi fechado durante a animação, não continua.
	if not dialog_enabled:
		return

	# Começa a animação de revelação do texto.
	_start_reveal()


func _show_dialog(line: DialogLine) -> void:
	# Atualiza o nome, texto e retrato usando a linha atual.
	dialog_name.text = line.dialog_name
	dialog_text.text = line.dialog_text
	portrait.texture = line.dialog_portrait

	# Esconde as respostas enquanto a nova linha é carregada.
	response_1.visible = false
	response_2.visible = false

	# Esconde os seletores.
	selector_1.visible = false
	selector_2.visible = false

	# Sempre começa selecionando a primeira resposta.
	selected_response = 0

	# Se a linha possui respostas, atualiza os textos delas.
	if line.has_responses:
		if line.response_1 != null:
			response_1.text = line.response_1.text

		if line.response_2 != null:
			response_2.text = line.response_2.text


func _start_reveal() -> void:
	# Marca que o texto está sendo revelado.
	is_revealing = true

	# O jogador não pode interagir normalmente durante a revelação.
	can_interact = false

	# As respostas permanecem escondidas durante a revelação.
	response_1.visible = false
	response_2.visible = false

	# Os seletores também permanecem escondidos.
	selector_1.visible = false
	selector_2.visible = false

	# Executa a animação de revelação.
	animation_player.play("Reveal")
	await animation_player.animation_finished

	# Se a revelação foi interrompida, não continua daqui.
	if not is_revealing:
		return

	# A revelação terminou normalmente.
	is_revealing = false
	can_interact = true

	# Agora que o texto terminou de aparecer,
	# as respostas podem ser mostradas.
	_show_responses()


func _show_responses() -> void:
	var line := dialog[current_index]

	# Esconde tudo antes de decidir o que deve aparecer.
	response_1.visible = false
	response_2.visible = false

	selector_1.visible = false
	selector_2.visible = false

	# Se a linha não possui respostas, não mostra nenhuma.
	if not line.has_responses:
		return

	# Mostra as duas opções de resposta.
	response_1.visible = true
	response_2.visible = true

	# Atualiza qual das opções está selecionada.
	_update_response_selection()


func _unhandled_input(event: InputEvent) -> void:
	# Ignora qualquer input quando não há dialog aberto.
	if not dialog_enabled:
		return

	# Trata o botão de interação.
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()

		# Durante a revelação, o primeiro interact apenas
		# termina a animação em vez de avançar o dialog.
		if is_revealing:
			_finish_reveal()
			return

		# Não permite interação antes que o dialog esteja pronto.
		if not can_interact:
			return

		var line := dialog[current_index]

		# Se existem respostas, o interact confirma a selecionada.
		if line.has_responses:
			_select_response()
		else:
			# Caso contrário, avança para a próxima linha.
			_next_dialog()

		return

	# Inputs abaixo daqui só funcionam quando o dialog
	# já terminou de revelar o texto.
	if not can_interact:
		return

	var line := dialog[current_index]

	# Se a linha não possui respostas, esquerda/direita não fazem nada.
	if not line.has_responses:
		return

	# Esquerda seleciona a primeira resposta.
	if event.is_action_pressed("left"):
		selected_response = 0
		_update_response_selection()
		get_viewport().set_input_as_handled()

	# Direita seleciona a segunda resposta.
	elif event.is_action_pressed("right"):
		selected_response = 1
		_update_response_selection()
		get_viewport().set_input_as_handled()


func _finish_reveal() -> void:
	# Obtém a animação de revelação.
	var reveal_animation: Animation = animation_player.get_animation("Reveal")

	# Pula a animação diretamente para o final,
	# fazendo o texto aparecer completamente.
	animation_player.seek(reveal_animation.length, true)

	# A revelação terminou.
	is_revealing = false
	can_interact = true

	# Agora as respostas podem aparecer.
	_show_responses()


func _update_response_selection() -> void:
	# Mostra o seletor apenas na resposta atualmente selecionada.
	selector_1.visible = selected_response == 0
	selector_2.visible = selected_response == 1


func _select_response() -> void:
	var line := dialog[current_index]

	var selected: DialogResponse

	if selected_response == 0:
		selected = line.response_1
	else:
		selected = line.response_2

	if selected == null:
		close_dialog()
		return

	# Executa todas as ações configuradas para esta resposta.
	if not selected.actions.is_empty():
		_run_response_actions(selected)

	# Depois das ações, verifica se existe uma linha de destino.
	if selected.target_index >= 0:
		_go_to_index(selected.target_index)
		return

	# Se configurado para fechar, fecha o dialog.
	if selected.close_after_action:
		close_dialog()
		return

	# Caso contrário, continua para a próxima linha.
	_next_dialog()


func _run_response_actions(response: DialogResponse) -> bool:
	if dialog_source == null:
		push_error("Dialog actions failed: dialog_source is null.")
		return false

	for action in response.actions:
		if action == null:
			continue

		var target: Node

		if action.action_node.is_empty():
			target = dialog_source
		else:
			target = dialog_source.get_node_or_null(action.action_node)

		if target == null:
			push_error(
				"Dialog action failed: could not find node '%s' relative to '%s'."
				% [action.action_node, dialog_source.get_path()]
			)
			return false

		if not target.has_method(action.action_method):
			push_error(
				"Dialog action failed: node '%s' does not have method '%s'."
				% [target.get_path(), action.action_method]
			)
			return false

		print(
			"Running dialog action: %s.%s(%s)"
			% [
				target.get_path(),
				action.action_method,
				action.action_parameters
			]
		)

		target.callv(
			action.action_method,
			action.action_parameters
		)

	return true


func _go_to_index(target_index: int) -> void:
	# Procura no array a linha que possui o índice solicitado.
	for i in dialog.size():
		if dialog[i] == null:
			continue

		if dialog[i].index == target_index:
			# Atualiza a posição atual do array.
			current_index = i

			# Mostra a nova linha.
			_show_dialog(dialog[current_index])

			# Começa novamente a revelação do texto.
			_start_reveal()

			return

	# Se o índice não foi encontrado, mostra um erro.
	push_error(
		"Dialog target index %d was not found."
		% target_index
	)

	# Fecha o dialog caso o destino seja inválido.
	close_dialog()


func _next_dialog() -> void:
	var line := dialog[current_index]

	# Um next_index menor que zero significa
	# que não existe próxima linha.
	if line.next_index < 0:
		close_dialog()
		return

	# Vai para a linha indicada pelo next_index.
	_go_to_index(line.next_index)


func close_dialog() -> void:
	# Impede que o fechamento seja executado novamente
	# caso o dialog já esteja fechado.
	if not dialog_enabled:
		return

	# Desativa imediatamente o dialog e as interações.
	dialog_enabled = false
	is_revealing = false
	can_interact = false

	# Esconde as respostas e os seletores.
	response_1.visible = false
	response_2.visible = false

	selector_1.visible = false
	selector_2.visible = false

	# Executa a animação de fechamento da caixa.
	animation_player.play("Close")
	await animation_player.animation_finished

	# Esconde completamente a interface.
	visible = false

	# Limpa os dados do dialog atual.
	dialog.clear()
	dialog_source = null

	# Informa ao player que o dialog foi fechado.
	dialog_closed.emit()
