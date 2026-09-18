class_name LabParts
extends RefCounted

# Конструктор. Детали сами по себе — обычные тела; строит их сварка. Инструмент
# "Связь" между деталью конструктора и любым предметом ставит не пружину, а
# крепление, тип которого зависит от детали:
#   rigid  — два пальца в разных точках: пара тел движется как одно целое;
#   pivot  — один палец: тела вращаются друг относительно друга (ось, шарнир);
#   motor  — палец с мотором PinJoint2D: мотор крутит прикреплённую деталь;
#   spring — жёсткая пружина с демпфером (амортизатор).
# Шарнир и мотор первой связью встают на основание жёстко, дальше — вращают.
# F на обычной детали приваривает её ко всему, чего она касается.

const KINDS = [
	"c_beam","c_beam_long","c_girder","c_plate","c_board","c_block","c_corner","c_triangle",
	"c_pipe","c_frame","c_platform","c_counterweight","c_hinge","c_axle","c_motor","c_spring",
	"c_jet","c_balloon","c_spikes","c_wing"
]
const POWERED = ["c_motor","c_jet"]

# w/h — габариты, mass, hp; shape: rect (по умолчанию), circle, corner, triangle, frame.
const SPECS = {
	"c_beam": {"w": 90, "h": 12, "mass": 4.0, "hp": 260.0, "friction": 0.7},
	"c_beam_long": {"w": 200, "h": 12, "mass": 9.0, "hp": 320.0, "friction": 0.7},
	"c_girder": {"w": 180, "h": 24, "mass": 7.0, "hp": 300.0, "friction": 0.7},
	"c_plate": {"w": 100, "h": 50, "mass": 12.0, "hp": 380.0, "friction": 0.6},
	"c_board": {"w": 120, "h": 16, "mass": 5.0, "hp": 140.0, "friction": 0.9},
	"c_block": {"w": 40, "h": 40, "mass": 20.0, "hp": 500.0, "friction": 0.8},
	"c_corner": {"w": 60, "h": 60, "mass": 6.0, "hp": 280.0, "friction": 0.7, "shape": "corner"},
	"c_triangle": {"w": 60, "h": 60, "mass": 5.0, "hp": 260.0, "friction": 0.7, "shape": "triangle"},
	"c_pipe": {"w": 160, "h": 10, "mass": 3.0, "hp": 200.0, "friction": 0.5},
	"c_frame": {"w": 80, "h": 80, "mass": 8.0, "hp": 300.0, "friction": 0.7, "shape": "frame"},
	"c_platform": {"w": 220, "h": 10, "mass": 6.0, "hp": 220.0, "friction": 1.0},
	"c_counterweight": {"w": 44, "h": 44, "mass": 80.0, "hp": 800.0, "friction": 0.9},
	"c_hinge": {"w": 24, "h": 24, "mass": 1.5, "hp": 300.0, "friction": 0.6, "shape": "circle"},
	"c_axle": {"w": 44, "h": 44, "mass": 3.0, "hp": 300.0, "friction": 1.3, "shape": "circle"},
	"c_motor": {"w": 36, "h": 36, "mass": 6.0, "hp": 320.0, "friction": 0.8, "shape": "circle"},
	"c_spring": {"w": 20, "h": 56, "mass": 2.0, "hp": 200.0, "friction": 0.6},
	"c_jet": {"w": 56, "h": 22, "mass": 5.0, "hp": 180.0, "friction": 0.6},
	"c_balloon": {"w": 52, "h": 52, "mass": 1.5, "hp": 20.0, "friction": 0.4, "shape": "circle"},
	"c_spikes": {"w": 60, "h": 20, "mass": 6.0, "hp": 400.0, "friction": 0.8},
	"c_wing": {"w": 150, "h": 10, "mass": 3.0, "hp": 160.0, "friction": 0.5}
}

const MOTOR_SPEED = 6.5
# Предел момента мотора: стрелу из длинной балки с грузом 30 кг он поднимает.
const MOTOR_TORQUE = 1400000.0
const JET_FORCE = 26000.0
const BALLOON_LIFT = 22000.0

static func is_part(body) -> bool:
	return is_instance_valid(body) and body is LabBody and body.kind in KINDS

static func setup(body: LabBody) -> void:
	var s = SPECS[body.kind]
	body.dimensions = Vector2(float(s.w), float(s.h))
	body.mass = s.mass
	body.health = s.hp

