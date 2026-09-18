class_name LabAmbience
extends Node2D

var game: Node2D
var visual_time := 0.0
var _emissives: Array[Node2D] = []
var _emissive_timer: float = 0.0
var _shadow_casters: Array[Node2D] = []

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	visual_time += delta
	_emissive_timer -= delta
	if _emissive_timer <= 0.0:
		_emissive_timer = 0.1
		_emissives.clear()
		_shadow_casters.clear()
		if is_instance_valid(game):
			for body in get_tree().get_nodes_in_group("bodies"):
				if not is_instance_valid(body): continue
				# One shadow per assembled object keeps ragdolls and vehicles from
				# turning into a stack of overlapping dark ellipses.
				var is_robot_anchor = is_instance_valid(body.ragdoll) and body.kind == "pelvis"
				var is_vehicle_part = is_instance_valid(body.vehicle)
				if (not is_instance_valid(body.ragdoll) and not is_vehicle_part) or is_robot_anchor:
					if body.kind not in ["water_pool", "oil_pool", "acid_pool", "slug", "nail", "emp", "flame", "tether"]:
						_shadow_casters.append(body)
				if body.active and not body.freeze and body.kind in ["thruster", "coil", "zapper", "grenade", "drone"]:
					_emissives.append(body)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game): return

	# Height-aware contact shadows give every prop a firm place in the scene.
	# Two soft ellipses are cheaper than a shadow shader and remain WebGL-safe.
	for body in _shadow_casters:
		if not is_instance_valid(body): continue
		var height = game.FLOOR_Y - body.global_position.y
		if height < -24.0 or height > 720.0: continue
		var near = 1.0 - clampf(height / 720.0, 0.0, 1.0)
		var base_width = clampf(maxf(body.dimensions.x, 24.0) * 0.72, 18.0, 150.0)
		if is_instance_valid(body.ragdoll): base_width = 38.0 * body.ragdoll.size_scale
		var width = base_width + (1.0 - near) * 34.0
		var floor_point = Vector2(body.global_position.x, game.FLOOR_Y + 3.0)
		draw_set_transform(floor_point, 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, width, Color(0.0, 0.025, 0.045, 0.055 + near * 0.11))
		draw_circle(Vector2.ZERO, width * 0.56, Color(0.0, 0.015, 0.025, 0.07 + near * 0.12))
		draw_set_transform(Vector2.ZERO)
	
	# 1. Dynamic emissive lighting cast into the environment by active mechanisms
	for body in _emissives:
		if not is_instance_valid(body) or not body.active or body.freeze: continue
		if body.kind == "thruster":
			# Directional fiery exhaust illumination cone
			var thrust_dir = Vector2.DOWN.rotated(body.rotation)
			var exhaust_origin = body.global_position + thrust_dir * 24.0
			var cone_len = 120.0 + sin(visual_time * 30.0) * 18.0
			var cone_w = 44.0
			var side_vec = Vector2(-thrust_dir.y, thrust_dir.x)
			var pts = PackedVector2Array([
				exhaust_origin - side_vec * 8.0,
				exhaust_origin + thrust_dir * cone_len - side_vec * cone_w,
				exhaust_origin + thrust_dir * (cone_len * 1.2),
				exhaust_origin + thrust_dir * cone_len + side_vec * cone_w,
				exhaust_origin + side_vec * 8.0
			])
			draw_colored_polygon(pts, Color(1.0, 0.55, 0.15, 0.14 + sin(visual_time * 36.0) * 0.03))
			# Floor illumination patch under thruster
			var f_dist = game.FLOOR_Y - body.global_position.y
			if f_dist > 0 and f_dist < 340:
				var f_alpha = (1.0 - f_dist / 340.0) * 0.24
				draw_set_transform(Vector2(body.global_position.x, game.FLOOR_Y + 1), 0, Vector2(1.0, 0.25))
				draw_circle(Vector2.ZERO, 95.0, Color(1.0, 0.60, 0.18, f_alpha))
				draw_set_transform(Vector2.ZERO)
		elif body.kind in ["coil", "zapper"]:
			# Pulsing cyan electric light field
			var pulse = 0.55 + 0.45 * sin(visual_time * 14.0)
			draw_circle(body.global_position, 140.0, Color(0.25, 0.85, 1.0, 0.05 * pulse))
			draw_circle(body.global_position, 65.0, Color(0.45, 0.95, 1.0, 0.10 * pulse))
		elif body.kind == "grenade":
			# Warning red blink
			var blink = 0.5 + 0.5 * sin(visual_time * 18.0)
			draw_circle(body.global_position, 85.0, Color(1.0, 0.22, 0.18, 0.09 * blink))
		elif body.kind == "drone":
			# Volumetric searchlight beam cone
			var cone_pts = PackedVector2Array([
				body.global_position + Vector2(-14, 8),
				Vector2(body.global_position.x - 75, game.FLOOR_Y),
				Vector2(body.global_position.x + 75, game.FLOOR_Y),
				body.global_position + Vector2(14, 8)
			])
			draw_colored_polygon(cone_pts, Color(0.35, 0.95, 0.85, 0.045))
			draw_set_transform(Vector2(body.global_position.x, game.FLOOR_Y + 1), 0, Vector2(1.0, 0.25))
			draw_circle(Vector2.ZERO, 75.0, Color(0.35, 0.95, 0.85, 0.08))
			draw_set_transform(Vector2.ZERO)
	
	# 3. Atmospheric floating motes responding to the active arena theme
	var arena = game.arena
	var tint = Color(0.35, 0.95, 0.84)
	var strength = 1.0
	var scanner = true
	if is_instance_valid(arena):
		tint = arena.mote_color()
		strength = arena.mote_strength()
		scanner = arena.has_scanner()
	
	for i in range(48):
		var base_x = -2200.0 + float((i * 397) % 6900)
		var base_y = -140.0 + float((i * 173) % 700)
		var sway_x = sin(visual_time * 0.35 + float(i) * 1.7) * 22.0
		var sway_y = fmod(visual_time * (5.0 + float(i % 5)) + float(i) * 31.0, 130.0)
		var p = Vector2(base_x + sway_x, base_y + sway_y)
		var pulse = 0.30 + 0.25 * sin(visual_time * 1.5 + float(i) * 2.1)
		var alpha = maxf(0.04, pulse) * 0.32 * strength
		var color = Color(tint.r, tint.g, tint.b, alpha)
		var rad = 1.1 + float(i % 3) * 0.55
		draw_circle(p, rad, color)
		draw_circle(p, rad * 2.5, Color(color.r, color.g, color.b, color.a * 0.25))
		if i % 8 == 0:
			draw_line(p - Vector2(6, 0), p + Vector2(6, 0), Color(color.r, color.g, color.b, color.a * 0.4), 1)
	
	# 4. Very faint traveling horizontal scanner line
	if scanner:
		var scan_y = 180.0 + fmod(visual_time * 36.0, 380.0)
		draw_line(Vector2(-2400, scan_y), Vector2(4800, scan_y), Color(tint.r, tint.g, tint.b, 0.035), 2)
