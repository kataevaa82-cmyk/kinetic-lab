class_name LabEffects
extends Node2D

var particles: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var beams: Array[Dictionary] = []
var flashes: Array[Dictionary] = []
var arcs: Array[Dictionary] = []

func slash_arc(center_pos: Vector2, radius: float, from_angle: float, to_angle: float, color: Color = LabArt.TEAL) -> void:
	var start_a = minf(from_angle, to_angle)
	var end_a = maxf(from_angle, to_angle)
	if end_a - start_a > PI * 1.6:
		end_a = start_a + PI * 1.6
	arcs.append({
		"center": center_pos,
		"r": radius,
		"from_a": start_a,
		"to_a": end_a,
		"color": color,
		"life": 0.22,
		"max_life": 0.22
	})

func emit_sparks(point: Vector2, count: int, color: Color, bias: Vector2 = Vector2.ZERO) -> void:
	for i in range(mini(count, 550 - particles.size())):
		var angle = randf() * TAU
		var spd = randf_range(50, 360)
		var vel = Vector2.from_angle(angle) * spd + bias
		var life = randf_range(0.35, 1.05)
		particles.append({
			"p": point,
			"v": vel,
			"life": life,
			"max_life": life,
			"c": color,
			"s": randf_range(1.6, 4.2),
			"gravity": 420.0,
			"glow": true,
			"spark": true
		})

func explosion(point: Vector2, radius: float) -> void:
	# Primary shockwave and secondary atmospheric refraction ring
	rings.append({"p": point, "r": radius * 1.25, "life": 0.65, "max_life": 0.65, "color": LabArt.AMBER})
	rings.append({"p": point, "r": radius * 1.65, "life": 0.50, "max_life": 0.50, "color": Color(0.4, 0.9, 1.0)})
	
	# Central blast flash
	flashes.append({"p": point, "r": radius * 0.75, "life": 0.22, "max_life": 0.22})
	
	# Expanding fireball clusters
	for i in range(14):
		var ang = randf() * TAU
		var dist = randf_range(4, 28)
		var spd = randf_range(40, 160)
		var p_life = randf_range(0.55, 1.15)
		particles.append({
			"p": point + Vector2.from_angle(ang) * dist,
			"v": Vector2.from_angle(ang) * spd + Vector2.UP * 35.0,
			"life": p_life,
			"max_life": p_life,
			"c": Color(1.0, 0.65, 0.2),
			"s": randf_range(12.0, 26.0),
			"gravity": -25.0,
			"glow": true,
			"fireball": true,
			"rot": randf() * TAU,
			"rot_speed": randf_range(-3.0, 3.0)
		})
	
	# Dense fiery shrapnel that arcs and bounces off the floor
	for i in range(32):
		var ang = randf() * TAU
		var spd = randf_range(120, 520)
		var p_life = randf_range(0.65, 1.45)
		particles.append({
			"p": point,
			"v": Vector2.from_angle(ang) * spd + Vector2.UP * 40.0,
			"life": p_life,
			"max_life": p_life,
			"c": LabArt.AMBER,
			"s": randf_range(2.0, 4.5),
			"gravity": 550.0,
			"glow": true,
			"shrapnel": true
		})
	
	# Soft atmospheric smoke puff
	for i in range(12):
		var ang = randf() * TAU
		var dist = randf_range(4, 24)
		var spd = randf_range(20, 80)
		var p_life = randf_range(0.5, 1.2)
		particles.append({
			"p": point + Vector2.from_angle(ang) * dist,
			"v": Vector2.from_angle(ang) * spd + Vector2.UP * 45.0,
			"life": p_life,
			"max_life": p_life,
			"c": Color(0.65, 0.75, 0.82),
			"s": randf_range(9.0, 18.0),
			"gravity": -15.0,
			"glow": false,
			"smoke": true,
			"rot": randf() * TAU,
			"rot_speed": randf_range(-1.5, 1.5)
		})

func beam(from: Vector2, to: Vector2) -> void:
	beams.append({"a": from, "b": to, "life": 0.20, "max_life": 0.20})
	emit_sparks(to, 14, LabArt.TEAL)

func flash(point: Vector2, radius: float = 24.0, color: Color = Color(1.0, 0.95, 0.8)) -> void:
	flashes.append({"p": point, "r": radius, "life": 0.12, "max_life": 0.12, "color": color})

var _active_frames_left: int = 0

func _process(delta: float) -> void:
	if particles.is_empty() and rings.is_empty() and beams.is_empty() and flashes.is_empty() and arcs.is_empty():
		if _active_frames_left > 0:
			_active_frames_left -= 1
			queue_redraw()
		return
	_active_frames_left = 2

	for i in range(particles.size() - 1, -1, -1):
		var p = particles[i]
		p.life -= delta
		p.v.y += float(p.get("gravity", 380.0)) * delta
		if p.get("smoke", false):
			p.v *= pow(0.25, delta)
			p.s += delta * 12.0
		elif p.get("fireball", false):
			p.v *= pow(0.35, delta)
			p.s += delta * 8.0
		elif p.get("shrapnel", false):
			p.v.x *= pow(0.85, delta)
		p.p += p.v * delta
		if p.has("rot"): p.rot += float(p.rot_speed) * delta
		
		# Floor bounce and friction
		if p.p.y > 619:
			p.p.y = 619
			p.v.y = -absf(p.v.y) * 0.35
			p.v.x *= 0.82
			if p.get("shrapnel", false) and absf(p.v.y) < 20:
				p.v.y = 0
		if p.life <= 0:
			particles.remove_at(i)
	
	for list in [rings, beams, flashes, arcs]:
		for i in range(list.size() - 1, -1, -1):
			list[i].life -= delta
			if list[i].life <= 0: list.remove_at(i)
	
	queue_redraw()