static func add_shapes(body: LabBody) -> void:
	var s = SPECS[body.kind]
	var w = float(s.w)
	var h = float(s.h)
	var shapes: Array = []
	match str(s.get("shape", "rect")):
		"circle":
			var c = CircleShape2D.new(); c.radius = w * 0.5
			shapes.append([c, Vector2.ZERO])
		"corner":
			var a = RectangleShape2D.new(); a.size = Vector2(w, 14)
			var b = RectangleShape2D.new(); b.size = Vector2(14, h - 14)
			shapes.append([a, Vector2(0, h * 0.5 - 7)])
			shapes.append([b, Vector2(-w * 0.5 + 7, -7)])
		"triangle":
			var t = ConvexPolygonShape2D.new()
			t.points = PackedVector2Array([Vector2(-w * 0.5, h * 0.5), Vector2(w * 0.5, h * 0.5), Vector2(-w * 0.5, -h * 0.5)])
			shapes.append([t, Vector2.ZERO])
		"frame":
			var bar = 10.0
			for side in [[Vector2(w, bar), Vector2(0, -h * 0.5 + bar * 0.5)], [Vector2(w, bar), Vector2(0, h * 0.5 - bar * 0.5)], [Vector2(bar, h - bar * 2), Vector2(-w * 0.5 + bar * 0.5, 0)], [Vector2(bar, h - bar * 2), Vector2(w * 0.5 - bar * 0.5, 0)]]:
				var r = RectangleShape2D.new(); r.size = side[0]
				shapes.append([r, side[1]])
		_:
			var r = RectangleShape2D.new(); r.size = Vector2(w, h)
			shapes.append([r, Vector2.ZERO])
	for entry in shapes:
		var cs = CollisionShape2D.new()
		cs.shape = entry[0]
		cs.position = entry[1]
		body.add_child(cs)
	var mat = PhysicsMaterial.new()
	mat.friction = float(s.friction)
	mat.bounce = 0.05
	body.physics_material_override = mat

# --------------------------------------------------------------------------
# Сварка
# --------------------------------------------------------------------------
static func weld_count(game: Node2D, body: LabBody) -> int:
	var n = 0
	for w in game.welds:
		if w.a == body or w.b == body: n += 1
	return n

static func welded(game: Node2D, a: LabBody, b: LabBody) -> bool:
	for w in game.welds:
		if (w.a == a and w.b == b) or (w.a == b and w.b == a): return true
	return false

static func choose_type(game: Node2D, a: LabBody, b: LabBody) -> String:
	for kind_pair in [["c_spring", "spring"], ["c_axle", "pivot"]]:
		if a.kind == kind_pair[0] or b.kind == kind_pair[0]: return kind_pair[1]
	for part in [a, b]:
		if part.kind == "c_motor": return "rigid" if weld_count(game, part) == 0 else "motor"
	for part in [a, b]:
		if part.kind == "c_hinge": return "rigid" if weld_count(game, part) == 0 else "pivot"
	return "rigid"

static func pivot_body(a: LabBody, b: LabBody) -> LabBody:
	for kind in ["c_axle", "c_motor", "c_hinge"]:
		if a.kind == kind: return a
		if b.kind == kind: return b
	return a

static func can_weld(game: Node2D, a, b) -> bool:
	if not (is_instance_valid(a) and is_instance_valid(b)) or a == b: return false
	if not (a is LabBody and b is LabBody): return false
	for body in [a, b]:
		if body.kind in game.EPHEMERAL or body.kind in game.FLUIDS or body.kind == LabVehicle.WHEEL: return false
	return is_part(a) or is_part(b)

