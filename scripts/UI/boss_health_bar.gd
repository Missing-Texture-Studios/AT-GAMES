extends Control

const HUD_FONT: Font = preload("res://fonts/TINY5-REGULAR.TTF")
const BAR_MARGIN := 18.0
const BAR_HEIGHT := 52.0
const ICON_SIZE := 13.0
const ICON_GAP := 8.0

@export var boss_path: NodePath = ^"../../Denial"

var boss: Node2D
var boss_sprite: AnimatedSprite2D


func _ready() -> void:
	boss = get_node_or_null(boss_path) as Node2D
	if boss == null or boss.is_queued_for_deletion():
		visible = false
		return
	boss_sprite = boss.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	queue_redraw()


func _process(_delta: float) -> void:
	if not is_instance_valid(boss):
		visible = false
		return
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(boss):
		return

	var bar_width := minf(size.x - BAR_MARGIN * 2.0, 960.0)
	if bar_width <= 0.0:
		return
	var bar_position := Vector2((size.x - bar_width) * 0.5, size.y - BAR_HEIGHT - BAR_MARGIN)
	var bar_rect := Rect2(bar_position, Vector2(bar_width, BAR_HEIGHT))
	var is_enraged := bool(boss.get("is_enraged"))
	var is_vulnerable := bool(boss.call("can_be_damaged"))
	var is_exposed := bool(boss.get("is_flashlight_exposed"))
	var state := int(boss.get("state"))
	var border_color := Color(0.48, 0.17, 0.22, 0.95)
	if is_enraged:
		border_color = Color(1.0, 0.32, 0.1, 1.0)

	draw_rect(bar_rect, Color(0.025, 0.016, 0.023, 0.9))
	draw_rect(bar_rect, border_color, false, 2.0)
	_draw_boss_portrait(bar_rect)
	draw_string(
		HUD_FONT,
		Vector2(bar_rect.position.x + 39.0, bar_rect.position.y + 16.0),
		"Negação",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		13,
		Color(1.0, 0.86, 0.82, 1.0)
	)

	var icon_strip_width := ICON_SIZE * 4.0 + ICON_GAP * 3.0
	var icon_strip_left := bar_rect.end.x - icon_strip_width - 12.0
	var track_left := bar_rect.position.x + 39.0
	var track_width := maxf(icon_strip_left - track_left - 12.0, 24.0)
	var track_rect := Rect2(track_left, bar_rect.position.y + 28.0, track_width, 14.0)
	draw_rect(track_rect, Color(0.11, 0.065, 0.075, 1.0))

	var maximum_health := maxf(float(boss.get("max_health")), 1.0)
	var health_ratio := clampf(float(boss.get("health")) / maximum_health, 0.0, 1.0)
	var fill_color := Color(0.77, 0.13, 0.2, 1.0)
	if is_enraged:
		fill_color = Color(1.0, 0.34, 0.1, 1.0)
	if is_vulnerable:
		fill_color = Color(0.2, 0.78, 0.48, 1.0)
	if is_exposed and is_vulnerable:
		fill_color = Color(0.42, 1.0, 0.68, 1.0)
	draw_rect(Rect2(track_rect.position, Vector2(track_rect.size.x * health_ratio, track_rect.size.y)), fill_color)

	for segment in range(1, 17):
		var segment_x := track_rect.position.x + track_rect.size.x * float(segment) / 17.0
		draw_line(
			Vector2(segment_x, track_rect.position.y + 1.0),
			Vector2(segment_x, track_rect.end.y - 1.0),
			Color(0.025, 0.016, 0.023, 0.72),
			1.0
		)

	var enraged_mark_x := track_rect.position.x + track_rect.size.x * 0.5
	var marker_color := Color(1.0, 0.72, 0.28, 1.0 if is_enraged else 0.5)
	draw_line(Vector2(enraged_mark_x, track_rect.position.y - 2.0), Vector2(enraged_mark_x, track_rect.end.y + 2.0), marker_color, 2.0)
	_draw_phase_indicators(icon_strip_left, track_rect.get_center().y, state, is_enraged, is_vulnerable, is_exposed)


func _draw_boss_portrait(bar_rect: Rect2) -> void:
	if boss_sprite == null or boss_sprite.sprite_frames == null:
		return
	if boss_sprite.sprite_frames.get_frame_count(boss_sprite.animation) <= boss_sprite.frame:
		return
	var texture := boss_sprite.sprite_frames.get_frame_texture(boss_sprite.animation, boss_sprite.frame)
	if texture == null:
		return
	draw_texture_rect(
		texture,
		Rect2(bar_rect.position + Vector2(7.0, 5.0), Vector2(21.0, 42.0)),
		false,
		Color.WHITE
	)


func _draw_phase_indicators(
	left: float,
	center_y: float,
	state: int,
	is_enraged: bool,
	is_vulnerable: bool,
	is_exposed: bool
) -> void:
	var active_phase := 0
	match state:
		2:
			active_phase = 1
		3:
			active_phase = 2
		4:
			active_phase = 3
		_:
			pass

	for phase_index in range(4):
		var center := Vector2(left + ICON_SIZE * 0.5 + phase_index * (ICON_SIZE + ICON_GAP), center_y)
		var active_color := Color(0.8, 0.67, 0.58, 0.28)
		if phase_index == active_phase:
			active_color = Color(0.95, 0.8, 0.65, 0.95)
		if phase_index == 3 and is_vulnerable:
			var exposure_alpha := 1.0
			if is_exposed:
				exposure_alpha = 0.72 + 0.28 * sin(Time.get_ticks_msec() * 0.012)
			active_color = Color(0.45, 1.0, 0.68, exposure_alpha)
		if is_enraged and phase_index == active_phase:
			active_color = Color(1.0, 0.34, 0.16, 1.0)
		_draw_phase_icon(phase_index, center, active_color)


func _draw_phase_icon(phase_index: int, center: Vector2, color: Color) -> void:
	match phase_index:
		0:
			draw_arc(center, 4.5, 0.0, TAU, 16, color, 1.5)
			draw_circle(center, 1.6, color)
		1:
			var top := center + Vector2(0.0, -5.0)
			var lower_left := center + Vector2(-5.0, 4.0)
			var lower_right := center + Vector2(5.0, 4.0)
			draw_line(top, lower_left, color, 1.5)
			draw_line(lower_left, lower_right, color, 1.5)
			draw_line(lower_right, top, color, 1.5)
			draw_line(center + Vector2(0.0, -2.0), center + Vector2(0.0, 1.0), color, 1.5)
			draw_circle(center + Vector2(0.0, 3.0), 0.8, color)
		2:
			for arrow_offset in [-3.0, 3.0]:
				var arrow_center := center + Vector2(arrow_offset, 0.0)
				draw_line(arrow_center + Vector2(-2.0, -4.0), arrow_center + Vector2(2.0, 0.0), color, 1.5)
				draw_line(arrow_center + Vector2(2.0, 0.0), arrow_center + Vector2(-2.0, 4.0), color, 1.5)
		3:
			draw_arc(center, 4.3, 0.0, TAU, 16, color, 1.5)
			draw_line(center + Vector2(-6.0, 0.0), center + Vector2(-2.0, 0.0), color, 1.2)
			draw_line(center + Vector2(2.0, 0.0), center + Vector2(6.0, 0.0), color, 1.2)
			draw_line(center + Vector2(0.0, -6.0), center + Vector2(0.0, -2.0), color, 1.2)
			draw_line(center + Vector2(0.0, 2.0), center + Vector2(0.0, 6.0), color, 1.2)