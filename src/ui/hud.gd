extends CanvasLayer

const Reticle = preload("res://src/ui/reticle.gd")
const INK := Color("101e21")
const PAPER := Color("e9e4d5")
const MUTED := Color("9baaa6")
const AMBER := Color("e1ad67")

signal play_requested
signal menu_requested
signal resume_requested
signal quit_requested
signal mute_requested

var root: Control
var modal: Control
var hud: Control
var reticle: Control
var hp_label: Label
var hp_bar: ProgressBar
var ammo_label: Label
var wave_label: Label
var score_label: Label
var status_label: Label
var mode_label: Label
var debug_label: Label
var audio_label: Label

func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", PAPER)
	root.theme = theme
	build_hud()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	reticle = Reticle.new()
	root.add_child(reticle)

func label(text: String, size: int, color: Color = PAPER) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

func style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border
	result.set_border_width_all(1)
	result.content_margin_left = 20
	result.content_margin_right = 20
	result.content_margin_top = 14
	result.content_margin_bottom = 14
	return result

func panel(parent: Node, pos: Vector2, size: Vector2) -> PanelContainer:
	var result := PanelContainer.new()
	result.position = pos
	result.custom_minimum_size = size
	result.add_theme_stylebox_override("panel", style(Color(0.045, 0.09, 0.10, 0.93), Color("41514d")))
	parent.add_child(result)
	return result

func button(text: String, action: Callable, primary: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 54
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.alignment = HORIZONTAL_ALIGNMENT_LEFT
	result.add_theme_font_size_override("font_size", 19)
	result.add_theme_color_override("font_color", INK if primary else PAPER)
	result.add_theme_color_override("font_hover_color", INK)
	result.add_theme_color_override("font_pressed_color", INK)
	result.add_theme_stylebox_override("normal", style(AMBER if primary else Color("243437"), Color("4d5f59")))
	result.add_theme_stylebox_override("hover", style(Color("f1c788")))
	result.add_theme_stylebox_override("pressed", style(Color("be8d4d")))
	result.add_theme_stylebox_override("focus", style(Color(0, 0, 0, 0), PAPER))
	result.pressed.connect(action)
	return result

func build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var health_panel := panel(hud, Vector2(28, 24), Vector2(250, 90))
	health_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var health_box := VBoxContainer.new()
	health_panel.add_child(health_box)
	hp_label = label("SOBREVIVENTE / 100", 18)
	health_box.add_child(hp_label)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size.y = 8
	hp_bar.show_percentage = false
	hp_bar.add_theme_stylebox_override("background", style(Color("374542")))
	hp_bar.add_theme_stylebox_override("fill", style(AMBER))
	health_box.add_child(hp_bar)
	var wave_panel := panel(hud, Vector2(294, 24), Vector2(240, 90))
	var wave_box := VBoxContainer.new()
	wave_panel.add_child(wave_box)
	wave_label = label("HORDA 01", 25, AMBER)
	wave_box.add_child(wave_label)
	score_label = label("00000 PONTOS", 15, MUTED)
	wave_box.add_child(score_label)
	var ammo_panel := panel(hud, Vector2(-284, 24), Vector2(256, 90))
	ammo_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ammo_panel.offset_left = -284
	ammo_panel.offset_right = -28
	var ammo_box := VBoxContainer.new()
	ammo_panel.add_child(ammo_box)
	ammo_label = label("12 / 12", 27, AMBER)
	ammo_box.add_child(ammo_label)
	ammo_box.add_child(label("9 MM  /  RESERVA ILIMITADA", 12, MUTED))
	status_label = label("", 22, PAPER)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	status_label.offset_top = 134
	hud.add_child(status_label)
	var bottom := panel(hud, Vector2(28, -92), Vector2(550, 66))
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.offset_top = -92
	bottom.offset_bottom = -26
	mode_label = label("WASD  Mover    RMB  Focar    R  Recarregar", 16)
	bottom.add_child(mode_label)
	audio_label = label("ESC  Pausa   ·   F1  Agentes   ·   M  Áudio", 14, MUTED)
	audio_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	audio_label.position = Vector2(-350, -49)
	hud.add_child(audio_label)
	debug_label = label("", 16, AMBER)
	debug_label.position = Vector2(30, 145)
	hud.add_child(debug_label)
	# Every HUD descendant is transparent to aiming/clicking.
	ignore_mouse(hud)

func ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		ignore_mouse(child)

func show_screen(state: String, score: int, wave: int) -> void:
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	hud.visible = state in ["PLAYING", "PAUSED"]
	reticle.visible = state == "PLAYING"
	modal.visible = state != "PLAYING"
	if state == "PLAYING":
		return
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.06, 0.07, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	card.offset_right = 494
	card.add_theme_stylebox_override("panel", style(Color(0.04, 0.085, 0.095, 0.97)))
	modal.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 32)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	column.add_child(label("N S B   /   SURVIVAL ARCADE", 15, AMBER))
	var divider := ColorRect.new()
	divider.color = AMBER
	divider.custom_minimum_size = Vector2(42, 3)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(divider)
	if state == "MENU":
		column.add_child(label("NO SAFE\nBLOCK", 68))
		column.add_child(label("O bairro caiu.\nVocê ainda está de pé.", 24, MUTED))
	elif state == "OVER":
		column.add_child(label("FIM DA\nLINHA.", 64))
		column.add_child(label("%05d PONTOS\nHORDA %02d ALCANÇADA" % [score, wave], 24, AMBER))
	else:
		column.add_child(label("RESPIRE.", 58))
		column.add_child(label("Partida pausada.\nO bairro pode esperar.", 24, MUTED))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	if state == "MENU":
		column.add_child(label("01  MOVA-SE.   02  MIRE.   03  SOBREVIVA.", 13, AMBER))
		column.add_child(label("WASD   mover     •     Mouse   mirar\nEsquerdo   atirar     •     Direito   focar\nR   recarregar     •     F1   ver agentes", 16, MUTED))
		column.add_child(button("INICIAR PARTIDA     →", func(): play_requested.emit(), true))
		column.add_child(button("SAIR", func(): quit_requested.emit()))
	elif state == "OVER":
		column.add_child(button("TENTAR NOVAMENTE     →", func(): play_requested.emit(), true))
		column.add_child(button("VOLTAR AO MENU", func(): menu_requested.emit()))
	else:
		column.add_child(button("CONTINUAR     →", func(): resume_requested.emit(), true))
		column.add_child(button("VOLTAR AO MENU", func(): menu_requested.emit()))
	column.add_child(button("ÁUDIO ON / OFF     [M]", func(): mute_requested.emit()))
	column.add_child(label("UM QUARTEIRÃO. NENHUM LUGAR SEGURO.\nGODOT  /  EDIÇÃO ACADÊMICA 01", 12, MUTED))
	# Keyboard navigation starts at a meaningful action.
	for child in column.get_children():
		if child is Button:
			child.grab_focus()
			break