static func weld(game: Node2D, a: LabBody, b: LabBody, type: String = "", announce: bool = false) -> bool:
	if not can_weld(game, a, b) or welded(game, a, b): return false
	if game.welds.size() >= 160:
		if announce: game.notify(game.t("Слишком много креплений: удали часть конструкции", "Too many joints: remove part of a build"))
		return false
	if type == "": type = choose_type(game, a, b)
	var joints: Array = []
	match type:
		"rigid":
			# Два пальца в разных точках держат пару как одно тело. Точки — возле
			# места контакта, на отрезке между центрами, разнесённые поперёк.
			var mid = a.global_position.lerp(b.global_position, 0.5)
			var along = (b.global_position - a.global_position)
			var perp = Vector2.UP if along.length() < 1.0 else along.normalized().orthogonal()
			for p in [mid + perp * 9.0, mid - perp * 9.0]:
				joints.append(_pin(game, a, b, p))
		"pivot", "motor":
			var hub = pivot_body(a, b)
			var pin = _pin(game, a, b, hub.global_position)
			# Мотор крутит деталь не мотором шарнира — тот в Godot слишком слаб и не
			# поднимал даже балку, — а моментом в LabParts.tick.
			joints.append(pin)
		"spring":
			var j = DampedSpringJoint2D.new()
			game.world.add_child(j)
			j.global_position = a.global_position
			j.rotation = (b.global_position - a.global_position).angle() - PI / 2
			j.length = maxf(a.global_position.distance_to(b.global_position), 5.0)
			j.rest_length = j.length
			j.stiffness = 60.0 * (a.mass + b.mass)
			j.damping = 2.0
			j.disable_collision = true
			j.node_a = j.get_path_to(a)
			j.node_b = j.get_path_to(b)
			joints.append(j)
	game.welds.append({"a": a, "b": b, "type": type, "joints": joints})
	# Всё, что сварено в одну конструкцию, между собой не сталкивается — как
	# пластины робота. Иначе лопасть мельницы упиралась в свою же стойку, а рама
	# тележки — в ускоритель, приваренный к той же раме, и конструкцию разносило.
	var members = group(game, a)
	for i in range(members.size()):
		for k in range(i + 1, members.size()):
			members[i].add_collision_exception_with(members[k])
			members[k].add_collision_exception_with(members[i])
	if announce:
		var msg = {
			"rigid": game.t("Детали сварены", "Parts welded"),
			"pivot": game.t("Соединено на оси — вращается", "Joined on a pivot — it turns"),
			"motor": game.t("Мотор крутит деталь. F — направление", "The motor drives the part. F sets direction"),
			"spring": game.t("Поставлен амортизатор", "Shock absorber fitted")
		}[type]
		game.notify(msg)
		game.play_sound("equip" if type != "spring" else "link", 0.4)
		game.record("link")
	return true

static func _pin(game: Node2D, a: LabBody, b: LabBody, at: Vector2) -> PinJoint2D:
	var pin = PinJoint2D.new()
	game.world.add_child(pin)
	pin.global_position = at
	pin.softness = 0.0
	pin.disable_collision = true
	pin.node_a = pin.get_path_to(a)
	pin.node_b = pin.get_path_to(b)
	return pin

static func group(game: Node2D, start: LabBody) -> Array:
	var seen: Array = [start]
	var queue: Array = [start]
	while not queue.is_empty():
		var cur = queue.pop_back()
		for wd in game.welds:
			var other = wd.b if wd.a == cur else (wd.a if wd.b == cur else null)
			if other != null and is_instance_valid(other) and other not in seen:
				seen.append(other)
				queue.append(other)
	return seen

static func unweld_all(game: Node2D, body: LabBody) -> int:
	var n = 0
	var former = group(game, body)
	for i in range(game.welds.size() - 1, -1, -1):
		var w = game.welds[i]
		if w.a == body or w.b == body:
			for j in w.joints:
				if is_instance_valid(j): j.free()
			game.welds.remove_at(i)
			n += 1
	# Отсоединённая деталь снова сталкивается с бывшей конструкцией.
	for other in former:
		if other != body and is_instance_valid(other):
			body.remove_collision_exception_with(other)
			other.remove_collision_exception_with(body)
	return n

static func touching(game: Node2D, body: LabBody) -> Array:
	# Касание с запасом в несколько пикселей: детали, поставленные встык, в
	# физическом контакте могут и не быть.
	var found: Array = []
	var space = body.get_world_2d().direct_space_state
	for child in body.get_children():
		if not child is CollisionShape2D: continue
		var q = PhysicsShapeQueryParameters2D.new()
		q.shape = child.shape
		q.transform = body.global_transform * child.transform
		q.margin = 6.0
		q.collision_mask = 2
		q.exclude = [body.get_rid()]
		for hit in space.intersect_shape(q, 16):
			var other = hit.collider
			if other is LabBody and other not in found and can_weld(game, body, other): found.append(other)
	return found

