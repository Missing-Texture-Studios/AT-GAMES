extends Control

# Sinais emitidos quando o sistema de dialog é aberto ou fechado.
signal dialog_opened
signal dialog_closed


# Referências aos elementos visuais do dialog.
@onready var portrait: TextureRect = $Panel/Portrait
@onready var dialog_name: Label = $"Panel/Dialog Name"
@onready var dialog_text: Label = $"Panel/Dialog Text"
@onready var options_scroll: ScrollContainer = $Panel/OptionsScroll
@onready var options_container: VBoxContainer = $Panel/OptionsScroll/Options


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
var response_options: Array[DialogResponse] = []
var response_labels: Array[Label] = []
var _layout_initialized: bool = false
var _default_text_rect := Rect2()
var _default_options_rect := Rect2()


const PLAYER_PORTRAIT: Texture2D = preload("res://sprites/player/portrait_static.png")


func _ready() -> void:
	# O dialog começa escondido.
	visible = false

	options_scroll.visible = false
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_setup_player_portrait()


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
	dialog_name.text = line.dialog_name if not line.dialog_name.is_empty() else "Você"
	dialog_text.text = _format_dialog_text(line)
	_fit_dialog_text()
	_clear_response_options()
	options_scroll.visible = false
	_apply_dialog_layout(line)

	if line.hide_portrait:
		portrait.visible = false
	elif line.dialog_portrait == null:
		_show_player_portrait()
	else:
		portrait.visible = true
		portrait.texture = line.dialog_portrait

	# Sempre começa selecionando a primeira resposta.
	selected_response = 0

	response_options = _get_response_options(line)


func _get_response_options(line: DialogLine) -> Array[DialogResponse]:
	var options: Array[DialogResponse] = line.responses.duplicate()

	for legacy_option in [line.response_1, line.response_2]:
		if legacy_option != null and not options.has(legacy_option):
			options.append(legacy_option)

	return options


func _clear_response_options() -> void:
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()

	response_labels.clear()


func _format_dialog_text(line: DialogLine) -> String:
	match line.presentation:
		DialogLine.Presentation.ACTION:
			return "*%s*" % line.dialog_text
		DialogLine.Presentation.QUOTE:
			return "\"%s\"" % line.dialog_text
		DialogLine.Presentation.THOUGHT:
			return "[%s]" % line.dialog_text

	return line.dialog_text


func _fit_dialog_text() -> void:
	var dialog_font: Font = dialog_text.get_theme_font("font")

	if dialog_font == null:
		return

	for font_size in range(20, 10, -1):
		var measured := dialog_font.get_multiline_string_size(
			dialog_text.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			dialog_text.size.x,
			font_size
		)

		if measured.y <= dialog_text.size.y:
			dialog_text.add_theme_font_size_override("font_size", font_size)
			return

	dialog_text.add_theme_font_size_override("font_size", 11)


func _setup_player_portrait() -> void:
	portrait.texture = PLAYER_PORTRAIT


func _apply_dialog_layout(line: DialogLine) -> void:
	if not _layout_initialized:
		_default_text_rect = Rect2(
			dialog_text.offset_left,
			dialog_text.offset_top,
			dialog_text.offset_right - dialog_text.offset_left,
			dialog_text.offset_bottom - dialog_text.offset_top
		)

		_default_options_rect = Rect2(
			options_scroll.offset_left,
			options_scroll.offset_top,
			options_scroll.offset_right - options_scroll.offset_left,
			options_scroll.offset_bottom - options_scroll.offset_top
		)

		_layout_initialized = true

	var no_portrait := line.hide_portrait
	var no_name := line.hide_name or line.dialog_name.is_empty()

	dialog_name.visible = not line.hide_name

	# Retrato ocupa a esquerda; sem retrato o texto pode usar toda a largura.
	var text_left := 22.0 if no_portrait else _default_text_rect.position.x

	dialog_text.offset_left = text_left
	dialog_text.offset_top = _default_text_rect.position.y
	dialog_text.offset_right = _default_text_rect.position.x + _default_text_rect.size.x
	dialog_text.offset_bottom = _default_text_rect.position.y + _default_text_rect.size.y

	dialog_text.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
		if (no_portrait and no_name)
		else HORIZONTAL_ALIGNMENT_LEFT
	)

	dialog_text.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
		if (no_portrait and no_name)
		else VERTICAL_ALIGNMENT_TOP
	)

	options_scroll.offset_left = text_left if no_portrait else _default_options_rect.position.x
	options_scroll.offset_top = _default_options_rect.position.y
	options_scroll.offset_right = (
		_default_options_rect.position.x + _default_options_rect.size.x
	)
	options_scroll.offset_bottom = (
		_default_options_rect.position.y + _default_options_rect.size.y
	)


func _show_player_portrait() -> void:
	portrait.visible = true
	portrait.texture = PLAYER_PORTRAIT


func _start_reveal() -> void:
	# Marca que o texto está sendo revelado.
	is_revealing = true

	# O jogador não pode interagir normalmente durante a revelação.
	can_interact = false

	options_scroll.visible = false

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
	_clear_response_options()

	if response_options.is_empty():
		return

	for response_index in response_options.size():
		var option_label := Label.new()
		option_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		option_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_label.custom_minimum_size = Vector2(540, 28)
		option_label.add_theme_font_override("font", dialog_text.get_theme_font("font"))
		option_label.add_theme_font_size_override("font_size", 18)
		option_label.mouse_filter = Control.MOUSE_FILTER_STOP
		option_label.gui_input.connect(
			_on_option_gui_input.bind(response_index)
		)

		options_container.add_child(option_label)
		response_labels.append(option_label)

	options_scroll.visible = true
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

		if not response_options.is_empty():
			_select_response()
		else:
			# Caso contrário, avança para a próxima linha.
			_next_dialog()

		return

	# Inputs abaixo daqui só funcionam quando o dialog
	# já terminou de revelar o texto.
	if not can_interact:
		return

	if response_options.is_empty():
		return

	if event.is_action_pressed("up") or event.is_action_pressed("left"):
		selected_response = posmod(
			selected_response - 1,
			response_options.size()
		)

		_update_response_selection()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("down") or event.is_action_pressed("right"):
		selected_response = (
			selected_response + 1
		) % response_options.size()

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
	for response_index in response_labels.size():
		var option_label := response_labels[response_index]
		var marker := "> " if response_index == selected_response else "  "

		option_label.text = marker + response_options[response_index].text

		option_label.add_theme_color_override(
			"font_color",
			Color(1.0, 0.9, 0.55)
			if response_index == selected_response
			else Color.WHITE
		)

	if selected_response < response_labels.size():
		options_scroll.ensure_control_visible(
			response_labels[selected_response]
		)


func _on_option_gui_input(
	event: InputEvent,
	response_index: int
) -> void:
	if (
		not event is InputEventMouseButton
		or not event.pressed
		or event.button_index != MOUSE_BUTTON_LEFT
	):
		return

	selected_response = response_index
	_update_response_selection()

	if can_interact:
		_select_response()

	get_viewport().set_input_as_handled()


func _select_response() -> void:
	if selected_response < 0 or selected_response >= response_options.size():
		close_dialog()
		return

	var selected := response_options[selected_response]

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

	options_scroll.visible = false

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