func update_game(game: Node) -> void:
	if not is_instance_valid(game.player):
		return
	var player = game.player
	hp_label.text = "SOBREVIVENTE  /  %03d" % int(player.health.current)
	hp_bar.value = player.health.current
	wave_label.text = "HORDA %02d" % game.waves.round_number
	score_label.text = "%05d PONTOS  ·  %d HOSTIS" % [game.score, game.waves.alive + game.waves.pending]
	ammo_label.text = "RECARREGANDO…" if player.weapon.reloading else "%02d / 12" % player.weapon.ammo
	ammo_label.add_theme_font_size_override("font_size", 19 if player.weapon.reloading else 27)
	reticle.focused = player.focused
	reticle.reloading = player.weapon.reloading
	if player.weapon.reloading:
		mode_label.text = "RECARREGANDO  /  %.1f s" % player.weapon.reload_left
	elif player.weapon.ammo == 0:
		mode_label.text = "SEM MUNIÇÃO NO PENTE   /   pressione R"
	elif player.focused:
		mode_label.text = "FOCO ATIVO   /   precisão máxima · movimento reduzido"
	else:
		mode_label.text = "WASD  Mover    RMB  Focar    R  Recarregar"
	status_label.text = "HORDA %02d EM %d" % [game.waves.round_number, ceili(game.intermission)] if game.intermission > 0 else ""
	debug_label.visible = game.debug_enabled
	debug_label.text = "AGENTES / F1\n%d ativos · %d pendentes\n%d FPS\nPercepção → decisão → ação" % [game.enemies.size(), game.waves.pending, Engine.get_frames_per_second()]
	audio_label.text = "ESC  Pausa   ·   F1  Agentes   ·   M  " + ("Mudo" if game.audio.muted else "Áudio")