static func activate(game: Node2D, body: LabBody) -> void:
	match body.kind:
		"c_motor":
			body.gear = {0: 1, 1: -1, -1: 0}[body.gear]
			body.active = body.gear != 0
			refresh_motor(game, body)
			game.notify([game.t("Мотор остановлен", "Motor stopped"), game.t("Мотор: по часовой", "Motor: clockwise"), game.t("Мотор: против часовой", "Motor: counter-clockwise")][[0, 1, -1].find(body.gear)])
			game.play_sound("switch_on" if body.active else "switch_off", 0.4)
		"c_jet":
			body.active = not body.active
			game.notify(game.t("Ускоритель включён", "Booster on") if body.active else game.t("Ускоритель выключен", "Booster off"))
			game.play_sound("rocket" if body.active else "switch_off", 0.4)
		_:
			var added = 0
			for other in touching(game, body):
				if weld(game, body, other): added += 1
			if added > 0:
				game.notify(game.t("Приварено к деталям: %d" % added, "Welded to %d parts" % added))
				game.play_sound("equip", 0.45)
				game.record("link")
			elif unweld_all(game, body) > 0:
				game.notify(game.t("Деталь отсоединена", "Part detached"))
				game.play_sound("snap", 0.4)
			else:
				game.notify(game.t("Поставь деталь вплотную к другой и нажми F — или соедини «Связью»", "Place the part against another and press F — or join them with Link"))

static func refresh_motor(game: Node2D, motor: LabBody) -> void:
	for w in game.welds:
		if w.type != "motor" or (w.a != motor and w.b != motor): continue
		# Мотор, стоящий без дела, засыпает вместе с деталью — будим пару.
		w.a.sleeping = false
		w.b.sleeping = false

# --------------------------------------------------------------------------
# Поведение
# --------------------------------------------------------------------------
static func tick(game: Node2D, body: LabBody, delta: float) -> void:
	if body.freeze: return
	match body.kind:
		"c_motor":
			if body.gear == 0: return
			# Момент к целевой относительной скорости; реакция уходит в сам мотор,
			# а через жёсткое крепление — в основание. Незакреплённая конструкция
			# поэтому закручивается сама, как и должна.
			for w in game.welds:
				if w.type != "motor" or (w.a != body and w.b != body): continue
				var other: LabBody = w.b if w.a == body else w.a
				if not is_instance_valid(other) or other.freeze: continue
				var reach = maxf(other.dimensions.x, other.dimensions.y) * 0.5
				var rel = other.angular_velocity - body.angular_velocity
				var want = MOTOR_SPEED * float(body.gear)
				var torque = clampf((want - rel) * other.mass * reach * reach * 20.0, -MOTOR_TORQUE, MOTOR_TORQUE)
				other.apply_torque(torque)
				body.apply_torque(-torque)
				other.sleeping = false
		"c_jet":
			if body.active:
				var dir = Vector2.RIGHT.rotated(body.rotation)
				body.apply_central_force(dir * JET_FORCE)
				if Engine.get_physics_frames() % 2 == 0:
					game.fx.emit_sparks(body.global_position - dir * 30.0, 2, LabArt.AMBER, -dir * 260.0)
				if Engine.get_physics_frames() % 9 == 0: game.play_sound("flame", 0.14)
		"c_balloon":
			if game.gravity: body.apply_central_force(Vector2(0, -BALLOON_LIFT))
			body.linear_damp = 0.9
			if body.health <= 0.0 and not body.detonating:
				body.detonating = true
				game.fx.emit_sparks(body.global_position, 16, LabArt.TEAL)
				game.play_sound("pop", 0.5)
				game.call_deferred("remove_entity", body)
		"c_wing":
			# Плоская пластина в потоке: сила против нормальной составляющей
			# скорости. Наклонённое крыло на ходу даёт подъём, плашмя — тормозит
			# падение, ребром вперёд почти не мешает.
			var n = Vector2.UP.rotated(body.rotation)
			var v = body.linear_velocity
			var vn = v.dot(n)
			var force = -n * vn * v.length() * 0.0016 * body.dimensions.x
			body.apply_central_force(force.limit_length(40000.0))
	if body.kind in POWERED and body.active: body.queue_redraw()

static func on_contact(game: Node2D, body: LabBody, other: Node) -> void:
	if body.kind != "c_spikes" or body.impact_cooldown > 0.0: return
	if not other is LabBody or other.kind in game.EPHEMERAL: return
	var speed = (body.prior_velocity - other.linear_velocity).length()
	if speed < 70.0: return
	body.impact_cooldown = 0.25
	var hurt = clampf(8.0 + speed * 0.04, 8.0, 40.0)
	if is_instance_valid(other.ragdoll):
		if other.ragdoll.cut_guard > 0.0: return
		other.ragdoll.cut_guard = 0.2
		other.ragdoll.hurt(hurt)
	else:
		other.damage(hurt, Vector2.ZERO)
	game.fx.emit_sparks(other.global_position, 5, LabArt.AMBER)
	game.play_sound("metal", 0.3)