func _draw() -> void:
	if particles.is_empty() and rings.is_empty() and beams.is_empty() and flashes.is_empty() and arcs.is_empty():
		return

	var smoke_list: Array[Dictionary] = []
	var fireball_list: Array[Dictionary] = []
	var spark_list: Array[Dictionary] = []

	for p in particles:
		if p.get("smoke", false):
			smoke_list.append(p)
		elif p.get("fireball", false):
			fireball_list.append(p)
		else:
			spark_list.append(p)

	# 1. Smoke clouds (background layer of explosion)
	for p in smoke_list:
		var fade = clampf(p.life / float(p.get("max_life", 1.0)), 0.0, 1.0)
		var col: Color = p.c
		col.a = fade * 0.10
		draw_circle(p.p, p.s, col)
	
	# 2. Fireball clusters
	for p in fireball_list:
		var norm = clampf(1.0 - p.life / float(p.get("max_life", 1.0)), 0.0, 1.0)
		var fire_col = Color(1.0, 0.95, 0.8).lerp(Color(1.0, 0.45, 0.1), norm * 1.5)
		if norm > 0.6: fire_col = fire_col.lerp(Color(0.25, 0.15, 0.12), (norm - 0.6) / 0.4)
		fire_col.a = clampf((1.0 - norm) * 1.6, 0.0, 0.85)
		draw_circle(p.p, p.s, fire_col)
		draw_circle(p.p, p.s * 0.55, Color(1.0, 1.0, 0.85, fire_col.a * 0.7))
	
	# 3. Energy Beams with high-intensity electric jitter
	for b in beams:
		var progress = clampf(b.life / float(b.get("max_life", 0.20)), 0.0, 1.0)
		draw_line(b.a, b.b, Color(0.2, 0.85, 1.0, progress * 0.45), 28, true)
		draw_line(b.a, b.b, Color(0.35, 1.0, 0.85, progress * 0.95), 10, true)
		draw_line(b.a, b.b, Color(1.0, 1.0, 1.0, progress * 1.8), 2.5, true)
		var dir = b.b - b.a
		var length = dir.length()
		if length > 20:
			var steps = int(clampf(length / 28.0, 3, 12))
			var norm_dir = dir.normalized()
			var perp = Vector2(-norm_dir.y, norm_dir.x)
			var arc_pts = PackedVector2Array()
			arc_pts.append(b.a)
			for s in range(1, steps):
				var frac = float(s) / float(steps)
				var jitter = randf_range(-14.0, 14.0) * sin(frac * PI)
				arc_pts.append(b.a + dir * frac + perp * jitter)
			arc_pts.append(b.b)
			draw_polyline(arc_pts, Color(0.65, 1.0, 0.95, progress * 0.85), 1.8, true)
	
	# 4. Expanding shockwave rings
	for r in rings:
		var max_l = float(r.get("max_life", 0.65))
		var progress = 1.0 - r.life / max_l
		var col: Color = r.get("color", LabArt.AMBER)
		var rad = r.r * progress
		var alpha = (1.0 - progress)
		draw_arc(r.p, rad, 0, TAU, 72, Color(col.r, col.g, col.b, alpha * 0.9), 3.5, true)
		draw_arc(r.p, rad * 0.88, 0, TAU, 56, Color(1.0, 0.95, 0.75, alpha * 0.65), 2.0, true)
		draw_circle(r.p, rad * 0.75, Color(col.r, col.g, col.b, alpha * 0.08))
	
	# 5. Central blast flashes
	for f in flashes:
		var prog = 1.0 - f.life / float(f.get("max_life", 0.15))
		var alpha = (1.0 - prog) * 0.9
		var col: Color = f.get("color", Color(1.0, 0.95, 0.85))
		draw_circle(f.p, f.r * (0.8 + prog * 0.5), Color(col.r, col.g, col.b, alpha))
		draw_circle(f.p, f.r * 0.45, Color(1.0, 1.0, 1.0, alpha * 1.2))
	
	# 6. Slash trail arcs
	for a in arcs:
		var progress = 1.0 - a.life / float(a.get("max_life", 0.22))
		var alpha = (1.0 - progress) * 0.95
		var col: Color = a.get("color", LabArt.TEAL)
		var c_outer = Color(col.r, col.g, col.b, alpha * 0.85)
		var c_inner = Color(1.0, 1.0, 1.0, alpha * 1.15)
		draw_arc(a.center, a.r, a.from_a, a.to_a, 24, c_outer, 7.0 * (1.0 - progress * 0.45), true)
		draw_arc(a.center, a.r * 0.97, a.from_a, a.to_a, 20, c_inner, 2.4, true)
	
	# 7. Shrapnel & Sparks
	for p in spark_list:
		var col: Color = p.c
		var fade = clampf(p.life / float(p.get("max_life", 1.0)), 0.0, 1.0)
		col.a *= minf(1.0, fade * 2.2)
		var p_size = p.s
		
		if p.get("shrapnel", false):
			var tail = p.p - p.v * 0.038
			draw_line(p.p, tail, Color(col.r, col.g * 0.6, col.b * 0.2, col.a * 0.5), p_size * 2.2, true)
			draw_circle(p.p, p_size, Color(1.0, 0.85, 0.5, col.a))
			draw_circle(p.p, p_size * 0.5, Color(1.0, 1.0, 1.0, col.a))
		else:
			var tail = p.p - p.v * 0.032
			if p.get("glow", false):
				draw_line(p.p, tail, Color(col.r, col.g, col.b, col.a * 0.22), p_size * 4.2, true)
			draw_line(p.p, tail, col, p_size * 1.4, true)
			draw_circle(p.p, p_size * 0.65, Color(1.0, 1.0, 1.0, col.a * 0.95))