# --------------------------------------------------------------------------
# Рисование
# --------------------------------------------------------------------------
const STEEL = Color("7d8f9b")
const STEEL_DARK = Color("4a5a66")
const STEEL_LIGHT = Color("b7c6cf")
const WOOD = Color("a8743f")

static func draw_icon(c: CanvasItem, kind: String, center: Vector2, scale_value: float, rot: float) -> void:
	var s = SPECS[kind]
	var fit = 1.0
	if scale_value < 0.8: fit = minf(1.0, minf(118.0 / float(s.w), 70.0 / float(s.h)) / 0.64 * 0.64)
	if scale_value < 0.45: fit = minf(1.0, minf(56.0 / float(s.w), 30.0 / float(s.h)))
	c.draw_set_transform(center, rot, Vector2.ONE * scale_value * fit)
	draw(c, kind, 1.0, false, 0, 0.0)
	c.draw_set_transform(Vector2.ZERO)

static func _bolt(c: CanvasItem, at: Vector2, r: float = 2.2) -> void:
	LabSurface.circle(c,at, r + 0.8, STEEL_DARK)
	LabSurface.circle(c,at, r, STEEL_LIGHT)

static func draw(c: CanvasItem, kind: String, condition: float, active: bool, gear: int, phase: float) -> void:
	var s = SPECS[kind]
	var w = float(s.w)
	var h = float(s.h)
	var half = Vector2(w, h) * 0.5
	var steel = STEEL.lerp(Color("3a3f44"), clampf((1.0 - condition) * 0.7, 0.0, 0.7))
	match kind:
		"c_beam", "c_beam_long":
			LabSurface.rect(c,Rect2(-half, Vector2(w, h)), steel)
			LabSurface.line(c,Vector2(-half.x, -half.y + 1.5), Vector2(half.x, -half.y + 1.5), STEEL_LIGHT, 1.5)
			LabSurface.line(c,Vector2(-half.x, half.y - 1.5), Vector2(half.x, half.y - 1.5), STEEL_DARK, 1.5)
			var holes = int(w / 30.0)
			for i in range(holes):
				var x = -half.x + (float(i) + 0.5) * w / float(holes)
				LabSurface.circle(c,Vector2(x, 0), 2.6, Color("1a2328"))
		"c_girder":
			LabSurface.rect(c,Rect2(-half.x, -half.y, w, 4), steel)
			LabSurface.rect(c,Rect2(-half.x, half.y - 4, w, 4), steel)
			var n = 8
			var step = w / float(n)
			for i in range(n):
				var x0 = -half.x + float(i) * step
				LabSurface.line(c,Vector2(x0, half.y - 3), Vector2(x0 + step, -half.y + 3), steel, 3.0, true)
				LabSurface.line(c,Vector2(x0, -half.y + 3), Vector2(x0, half.y - 3), steel.darkened(0.15), 2.0)
			LabSurface.line(c,Vector2(half.x, -half.y), Vector2(half.x, half.y), steel, 3.0)
			for x in [-half.x + 4, half.x - 4]: _bolt(c, Vector2(x, 0), 2.0)
		"c_plate":
			LabSurface.rect(c,Rect2(-half, Vector2(w, h)), steel)
			LabSurface.rect(c,Rect2(-half + Vector2(3, 3), Vector2(w - 6, h - 6)), steel.lightened(0.08), false, 1.5)
			for p in [Vector2(-half.x + 7, -half.y + 7), Vector2(half.x - 7, -half.y + 7), Vector2(-half.x + 7, half.y - 7), Vector2(half.x - 7, half.y - 7)]:
				_bolt(c, p)
			for i in range(4):
				LabSurface.line(c,Vector2(-half.x + 16 + i * 20, -half.y + 14), Vector2(-half.x + 28 + i * 20, half.y - 14), Color(1, 1, 1, 0.06), 3.0)
		"c_board":
			var wood = WOOD.lerp(Color("3a2c20"), clampf((1.0 - condition) * 0.7, 0.0, 0.7))
			LabSurface.rect(c,Rect2(-half, Vector2(w, h)), wood)
			LabSurface.line(c,Vector2(-half.x, -2), Vector2(half.x, -2), wood.darkened(0.25), 1.0)
			LabSurface.line(c,Vector2(-half.x, 3), Vector2(half.x, 3), wood.darkened(0.2), 1.0)
			c.draw_arc(Vector2(-20, 0), 4.0, 0.5, 5.5, 10, wood.darkened(0.35), 1.2, true)
			for x in [-half.x + 8, half.x - 8]:
				LabSurface.circle(c,Vector2(x, 0), 2.0, STEEL_LIGHT)
		"c_block":
			LabSurface.rect(c,Rect2(-half, Vector2(w, h)), steel.darkened(0.1))
			LabSurface.polygon(c,PackedVector2Array([-half, Vector2(half.x, -half.y), Vector2(half.x - 6, -half.y + 6), -half + Vector2(6, 6)]), STEEL_LIGHT.darkened(0.1))
			LabSurface.polygon(c,PackedVector2Array([Vector2(half.x, -half.y), half, half - Vector2(6, 6), Vector2(half.x - 6, -half.y + 6)]), STEEL_DARK)
			LabSurface.rect(c,Rect2(-half + Vector2(6, 6), Vector2(w - 12, h - 12)), steel)
			LabSurface.line(c,Vector2(-8, -8), Vector2(8, 8), Color(1, 1, 1, 0.08), 3.0)
		"c_corner":
			LabSurface.rect(c,Rect2(-half.x, half.y - 14, w, 14), steel)
			LabSurface.rect(c,Rect2(-half.x, -half.y, 14, h - 14), steel)
			LabSurface.polygon(c,PackedVector2Array([Vector2(-half.x + 14, half.y - 14), Vector2(-half.x + 14, half.y - 30), Vector2(-half.x + 30, half.y - 14)]), steel.darkened(0.1))
			for p in [Vector2(-half.x + 7, -half.y + 10), Vector2(-half.x + 7, 6), Vector2(half.x - 10, half.y - 7), Vector2(-4, half.y - 7)]:
				_bolt(c, p)
		"c_triangle":
			var tri = PackedVector2Array([Vector2(-half.x, half.y), Vector2(half.x, half.y), Vector2(-half.x, -half.y)])
			LabSurface.polygon(c,tri, steel)
			c.draw_polyline(tri + PackedVector2Array([tri[0]]), STEEL_DARK, 2.0, true)
			LabSurface.circle(c,Vector2(-half.x * 0.35, half.y * 0.35), 7.0, Color("1a2328"))
			for p in [Vector2(-half.x + 6, half.y - 6), Vector2(half.x - 10, half.y - 6), Vector2(-half.x + 6, -half.y + 10)]:
				_bolt(c, p)
		"c_pipe":
			LabSurface.rect(c,Rect2(-half, Vector2(w, h)), Color("9aa9b2").lerp(Color("3a3f44"), 1.0 - condition))
			LabSurface.line(c,Vector2(-half.x, -half.y + 2), Vector2(half.x, -half.y + 2), Color(1, 1, 1, 0.35), 2.0)
			LabSurface.line(c,Vector2(-half.x, half.y - 1.5), Vector2(half.x, half.y - 1.5), STEEL_DARK, 1.5)
			for x in [-half.x + 3, half.x - 3]:
				LabSurface.rect(c,Rect2(x - 3, -half.y - 1, 6, h + 2), STEEL_DARK)
		"c_frame":
			var bar = 10.0
			for r in [Rect2(-half.x, -half.y, w, bar), Rect2(-half.x, half.y - bar, w, bar), Rect2(-half.x, -half.y, bar, h), Rect2(half.x - bar, -half.y, bar, h)]:
				LabSurface.rect(c,r, steel)
			LabSurface.line(c,Vector2(-half.x + bar, -half.y + bar), Vector2(half.x - bar, half.y - bar), steel.darkened(0.1), 3.0, true)
			for p in [-half + Vector2(5, 5), Vector2(half.x - 5, -half.y + 5), Vector2(-half.x + 5, half.y - 5), half - Vector2(5, 5)]:
				_bolt(c, p)
		"c_platform":
			LabSurface.rect(c,Rect2(-half, Vector2(w, h)), Color("5d6b74").lerp(Color("3a3f44"), 1.0 - condition))
			var x = -half.x + 4.0
			while x < half.x - 2.0:
				LabSurface.line(c,Vector2(x, -half.y + 1), Vector2(x + 5, half.y - 1), Color("8d9ba3"), 1.5)
				x += 8.0
			LabSurface.line(c,Vector2(-half.x, -half.y + 0.5), Vector2(half.x, -half.y + 0.5), AMBER, 1.0)
		"c_counterweight":
			LabSurface.rect(c,Rect2(-half, Vector2(w, h)), Color("2f3a42"))
			LabSurface.rect(c,Rect2(-half + Vector2(4, 4), Vector2(w - 8, h - 8)), Color("3d4a54"))
			for i in range(3):
				LabSurface.line(c,Vector2(-half.x + 6, -8 + i * 8), Vector2(half.x - 6, -8 + i * 8), Color("2a343b"), 2.0)
			LabSurface.rect(c,Rect2(-10, -half.y - 6, 20, 6), STEEL_DARK)
			LabSurface.rect(c,Rect2(-12, -6, 24, 12), AMBER.darkened(0.2))
			LabSurface.line(c,Vector2(-6, 0), Vector2(6, 0), Color("2f3a42"), 2.0)
		"c_hinge":
			LabSurface.circle(c,Vector2.ZERO, half.x, steel)
			c.draw_arc(Vector2.ZERO, half.x - 2.0, 0, TAU, 18, STEEL_LIGHT, 1.5, true)
			LabSurface.circle(c,Vector2.ZERO, 4.5, Color("1a2328"))
			LabSurface.circle(c,Vector2.ZERO, 2.2, AMBER)
		"c_axle":
			var r = half.x
			LabSurface.circle(c,Vector2.ZERO, r, Color("1c2328"))
			for i in range(12):
				var a = float(i) * TAU / 12.0
				LabSurface.line(c,Vector2.from_angle(a) * (r - 3.0), Vector2.from_angle(a) * r, Color("2d363c"), 2.0)
			LabSurface.circle(c,Vector2.ZERO, r * 0.6, STEEL_LIGHT)
			for i in range(4):
				var a = float(i) * TAU / 4.0
				LabSurface.line(c,Vector2.from_angle(a) * r * 0.15, Vector2.from_angle(a) * r * 0.58, STEEL_DARK, 3.0, true)
			LabSurface.circle(c,Vector2.ZERO, 4.0, AMBER)
		"c_motor":
			var r = half.x
			LabSurface.circle(c,Vector2.ZERO, r, Color("2f3a42"))
			for i in range(8):
				var a = float(i) * TAU / 8.0
				LabSurface.line(c,Vector2.from_angle(a) * (r - 6.0), Vector2.from_angle(a) * (r - 1.0), STEEL, 3.0)
			LabSurface.circle(c,Vector2.ZERO, r * 0.52, STEEL)
			LabSurface.circle(c,Vector2.ZERO, r * 0.22, Color("1a2328"))
			var glow = TEAL if active else Color("41505a")
			c.draw_arc(Vector2.ZERO, r * 0.78, -2.4, 0.4, 14, glow, 2.5, true)
			var tip = Vector2.from_angle(0.4 if gear >= 0 else -2.4) * r * 0.78
			LabSurface.circle(c,tip, 3.0, glow)
			if active: LabArt.soft_glow(c, Vector2.ZERO, r, Color(0.3, 1.0, 0.8, 1.0), 0.5)
		"c_spring":
			LabSurface.rect(c,Rect2(-half.x, -half.y, w, 6), STEEL_DARK)
			LabSurface.rect(c,Rect2(-half.x, half.y - 6, w, 6), STEEL_DARK)
			LabSurface.line(c,Vector2(0, -half.y + 6), Vector2(0, half.y - 6), STEEL_LIGHT, 3.0)
			var coils = 7
			var prev = Vector2(-half.x + 2, -half.y + 7)
			for i in range(1, coils * 2 + 1):
				var y = lerpf(-half.y + 7, half.y - 7, float(i) / float(coils * 2))
				var p = Vector2(half.x - 2 if i % 2 == 1 else -half.x + 2, y)
				LabSurface.line(c,prev, p, AMBER, 2.0, true)
				prev = p
		"c_jet":
			LabSurface.rect(c,Rect2(-half.x + 8, -half.y, w - 16, h), steel)
			LabSurface.polygon(c,PackedVector2Array([Vector2(half.x - 8, -half.y), Vector2(half.x, 0), Vector2(half.x - 8, half.y)]), STEEL_LIGHT)
			LabSurface.polygon(c,PackedVector2Array([Vector2(-half.x + 8, -half.y + 3), Vector2(-half.x, -half.y - 2), Vector2(-half.x, half.y + 2), Vector2(-half.x + 8, half.y - 3)]), STEEL_DARK)
			LabSurface.rect(c,Rect2(-10, -half.y, 4, h), Color("d62828"))
			if active:
				var flick = 16.0 + sin(Time.get_ticks_msec() * 0.05) * 5.0
				LabSurface.polygon(c,PackedVector2Array([Vector2(-half.x, -6), Vector2(-half.x - flick, 0), Vector2(-half.x, 6)]), Color(1.0, 0.55, 0.15, 0.9))
				LabSurface.polygon(c,PackedVector2Array([Vector2(-half.x, -3), Vector2(-half.x - flick * 0.55, 0), Vector2(-half.x, 3)]), Color(1.0, 0.95, 0.7))
		"c_balloon":
			var r = half.x
			LabSurface.line(c,Vector2(0, r), Vector2(0, r + 10), STEEL_LIGHT, 1.5)
			LabSurface.circle(c,Vector2.ZERO, r, Color("e76f51"))
			c.draw_arc(Vector2.ZERO, r - 1.0, 0, TAU, 28, Color("c44b30"), 2.0, true)
			for x in [-r * 0.45, 0.0, r * 0.45]:
				LabSurface.line(c,Vector2(x, -r * 0.9), Vector2(x * 0.5, r * 0.95), Color(0, 0, 0, 0.12), 1.5, true)
			LabSurface.circle(c,Vector2(-r * 0.35, -r * 0.4), r * 0.18, Color(1, 1, 1, 0.35))
			LabSurface.rect(c,Rect2(-6, r - 4, 12, 6), STEEL_DARK)
		"c_spikes":
			LabSurface.rect(c,Rect2(-half.x, 0, w, half.y), STEEL_DARK)
			var n = 6
			for i in range(n):
				var x0 = -half.x + float(i) * w / float(n)
				LabSurface.polygon(c,PackedVector2Array([Vector2(x0, 1), Vector2(x0 + w / float(n) * 0.5, -half.y), Vector2(x0 + w / float(n), 1)]), STEEL_LIGHT)
				LabSurface.line(c,Vector2(x0 + w / float(n) * 0.5, -half.y), Vector2(x0 + w / float(n) * 0.5, 0), Color(1, 1, 1, 0.35), 1.0)
		"c_wing":
			var foil = PackedVector2Array([Vector2(-half.x, half.y), Vector2(-half.x + 20, -half.y - 3), Vector2(half.x * 0.2, -half.y - 4), Vector2(half.x, 0), Vector2(half.x * 0.2, half.y)])
			LabSurface.polygon(c,foil, Color("d8e2e6").lerp(Color("3a3f44"), 1.0 - condition))
			LabSurface.line(c,Vector2(-half.x + 20, -half.y - 2), Vector2(half.x * 0.2, -half.y - 3), Color(1, 1, 1, 0.5), 1.5)
			LabSurface.line(c,Vector2(-half.x + 30, 1), Vector2(half.x - 10, 1), Color("8d9ba3"), 1.0)
			LabSurface.rect(c,Rect2(-half.x - 2, -2, 8, 4), Color("d62828"))

const AMBER = Color("ffbc70")
const TEAL = Color("4ce0bd")

static func draw_weld(c: CanvasItem, weld: Dictionary, motor_active: bool) -> void:
	# Крепления видны поверх деталей: болты у жёсткой сварки, кольцо у оси,
	# кольцо со стрелкой у мотора, пружина у амортизатора.
	match str(weld.type):
		"rigid":
			for j in weld.joints:
				if not is_instance_valid(j): continue
				var p = j.global_position
				LabSurface.circle(c,p, 4.2, Color("1a2328"))
				var hexa = PackedVector2Array()
				for i in range(6): hexa.append(p + Vector2.from_angle(float(i) * TAU / 6.0) * 3.4)
				LabSurface.polygon(c,hexa, STEEL_LIGHT)
		"pivot", "motor":
			for j in weld.joints:
				if not is_instance_valid(j): continue
				var p = j.global_position
				c.draw_arc(p, 7.0, 0, TAU, 18, AMBER if weld.type == "pivot" else TEAL, 2.0, true)
				LabSurface.circle(c,p, 2.5, AMBER if weld.type == "pivot" else TEAL)
				if weld.type == "motor" and motor_active:
					var a = Time.get_ticks_msec() * 0.008
					c.draw_arc(p, 11.0, a, a + 2.2, 12, TEAL, 2.0, true)
		"spring":
			if is_instance_valid(weld.a) and is_instance_valid(weld.b):
				var pa = weld.a.global_position
				var pb = weld.b.global_position
				var d = pb - pa
				var n = d.normalized().orthogonal() * 5.0
				var pts = PackedVector2Array([pa])
				for i in range(1, 12):
					pts.append(pa + d * float(i) / 12.0 + (n if i % 2 == 0 else -n))
				pts.append(pb)
				c.draw_polyline(pts, AMBER, 2.0, true)
