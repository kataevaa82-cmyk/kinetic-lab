class_name LabVehicle
extends RefCounted

# Машины. Кузов — обычный LabBody с формой из нескольких выпуклых многоугольников,
# колёса — отдельные круглые тела. Каждое колесо держат два шарнира: направляющая
# (GrooveJoint2D) пускает его только вверх-вниз вдоль стойки, пружина с демпфером
# (DampedSpringJoint2D) держит кузов на весу. Мотор крутит ведущие колёса к целевой
# угловой скорости, а реакция мотора уходит в кузов — поэтому на резком старте
# машина приседает на корму, а монстр-трак встаёт на задние колёса.
#
# Все координаты — в системе кузова, машина смотрит вправо, ось Y вниз.

const WHEEL = "veh_wheel"
const KINDS = [
	"car_sedan","car_pickup","car_monster","car_tank",
	"car_sport","car_bus","car_mixer","car_jeep","car_ambulance","car_fire","car_police","car_dozer",
	"car_tractor","car_moto","car_atv","car_kart","car_limo","car_apc","car_heli"
]
# Сирена звучит у служебных машин на ходу.
const SIRENS = ["car_ambulance","car_fire","car_police"]

const SPECS = {
	"car_sedan": {
		"mass": 70.0, "hp": 340.0, "dims": Vector2(160, 52), "color": Color("c9544a"),
		"hull": [
			[Vector2(-80,-4),Vector2(78,-6),Vector2(82,8),Vector2(74,18),Vector2(-74,18),Vector2(-82,8)],
			[Vector2(-46,-6),Vector2(-30,-31),Vector2(22,-31),Vector2(46,-6)]
		],
		"wheels": [[Vector2(-50,16),17.0,true],[Vector2(50,16),17.0,true]],
		"wheel_mass": 4.0, "travel_up": 10.0, "travel_down": 9.0, "sag": 5.0, "damp": 0.12,
		"speed": 680.0, "accel": 620.0, "grip": 1.25, "reaction": 0.35, "style": "road"
	},
	"car_pickup": {
		"mass": 120.0, "hp": 480.0, "dims": Vector2(196, 60), "color": Color("3f7fbf"),
		"hull": [
			[Vector2(-98,2),Vector2(96,2),Vector2(96,16),Vector2(-98,16)],
			[Vector2(-98,-24),Vector2(-90,-24),Vector2(-90,2),Vector2(-98,2)],
			[Vector2(14,-44),Vector2(50,-44),Vector2(66,-14),Vector2(66,4),Vector2(14,4)],
			[Vector2(60,-16),Vector2(96,-10),Vector2(96,4),Vector2(60,4)]
		],
		"wheels": [[Vector2(-62,19),21.0,true],[Vector2(62,19),21.0,true]],
		"wheel_mass": 6.0, "travel_up": 12.0, "travel_down": 10.0, "sag": 6.0, "damp": 0.14,
		"speed": 540.0, "accel": 520.0, "grip": 1.35, "reaction": 0.3, "style": "road"
	},
	"car_monster": {
		"mass": 85.0, "hp": 420.0, "dims": Vector2(172, 116), "color": Color("ffbc70"),
		"hull": [
			[Vector2(-72,-22),Vector2(72,-24),Vector2(78,-6),Vector2(-74,-6)],
			[Vector2(-36,-24),Vector2(-22,-48),Vector2(24,-48),Vector2(40,-24)]
		],
		"wheels": [[Vector2(-60,26),34.0,true],[Vector2(60,26),34.0,true]],
		"wheel_mass": 9.0, "travel_up": 22.0, "travel_down": 18.0, "sag": 12.0, "damp": 0.08,
		"speed": 620.0, "accel": 900.0, "grip": 1.5, "reaction": 0.75, "style": "monster"
	},
	"car_tank": {
		"mass": 260.0, "hp": 900.0, "dims": Vector2(200, 60), "color": Color("5f7a4e"),
		"hull": [
			[Vector2(-92,-6),Vector2(92,-6),Vector2(100,6),Vector2(84,18),Vector2(-84,18),Vector2(-98,6)],
			[Vector2(-40,-6),Vector2(-30,-30),Vector2(26,-30),Vector2(40,-6)],
			[Vector2(30,-24),Vector2(108,-24),Vector2(108,-16),Vector2(30,-16)]
		],
		"wheels": [[Vector2(-72,22),12.0,true],[Vector2(-36,22),12.0,true],[Vector2(0,22),12.0,true],[Vector2(36,22),12.0,true],[Vector2(72,22),12.0,true]],
		"wheel_mass": 7.0, "travel_up": 6.0, "travel_down": 5.0, "sag": 3.0, "damp": 0.2,
		"speed": 250.0, "accel": 340.0, "grip": 1.7, "reaction": 0.15, "style": "tank",
		"gun_range": 820.0, "gun_wait": 2.4
	},
	# Колесо: [точка крепления, радиус, ведущее, стиль (необязательно)].
	"car_sport": {
		"mass": 60.0, "hp": 300.0, "dims": Vector2(172, 40), "color": Color("ffd23f"),
		"hull": [
			[Vector2(-84,-2),Vector2(-20,-10),Vector2(40,-10),Vector2(86,0),Vector2(84,10),Vector2(-84,10)],
			[Vector2(-40,-10),Vector2(-18,-26),Vector2(16,-26),Vector2(44,-10)]
		],
		"wheels": [[Vector2(-54,6),15.0,true],[Vector2(56,6),15.0,true]],
		"wheel_mass": 3.5, "travel_up": 7.0, "travel_down": 6.0, "sag": 3.0, "damp": 0.15,
		"speed": 980.0, "accel": 850.0, "grip": 1.4, "reaction": 0.2, "style": "sport"
	},
	"car_bus": {
		"mass": 320.0, "hp": 700.0, "dims": Vector2(292, 90), "color": Color("3d9970"),
		"hull": [[Vector2(-146,-70),Vector2(140,-70),Vector2(146,-60),Vector2(146,16),Vector2(-146,16)]],
		"wheels": [[Vector2(-96,18),22.0,true],[Vector2(100,18),22.0,true]],
		"wheel_mass": 10.0, "travel_up": 10.0, "travel_down": 8.0, "sag": 5.0, "damp": 0.18,
		"speed": 420.0, "accel": 330.0, "grip": 1.35, "reaction": 0.1, "style": "road"
	},
	"car_mixer": {
		"mass": 260.0, "hp": 640.0, "dims": Vector2(250, 96), "color": Color("e07b39"),
		"hull": [
			[Vector2(-122,0),Vector2(118,0),Vector2(118,16),Vector2(-122,16)],
			[Vector2(62,-58),Vector2(96,-58),Vector2(118,-30),Vector2(118,2),Vector2(62,2)],
			[Vector2(-110,-10),Vector2(-96,-62),Vector2(-20,-78),Vector2(40,-56),Vector2(50,-10)]
		],
		"wheels": [[Vector2(-90,18),20.0,true],[Vector2(-46,18),20.0,true],[Vector2(84,18),20.0,true]],
		"wheel_mass": 9.0, "travel_up": 8.0, "travel_down": 7.0, "sag": 4.0, "damp": 0.18,
		"speed": 380.0, "accel": 300.0, "grip": 1.4, "reaction": 0.1, "style": "road"
	},
	"car_jeep": {
		"mass": 95.0, "hp": 460.0, "dims": Vector2(172, 80), "color": Color("4f6d7a"),
		"hull": [
			[Vector2(-80,-14),Vector2(80,-14),Vector2(84,8),Vector2(-82,8)],
			[Vector2(-52,-14),Vector2(-44,-44),Vector2(24,-44),Vector2(40,-14)]
		],
		"wheels": [[Vector2(-54,22),24.0,true],[Vector2(54,22),24.0,true]],
		"wheel_mass": 7.0, "travel_up": 16.0, "travel_down": 14.0, "sag": 8.0, "damp": 0.12,
		"speed": 560.0, "accel": 650.0, "grip": 1.6, "reaction": 0.4, "style": "monster"
	},
	"car_ambulance": {
		"mass": 150.0, "hp": 520.0, "dims": Vector2(210, 86), "color": Color("eef1ee"),
		"hull": [
			[Vector2(-104,-62),Vector2(40,-62),Vector2(40,14),Vector2(-104,14)],
			[Vector2(36,-46),Vector2(70,-46),Vector2(100,-14),Vector2(104,14),Vector2(36,14)]
		],
		"wheels": [[Vector2(-66,18),20.0,true],[Vector2(70,18),20.0,true]],
		"wheel_mass": 7.0, "travel_up": 11.0, "travel_down": 9.0, "sag": 6.0, "damp": 0.15,
		"speed": 600.0, "accel": 520.0, "grip": 1.35, "reaction": 0.25, "style": "road",
		"heal_radius": 190.0, "heal_rate": 24.0
	},
	"car_fire": {
		"mass": 280.0, "hp": 800.0, "dims": Vector2(260, 90), "color": Color("d62828"),
		"hull": [
			[Vector2(-128,-40),Vector2(70,-40),Vector2(70,14),Vector2(-128,14)],
			[Vector2(66,-60),Vector2(100,-60),Vector2(128,-26),Vector2(128,14),Vector2(66,14)]
		],
		"wheels": [[Vector2(-92,18),22.0,true],[Vector2(-50,18),22.0,true],[Vector2(96,18),22.0,true]],
		"wheel_mass": 10.0, "travel_up": 9.0, "travel_down": 8.0, "sag": 5.0, "damp": 0.18,
		"speed": 460.0, "accel": 360.0, "grip": 1.4, "reaction": 0.1, "style": "road",
		"hose_range": 520.0
	},
	"car_police": {
		"mass": 75.0, "hp": 380.0, "dims": Vector2(164, 56), "color": Color("1d3557"),
		"hull": [
			[Vector2(-80,-4),Vector2(78,-6),Vector2(82,8),Vector2(74,18),Vector2(-74,18),Vector2(-82,8)],
			[Vector2(-46,-6),Vector2(-30,-31),Vector2(22,-31),Vector2(46,-6)]
		],
		"wheels": [[Vector2(-50,16),17.0,true],[Vector2(50,16),17.0,true]],
		"wheel_mass": 4.0, "travel_up": 10.0, "travel_down": 9.0, "sag": 5.0, "damp": 0.12,
		"speed": 820.0, "accel": 760.0, "grip": 1.35, "reaction": 0.3, "style": "road",
		"stun_range": 320.0
	},
	"car_dozer": {
		"mass": 300.0, "hp": 950.0, "dims": Vector2(232, 84), "color": Color("f4a300"),
		"hull": [
			[Vector2(-96,-14),Vector2(60,-14),Vector2(60,14),Vector2(-96,14)],
			[Vector2(-70,-60),Vector2(-10,-60),Vector2(0,-14),Vector2(-80,-14)],
			[Vector2(92,-44),Vector2(112,-40),Vector2(116,24),Vector2(96,26)],
			[Vector2(56,-8),Vector2(96,-20),Vector2(96,-8),Vector2(56,4)]
		],
		"wheels": [[Vector2(-82,24),11.0,true],[Vector2(-50,24),11.0,true],[Vector2(-18,24),11.0,true],[Vector2(14,24),11.0,true],[Vector2(46,24),11.0,true]],
		"wheel_mass": 8.0, "travel_up": 5.0, "travel_down": 4.0, "sag": 2.0, "damp": 0.22,
		"speed": 190.0, "accel": 320.0, "grip": 1.9, "reaction": 0.1, "style": "tank"
	},
	"car_tractor": {
		"mass": 160.0, "hp": 600.0, "dims": Vector2(190, 120), "color": Color("3a7d44"),
		"hull": [
			[Vector2(-40,-40),Vector2(76,-30),Vector2(80,0),Vector2(-40,0)],
			[Vector2(-66,-96),Vector2(-14,-96),Vector2(-10,-36),Vector2(-70,-36)]
		],
		"wheels": [[Vector2(-44,6),38.0,true,"monster"],[Vector2(60,22),22.0,true,"road"]],
		"wheel_mass": 10.0, "travel_up": 6.0, "travel_down": 5.0, "sag": 3.0, "damp": 0.2,
		"speed": 270.0, "accel": 520.0, "grip": 1.8, "reaction": 0.5, "style": "monster"
	},
	"car_moto": {
		"mass": 45.0, "hp": 220.0, "dims": Vector2(130, 60), "color": Color("c1121f"),
		"hull": [
			[Vector2(-40,-20),Vector2(30,-26),Vector2(44,-4),Vector2(-30,4)],
			[Vector2(-30,-30),Vector2(20,-34),Vector2(26,-24),Vector2(-34,-20)]
		],
		"wheels": [[Vector2(-44,16),20.0,true],[Vector2(46,16),20.0,false]],
		"wheel_mass": 5.0, "travel_up": 9.0, "travel_down": 8.0, "sag": 5.0, "damp": 0.14,
		"speed": 860.0, "accel": 800.0, "grip": 1.5, "reaction": 0.45, "style": "sport",
		"balance": 1.0
	},
	"car_atv": {
		"mass": 55.0, "hp": 260.0, "dims": Vector2(124, 60), "color": Color("8338ec"),
		"hull": [
			[Vector2(-54,-22),Vector2(50,-24),Vector2(58,-6),Vector2(-58,-4)],
			[Vector2(-30,-34),Vector2(10,-34),Vector2(14,-22),Vector2(-34,-22)]
		],
		"wheels": [[Vector2(-38,8),19.0,true],[Vector2(40,8),19.0,true]],
		"wheel_mass": 5.0, "travel_up": 12.0, "travel_down": 10.0, "sag": 6.0, "damp": 0.1,
		"speed": 640.0, "accel": 750.0, "grip": 1.55, "reaction": 0.5, "style": "monster"
	},
	"car_kart": {
		"mass": 30.0, "hp": 160.0, "dims": Vector2(96, 34), "color": Color("ff006e"),
		"hull": [
			[Vector2(-44,-6),Vector2(40,-8),Vector2(46,4),Vector2(-46,4)],
			[Vector2(-26,-22),Vector2(-10,-22),Vector2(-6,-6),Vector2(-30,-6)]
		],
		"wheels": [[Vector2(-32,8),11.0,true],[Vector2(34,8),11.0,true]],
		"wheel_mass": 2.0, "travel_up": 4.0, "travel_down": 3.0, "sag": 2.0, "damp": 0.2,
		"speed": 760.0, "accel": 900.0, "grip": 1.4, "reaction": 0.2, "style": "sport"
	},
	"car_limo": {
		"mass": 160.0, "hp": 520.0, "dims": Vector2(282, 50), "color": Color("1b1e24"),
		"hull": [
			[Vector2(-138,-4),Vector2(136,-6),Vector2(140,8),Vector2(132,18),Vector2(-132,18),Vector2(-140,8)],
			[Vector2(-84,-6),Vector2(-66,-30),Vector2(56,-30),Vector2(80,-6)]
		],
		"wheels": [[Vector2(-100,16),18.0,true],[Vector2(102,16),18.0,true]],
		"wheel_mass": 5.0, "travel_up": 9.0, "travel_down": 8.0, "sag": 4.0, "damp": 0.15,
		"speed": 620.0, "accel": 450.0, "grip": 1.3, "reaction": 0.15, "style": "road"
	},
	"car_apc": {
		"mass": 240.0, "hp": 850.0, "dims": Vector2(210, 80), "color": Color("b39b6b"),
		"hull": [
			[Vector2(-100,-30),Vector2(70,-30),Vector2(104,-6),Vector2(100,14),Vector2(-100,14)],
			[Vector2(-30,-30),Vector2(-20,-46),Vector2(20,-46),Vector2(30,-30)]
		],
		"wheels": [[Vector2(-72,20),19.0,true],[Vector2(-26,20),19.0,true],[Vector2(26,20),19.0,true],[Vector2(72,20),19.0,true]],
		"wheel_mass": 8.0, "travel_up": 10.0, "travel_down": 8.0, "sag": 5.0, "damp": 0.18,
		"speed": 460.0, "accel": 420.0, "grip": 1.6, "reaction": 0.15, "style": "monster",
		"gun_range": 700.0, "gun_wait": 0.14
	},
	"car_heli": {
		"mass": 90.0, "hp": 400.0, "dims": Vector2(224, 80), "color": Color("2a9d8f"),
		"hull": [
			[Vector2(-30,-36),Vector2(30,-40),Vector2(56,-14),Vector2(44,10),Vector2(-36,10),Vector2(-44,-14)],
			[Vector2(-110,-28),Vector2(-40,-26),Vector2(-40,-14),Vector2(-110,-20)],
			[Vector2(-40,24),Vector2(46,24),Vector2(46,28),Vector2(-40,28)]
		],
		"wheels": [],
		"wheel_mass": 0.0, "travel_up": 0.0, "travel_down": 0.0, "sag": 1.0, "damp": 0.1,
		"speed": 340.0, "accel": 0.0, "grip": 1.0, "reaction": 0.0, "style": "road",
		"gears": [0, 2, 1, -1], "altitude": 300.0
	}
}

static func spec(kind: String) -> Dictionary:
	return SPECS.get(kind, {})

static func part_count(kind: String) -> int:
	return 1 + spec(kind).get("wheels", []).size()

# --------------------------------------------------------------------------
# Сборка
# --------------------------------------------------------------------------
static func add_hull_shapes(body: LabBody) -> void:
	for poly in spec(body.kind).hull:
		var shape = ConvexPolygonShape2D.new()
		shape.points = PackedVector2Array(poly)
		var collision = CollisionShape2D.new()
		collision.shape = shape
		body.add_child(collision)

static func setup_chassis(body: LabBody) -> void:
	var s = spec(body.kind)
	body.dimensions = s.dims
	body.mass = s.mass
	body.health = s.hp
	body.tint = s.color

static func build(game: Node2D, chassis: LabBody) -> void:
	# Колёса создаются один раз; rebuild() потом только ставит их на место и
	# пересоздаёт шарниры — после загрузки сцены, поворота или разморозки.
	var s = spec(chassis.kind)
	# Общее для тел сопротивление воздуха 0.25 съедало около 12% скорости: описание
	# обещало легковушке 680, а она выходила на 600. У машины его почти нет.
	chassis.linear_damp = 0.02
	for w in s.wheels:
		var wheel = LabBody.new()
		wheel.kind = WHEEL
		wheel.vehicle = chassis
		wheel.vehicle_style = str(w[3]) if w.size() > 3 else str(s.style)
		var r: float = w[1]
		wheel.dimensions = Vector2(r*2.0, r*2.0)
		wheel.mass = s.wheel_mass
		wheel.health = 900.0
		wheel.game = game
		wheel.serial = game.next_id()
		wheel.position = chassis.global_transform * (w[0] as Vector2)
		game.world.add_child(wheel)
		wheel.gravity_scale = wheel.gravity_factor if game.gravity else 0.0
		var mat = PhysicsMaterial.new()
		mat.friction = s.grip
		mat.bounce = 0.12
		wheel.physics_material_override = mat
		wheel.angular_damp = 0.05
		wheel.linear_damp = 0.05
		chassis.wheels.append(wheel)
	rebuild(game, chassis)

static func _exclude_self_collisions(chassis: LabBody) -> void:
	for a in chassis.wheels:
		if not is_instance_valid(a): continue
		a.add_collision_exception_with(chassis)
		chassis.add_collision_exception_with(a)
		for b in chassis.wheels:
			if is_instance_valid(b) and a != b: a.add_collision_exception_with(b)

static func rebuild(game: Node2D, chassis: LabBody) -> void:
	# Порядок важен. Шарнир Godot сам ведёт исключение столкновений у своей пары
	# тел: при настройке ставит его (disable_collision) или снимает, при удалении
	# снимает. Раньше старые шарниры уходили через queue_free уже после создания
	# новых и снимали исключение с новой пары — колесо упиралось в корпус изнутри,
	# и после загрузки сцены машину подбрасывало и переворачивало. Поэтому старые
	# удаляем сразу, а новые создаём после.
	for j in chassis.vehicle_joints:
		if is_instance_valid(j): j.free()
	chassis.vehicle_joints.clear()
	var s = spec(chassis.kind)
	var xf: Transform2D = chassis.global_transform
	var per_wheel_load = float(s.mass) * 900.0 / float(maxi(s.wheels.size(), 1))
	for i in range(mini(s.wheels.size(), chassis.wheels.size())):
		var wheel: LabBody = chassis.wheels[i]
		if not is_instance_valid(wheel): continue
		var mount: Vector2 = s.wheels[i][0]
		var up: float = s.travel_up
		var down: float = s.travel_down
		# Колесо ставим туда, где оно окажется под весом кузова, чтобы машина
		# не подпрыгивала при каждом появлении и загрузке.
		wheel.global_position = xf * mount
		wheel.linear_velocity = chassis.linear_velocity
		wheel.freeze = chassis.freeze
		var groove = GrooveJoint2D.new()
		game.world.add_child(groove)
		groove.global_transform = xf * Transform2D(0.0, mount - Vector2(0, up))
		groove.length = up + down
		groove.initial_offset = up
		groove.disable_collision = true
		groove.node_a = groove.get_path_to(chassis)
		groove.node_b = groove.get_path_to(wheel)
		chassis.vehicle_joints.append(groove)
		# Пружина: верхняя точка на кузове, нижняя в центре колеса. Жёсткость
		# подобрана так, чтобы под своим весом машина садилась ровно на "sag".
		var arm = up + 26.0
		var spring = DampedSpringJoint2D.new()
		game.world.add_child(spring)
		spring.global_transform = xf * Transform2D(0.0, mount - Vector2(0, arm))
		spring.length = arm
		var stiffness = per_wheel_load / maxf(float(s.sag), 1.0)
		spring.stiffness = stiffness
		spring.rest_length = arm + float(s.sag)
		# Демпфер Godot гасит за шаг долю 1-exp(-damping*dt*k) относительной
		# скорости, где k — сумма обратных масс. "damp" в SPECS — именно эта доля,
		# так что подвеска гасится одинаково у лёгкой легковушки и у танка.
		var k_inv = 1.0 / float(s.mass) + 1.0 / float(s.wheel_mass)
		var step = 1.0 / float(Engine.physics_ticks_per_second)
		spring.damping = -log(1.0 - clampf(float(s.damp), 0.01, 0.9)) / (step * k_inv)
		spring.disable_collision = true
		spring.node_a = spring.get_path_to(chassis)
		spring.node_b = spring.get_path_to(wheel)
		chassis.vehicle_joints.append(spring)
	_exclude_self_collisions(chassis)
	chassis.queue_redraw()

static func bodies(body: LabBody) -> Array:
	var chassis = root(body)
	if chassis == null: return [body]
	var out: Array = [chassis]
	for w in chassis.wheels:
		if is_instance_valid(w): out.append(w)
	return out

static func root(body: LabBody) -> LabBody:
	if not is_instance_valid(body): return null
	if body.kind in KINDS: return body
	if body.kind == WHEEL and is_instance_valid(body.vehicle): return body.vehicle
	return null

static func free_joints(chassis: LabBody) -> void:
	for j in chassis.vehicle_joints:
		if is_instance_valid(j): j.free()
	chassis.vehicle_joints.clear()

# --------------------------------------------------------------------------
# Езда
# --------------------------------------------------------------------------
static func gears(kind: String) -> Array:
	return spec(kind).get("gears", [0, 1, -1])

static func gear_label(game: Node2D, g: int, kind: String = "") -> String:
	if kind == "car_heli" and g == 0: return game.t("Посадка", "Landing")
	match g:
		1: return game.t("Вперёд", "Forward")
		-1: return game.t("Назад", "Reverse")
		2: return game.t("Висеть", "Hover")
	return game.t("Стоп", "Stop")

static func cycle_gear(chassis: LabBody) -> int:
	if chassis.health <= 0.0: return 0
	var list = gears(chassis.kind)
	var i = list.find(chassis.gear)
	chassis.gear = list[(i + 1) % list.size()]
	chassis.active = chassis.gear != 0
	return chassis.gear

# Передача напрямую — кнопками в панели объекта. false, если такой передачи
# у машины нет или она уже включена.
static func set_gear(chassis: LabBody, g: int) -> bool:
	if chassis.health <= 0.0 or g not in gears(chassis.kind) or chassis.gear == g: return false
	chassis.gear = g
	chassis.active = g != 0
	return true

# Порядок кнопок передач в панели: слева назад, справа вперёд.
static func gear_buttons(kind: String) -> Array:
	return [0, 2, -1, 1] if kind == "car_heli" else [-1, 0, 1]

static func gear_button_label(game: Node2D, g: int, kind: String) -> String:
	if kind == "car_heli":
		match g:
			0: return game.t("Сесть", "Land")
			2: return game.t("Висеть", "Hover")
			-1: return "◀"
			1: return "▶"
	match g:
		-1: return game.t("◀ Назад", "◀ Rev")
		1: return game.t("Вперёд ▶", "Fwd ▶")
	return game.t("Стоп", "Stop")

static func drive(game: Node2D, chassis: LabBody, delta: float) -> void:
	var s = spec(chassis.kind)
	chassis.ability_cooldown = maxf(0.0, chassis.ability_cooldown - delta)
	chassis.boost = maxf(0.0, chassis.boost - delta)
	if chassis.health <= 0.0:
		chassis.gear = 0
		chassis.active = false
		chassis.boost = 0.0
	if chassis.kind == "car_heli":
		_fly(game, chassis, s, delta)
		return
	if s.has("balance") and not chassis.wrecked and not chassis.freeze:
		_balance(chassis)
	chassis.payload = maxf(0.0, chassis.payload - delta)
	if chassis.gear != 0 and chassis.kind in SIRENS and chassis.payload <= 0.0:
		chassis.payload = 1.7
		game.play_sound("siren", 0.22)
	if chassis.gear != 0 and not chassis.freeze:
		match chassis.kind:
			"car_apc": _apc_gun(game, chassis, s)
			"car_fire": _fire_hose(game, chassis, s)
			"car_ambulance": _heal(game, chassis, s, delta)
			"car_police": _stun(game, chassis, s)
	var dir = float(chassis.gear)
	var driven: Array = []
	for i in range(chassis.wheels.size()):
		var w = chassis.wheels[i]
		if is_instance_valid(w) and not w.freeze and s.wheels[i][2]: driven.append(w)
	if chassis.freeze or driven.is_empty(): return
	var roll = 0.0
	for w in driven: roll += w.angular_velocity * w.dimensions.x * 0.5
	chassis.track_phase += roll / driven.size() * delta
	var total_mass = float(s.mass) + float(s.wheel_mass) * chassis.wheels.size()
	if chassis.boost > 0.0:
		_nitro_burn(game, chassis, s, total_mass)
	# Под нитро мотор не душит разгон на своей обычной максималке.
	var top_speed = float(s.speed) * (1.5 if chassis.boost > 0.0 else 1.0)
	var reaction = 0.0
	for w in driven:
		var r: float = w.dimensions.x * 0.5
		if dir == 0.0:
			# Мотор выключен — лёгкое сопротивление качению, но не тормоз.
			w.apply_torque(-w.angular_velocity * w.mass * r * r * 0.4)
			continue
		var target = dir * top_speed / r
		# Сила, которая разгоняет машину с заданным ускорением, раскладывается
		# поровну на ведущие колёса и переводится в крутящий момент.
		var max_torque = total_mass * float(s.accel) * r / driven.size()
		var torque = clampf((target - w.angular_velocity) * w.mass * r * r * 90.0, -max_torque, max_torque)
		w.apply_torque(torque)
		reaction -= torque
	if dir != 0.0:
		# Передача против хода — это ещё и тормоз: неведущие колёса тоже
		# останавливаются. Иначе мотоцикл, у которого ведёт только заднее
		# колесо, после "назад" на полном ходу секунду катился вперёд юзом.
		var along = chassis.linear_velocity.dot(Vector2.RIGHT.rotated(chassis.rotation))
		if along * dir < -30.0:
			for i in range(chassis.wheels.size()):
				var w = chassis.wheels[i]
				if not is_instance_valid(w) or s.wheels[i][2]: continue
				var r: float = w.dimensions.x * 0.5
				var cap = total_mass * float(s.accel) * r / chassis.wheels.size()
				w.apply_torque(clampf(-w.angular_velocity * w.mass * r * r * 30.0, -cap, cap))
		chassis.apply_torque(reaction * float(s.reaction))
		if Engine.get_physics_frames() % 5 == 0 and is_instance_valid(game) and game.fx.particles.size() < 480:
			var back = chassis.global_transform * Vector2(-float(s.dims.x) * 0.5, 8)
			game.fx.particles.append({"p": back, "v": Vector2(randf_range(-30, 10) - dir * 40.0, randf_range(-50, -20)), "life": 0.7, "max_life": 0.7, "c": Color(0.55, 0.6, 0.65, 0.5), "s": randf_range(3.0, 6.0), "gravity": -30.0, "glow": false, "smoke": true})
	if chassis.kind == "car_tank" and dir != 0.0:
		_tank_gun(game, chassis, s)

static func _tank_gun(game: Node2D, chassis: LabBody, s: Dictionary) -> void:
	if chassis.mechanism_cooldown > 0.0: return
	var aim = Vector2.RIGHT.rotated(chassis.rotation)
	var muzzle = chassis.global_transform * Vector2(112, -20)
	var best: Node2D = null
	var best_d = float(s.gun_range)
	for robot in game.get_tree().get_nodes_in_group("robots"):
		if robot.dead or robot.parts.size() < 2: continue
		var to = robot.parts[1].global_position - muzzle
		var d = to.length()
		if d < best_d and aim.dot(to / maxf(d, 1.0)) > 0.93:
			best_d = d
			best = robot
	if best == null: return
	_tank_fire(game, chassis, s)

static func _tank_fire(game: Node2D, chassis: LabBody, s: Dictionary) -> void:
	var aim = Vector2.RIGHT.rotated(chassis.rotation)
	var muzzle = chassis.global_transform * Vector2(112, -20)
	chassis.mechanism_cooldown = float(s.gun_wait)
	game._spawn_projectile("cannonball", muzzle, aim * 820.0, 55.0, chassis)
	for w in chassis.wheels:
		if is_instance_valid(w):
			for shot in game.get_tree().get_nodes_in_group("bodies"):
				if shot.kind == "cannonball" and shot.source == chassis: shot.add_collision_exception_with(w)
	chassis.apply_impulse(-aim * 5200.0, aim * 60.0)
	game.fx.flash(muzzle, 34.0, Color(1.0, 0.85, 0.5))
	game.fx.emit_sparks(muzzle, 14, LabArt.AMBER, aim * 260.0)
	game.camera_shake = maxf(game.camera_shake, 4.0)
	game.play_sound("shot_heavy", 0.6)

static func _robot_ahead(game: Node2D, chassis: LabBody, from: Vector2, reach: float, cone: float) -> Node2D:
	return _nearest_robot(game, from, Vector2.RIGHT.rotated(chassis.rotation) * signf(float(chassis.gear)), reach, cone)

# Ближайший живой робот в конусе вокруг aim; cone меньше -1 — в любую сторону.
static func _nearest_robot(game: Node2D, from: Vector2, aim: Vector2, reach: float, cone: float) -> Node2D:
	var best: Node2D = null
	var best_d = reach
	for robot in game.get_tree().get_nodes_in_group("robots"):
		if robot.dead or robot.parts.size() < 2: continue
		var to = robot.parts[1].global_position - from
		var d = to.length()
		if d < best_d and aim.dot(to / maxf(d, 1.0)) > cone:
			best_d = d
			best = robot
	return best

static func _apc_gun(game: Node2D, chassis: LabBody, s: Dictionary) -> void:
	# Спаренный пулемёт в башне: короткие очереди по роботу впереди.
	if chassis.mechanism_cooldown > 0.0 or chassis.gear != 1: return
	var muzzle = chassis.global_transform * Vector2(84, -40)
	var target = _robot_ahead(game, chassis, muzzle, float(s.gun_range), 0.95)
	if target == null: return
	chassis.mechanism_cooldown = float(s.gun_wait)
	var aim = (target.parts[1].global_position - muzzle).normalized().rotated(randf_range(-0.03, 0.03))
	game._spawn_projectile("slug", muzzle, aim * 1500.0, 12.0, chassis)
	game.fx.emit_sparks(muzzle, 4, LabArt.AMBER, aim * 180.0)
	game.play_sound("shot", 0.22)

static func _fire_hose(game: Node2D, chassis: LabBody, s: Dictionary) -> void:
	# Лафетный ствол на лестнице бьёт пеной по ближайшему горящему телу.
	if chassis.mechanism_cooldown > 0.0: return
	var nozzle = chassis.global_transform * Vector2(64, -62)
	var best: LabBody = null
	var best_d = float(s.hose_range)
	for body in game.get_tree().get_nodes_in_group("bodies"):
		if body.burning <= 0.0 or LabVehicle.root(body) == chassis or body.kind in game.EPHEMERAL: continue
		var d = body.global_position.distance_to(nozzle)
		if d < best_d:
			best_d = d
			best = body
	if best == null: return
	chassis.mechanism_cooldown = 0.12
	var aim = (best.global_position - nozzle).normalized()
	for i in range(3):
		game._spawn_projectile("foam", nozzle, aim.rotated(randf_range(-0.12, 0.12)) * randf_range(520.0, 680.0) + Vector2(0, -60), 0.0, chassis)
	game.play_sound("spray", 0.3)

static func _heal(game: Node2D, chassis: LabBody, s: Dictionary, delta: float) -> void:
	# Скорая на ходу чинит роботов рядом, а павших поднимает — раз в секунду.
	var radius = float(s.heal_radius)
	for robot in game.get_tree().get_nodes_in_group("robots"):
		if robot.parts.size() < 2: continue
		if robot.parts[1].global_position.distance_to(chassis.global_position) > radius: continue
		if robot.dead:
			if chassis.mechanism_cooldown <= 0.0:
				chassis.mechanism_cooldown = 1.0
				robot.restore()
				game.fx.emit_sparks(robot.parts[1].global_position, 20, Color("65e39a"), Vector2.UP * 60)
				game.play_sound("revive", 0.4)
				game.notify(game.t("Скорая подняла робота", "The ambulance revived a robot"))
		elif robot.health < robot.max_health:
			robot.health = minf(robot.max_health, robot.health + float(s.heal_rate) * delta)
			if Engine.get_physics_frames() % 12 == 0:
				game.fx.emit_sparks(robot.parts[1].global_position, 2, Color("65e39a"), Vector2.UP * 40)

static func _stun(game: Node2D, chassis: LabBody, s: Dictionary) -> void:
	# Полиция задерживает: робот перед машиной оглушён и не сопротивляется.
	if chassis.mechanism_cooldown > 0.0: return
	chassis.mechanism_cooldown = 0.4
	var target = _robot_ahead(game, chassis, chassis.global_position, float(s.stun_range), 0.75)
	if target == null: return
	target.stun = maxf(target.stun, 0.8)
	game.fx.beam(chassis.global_transform * Vector2(0, -34), target.parts[1].global_position)
	game.play_sound("zap", 0.18)

static func _balance(chassis: LabBody) -> void:
	# Гироскоп мотоцикла: без него двухколёсная машина падает набок на месте.
	# Момент ограничен, поэтому сильный удар или взрыв мотоцикл всё же роняет.
	var ang = wrapf(chassis.rotation, -PI, PI)
	var torque = clampf(-ang * 16000.0 - chassis.angular_velocity * 2200.0, -30000.0, 30000.0) * chassis.mass
	chassis.apply_torque(torque)

static func _fly(game: Node2D, chassis: LabBody, s: Dictionary, delta: float) -> void:
	# Вертолёт без колёс: несущий винт — это сила вверх, которая держит высоту,
	# наклон корпуса — горизонтальная тяга. На "стоп" винт раскручивается вниз
	# и мягко сажает машину, а не роняет её.
	var spin = 0.0
	if chassis.freeze:
		chassis.queue_redraw()
		return
	var gs = chassis.gravity_scale
	var m = chassis.mass
	var v = chassis.linear_velocity
	var fx := 0.0
	var fy := 0.0
	var target_rot := 0.0
	if chassis.wrecked:
		spin = 2.0
	elif chassis.gear == 0:
		spin = 12.0
		fy = clampf((140.0 - v.y) * m * 4.0, -m * 900.0 * gs, 0.0)
		fx = -v.x * m * 1.2
	else:
		spin = 46.0
		var target_y = game.FLOOR_Y - float(s.altitude)
		var want_vy = clampf((target_y - chassis.global_position.y) * 1.8, -260.0, 260.0)
		fy = (want_vy - v.y) * m * 5.0 - m * 900.0 * gs
		var dir = 0.0 if chassis.gear == 2 else float(chassis.gear)
		fx = (dir * float(s.speed) - v.x) * m * 2.5
		target_rot = clampf(v.x / float(s.speed), -1.0, 1.0) * 0.16
		if Engine.get_physics_frames() % 6 == 0: game.play_sound("rotor", 0.2)
	if not chassis.wrecked:
		chassis.apply_central_force(Vector2(fx, fy))
		var err = wrapf(chassis.rotation - target_rot, -PI, PI)
		chassis.apply_torque(clampf(-err * 20000.0 - chassis.angular_velocity * 3000.0, -40000.0, 40000.0) * m)
		# Лебёдка выбирает трос: зацепленный груз поднимается под брюхо, а не
		# волочится по полу на всю длину, с которой его подцепили.
		for link in game.links:
			if (link.a == chassis or link.b == chassis) and is_instance_valid(link.joint) and link.joint.rest_length > WINCH_LENGTH:
				link.joint.rest_length = maxf(WINCH_LENGTH, link.joint.rest_length - 170.0 * delta)
	chassis.track_phase += spin * delta
	chassis.queue_redraw()

# --------------------------------------------------------------------------
# Действия. F переключает передачу, V — второе действие, своё у каждой машины.
# Автоматика служебных машин (пушка на ходу, пена по огню, лечение) остаётся:
# кнопка даёт то же самое по команде, в том числе на стоянке.
# --------------------------------------------------------------------------
const ABILITIES = {
	"car_sedan": "horn", "car_limo": "horn", "car_bus": "horn", "car_mixer": "horn",
	"car_pickup": "dump",
	"car_monster": "jump", "car_jeep": "jump", "car_atv": "jump", "car_moto": "jump",
	"car_sport": "nitro", "car_kart": "nitro",
	"car_tank": "cannon", "car_apc": "burst",
	"car_fire": "foam", "car_ambulance": "repair", "car_police": "arrest",
	"car_dozer": "shove", "car_tractor": "tow", "car_heli": "winch"
}
# Перезарядка после действия, секунды. У пушки танка — её gun_wait.
const ABILITY_WAIT = {
	"horn": 0.7, "dump": 1.0, "jump": 1.1, "nitro": 2.5, "burst": 1.2, "foam": 0.8,
	"repair": 4.0, "arrest": 2.0, "shove": 1.2, "tow": 0.4, "winch": 0.4
}
const NITRO_TIME = 1.1
const WINCH_LENGTH = 110.0

static func ability(kind: String) -> String:
	return str(ABILITIES.get(kind, ""))

static func ability_label(game: Node2D, chassis: LabBody) -> String:
	match ability(chassis.kind):
		"horn": return game.t("Сигнал", "Horn")
		"dump": return game.t("Сброс", "Dump")
		"jump": return game.t("Прыжок", "Jump")
		"nitro": return game.t("Нитро", "Nitro")
		"cannon": return game.t("Выстрел", "Fire")
		"burst": return game.t("Очередь", "Burst")
		"foam": return game.t("Пена", "Foam")
		"repair": return game.t("Ремонт", "Repair")
		"arrest": return game.t("Арест", "Arrest")
		"shove": return game.t("Толчок", "Shove")
		"tow": return game.t("Отцепить", "Unhitch") if hooked(game, chassis) else game.t("Буксир", "Tow")
		"winch": return game.t("Отцепить", "Release") if hooked(game, chassis) else game.t("Трос", "Winch")
	return ""

# Сколько перезарядки осталось, 0..1 — для полоски под кнопкой.
static func ability_wait(chassis: LabBody) -> float:
	var id = ability(chassis.kind)
	if id == "cannon":
		var full = float(spec(chassis.kind).gun_wait)
		return clampf(maxf(chassis.mechanism_cooldown, chassis.ability_cooldown) / full, 0.0, 1.0)
	return clampf(chassis.ability_cooldown / float(ABILITY_WAIT.get(id, 1.0)), 0.0, 1.0)

# Прицеплена ли к машине связь. Буксир и трос — обычные связи лаборатории,
# поэтому сохраняются со сценой; «Отцепить» снимает и связи, поставленные вручную.
static func hooked(game: Node2D, chassis: LabBody) -> bool:
	for link in game.links:
		if link.a == chassis or link.b == chassis: return true
	return false

static func use_ability(game: Node2D, chassis: LabBody) -> bool:
	if chassis.wrecked or chassis.health <= 0.0:
		game.notify(game.t("Машина разбита и не заводится", "The vehicle is wrecked and will not start"))
		return false
	if chassis.freeze:
		game.notify(game.t("Машина заморожена", "The vehicle is frozen"))
		return false
	var s = spec(chassis.kind)
	var id = ability(chassis.kind)
	if chassis.ability_cooldown > 0.0 or (id == "cannon" and chassis.mechanism_cooldown > 0.0): return false
	var done = false
	match id:
		"horn": done = _horn(game, chassis)
		"dump": done = _dump(game, chassis)
		"jump": done = _jump(game, chassis)
		"nitro": done = _nitro(game, chassis)
		"cannon":
			_tank_fire(game, chassis, s)
			done = true
		"burst": done = _burst(game, chassis, s)
		"foam": done = _foam(game, chassis, s)
		"repair": done = _repair(game, chassis, s)
		"arrest": done = _arrest(game, chassis, s)
		"shove": done = _shove(game, chassis)
		"tow", "winch": done = _hook(game, chassis, id)
	if done and ABILITY_WAIT.has(id): chassis.ability_cooldown = float(ABILITY_WAIT[id])
	return done

static func _forward(chassis: LabBody) -> Vector2:
	return Vector2.RIGHT.rotated(chassis.rotation)

# Тела, которые может задеть действие: не свои части, не снаряды и не лужи.
static func _others(game: Node2D, chassis: LabBody) -> Array:
	var out: Array = []
	for body in game.get_tree().get_nodes_in_group("bodies"):
		if body.is_queued_for_deletion() or root(body) == chassis: continue
		if body.kind in game.EPHEMERAL or body.kind in game.FLUIDS: continue
		out.append(body)
	return out

static func _horn(game: Node2D, chassis: LabBody) -> bool:
	# Гудок: роботы перед машиной отскакивают с дороги.
	game.play_sound("horn", 0.5)
	var nose = _forward(chassis)
	var at = chassis.global_position
	for robot in game.get_tree().get_nodes_in_group("robots"):
		if robot.dead or robot.parts.size() < 2: continue
		var to: Vector2 = robot.parts[1].global_position - at
		var d = to.length()
		if d > 340.0 or nose.dot(to / maxf(d, 1.0)) < 0.2: continue
		var hop = (Vector2(signf(to.x) if absf(to.x) > 1.0 else 1.0, 0.0) * 0.6 + Vector2.UP).normalized() * 340.0
		for p in robot.parts:
			if is_instance_valid(p) and not p.freeze: p.apply_central_impulse(hop * p.mass)
	game.fx.emit_sparks(chassis.global_transform * Vector2(float(spec(chassis.kind).dims.x) * 0.5, -4), 6, Color("fff2c2"), nose * 160.0)
	return true

static func _dump(game: Node2D, chassis: LabBody) -> bool:
	# Пикап вскидывает кузов: всё, что лежит в нём, летит назад и вверх.
	var bed = Rect2(-98, -130, 112, 132)
	var kick = chassis.global_transform.basis_xform(Vector2(-0.5, -1.0).normalized()) * 520.0
	var moved: Dictionary = {}
	for body in _others(game, chassis):
		if body.freeze or not bed.has_point(chassis.to_local(body.global_position)): continue
		var group: Array = body.ragdoll.parts if is_instance_valid(body.ragdoll) else [body]
		for p in group:
			if is_instance_valid(p) and not moved.has(p):
				moved[p] = true
				p.apply_central_impulse(kick * p.mass)
	if moved.is_empty():
		game.notify(game.t("Кузов пуст", "The bed is empty"))
		return false
	game.fx.emit_sparks(chassis.global_transform * Vector2(-44, -4), 8, Color(0.72, 0.66, 0.55), kick * 0.25)
	game.play_sound("thunk", 0.5)
	return true

static func _jump(game: Node2D, chassis: LabBody) -> bool:
	var grounded = false
	# Уснувшее колесо контактов не сообщает, но спит оно только стоя на чём-то:
	# иначе давно припаркованная машина «не касалась бы земли».
	for w in chassis.wheels:
		if is_instance_valid(w) and (w.get_contact_count() > 0 or w.sleeping): grounded = true
	if not grounded:
		game.notify(game.t("Прыгать можно только с земли", "Jumping needs the wheels on the ground"))
		return false
	# Вверх по оси кузова, наполовину выпрямленной: на склоне прыжок уходит
	# чуть вперёд, но перевёрнутую машину в пол не вбивает.
	var up = Vector2.UP.rotated(wrapf(chassis.rotation, -PI, PI) * 0.5)
	for b in bodies(chassis):
		b.apply_central_impulse(up * 560.0 * b.mass)
	for w in chassis.wheels:
		if is_instance_valid(w): game.fx.emit_sparks(w.global_position + Vector2(0, float(w.dimensions.y) * 0.5), 6, Color(0.6, 0.64, 0.66), Vector2.UP * 60.0)
	game.play_sound("whoosh", 0.45)
	return true

static func _nitro(game: Node2D, chassis: LabBody) -> bool:
	chassis.boost = NITRO_TIME
	game.play_sound("rocket", 0.5)
	return true

static func _nitro_burn(game: Node2D, chassis: LabBody, s: Dictionary, total_mass: float) -> void:
	# Ускоритель толкает машину по ходу передачи, на нейтрали — вперёд.
	var dir = -1.0 if chassis.gear == -1 else 1.0
	chassis.apply_central_force(_forward(chassis) * dir * total_mass * 900.0)
	if Engine.get_physics_frames() % 2 == 0:
		var back = chassis.global_transform * Vector2(-float(s.dims.x) * 0.5 * dir, 2)
		game.fx.emit_sparks(back, 3, Color(0.45, 0.75, 1.0), -_forward(chassis) * dir * 260.0)

static func _burst(game: Node2D, chassis: LabBody, s: Dictionary) -> bool:
	# Очередь из шести пуль — по роботу впереди, а если его нет, прямо по курсу.
	var muzzle = chassis.global_transform * Vector2(84, -40)
	var aim = _forward(chassis)
	var target = _nearest_robot(game, muzzle, aim, float(s.gun_range), 0.8)
	if target: aim = (target.parts[1].global_position - muzzle).normalized()
	for i in range(6):
		game._spawn_projectile("slug", muzzle - aim * float(i) * 20.0, aim.rotated(randf_range(-0.04, 0.04)) * 1500.0, 12.0, chassis)
	game.fx.flash(muzzle, 20.0, Color(1.0, 0.9, 0.6))
	game.fx.emit_sparks(muzzle, 10, LabArt.AMBER, aim * 200.0)
	game.camera_shake = maxf(game.camera_shake, 1.8)
	game.play_sound("shot", 0.4)
	return true

static func _foam(game: Node2D, chassis: LabBody, s: Dictionary) -> bool:
	# Залп пены: в ближайший огонь, а без огня — вперёд и вверх дугой.
	var nozzle = chassis.global_transform * Vector2(64, -62)
	var aim = chassis.global_transform.basis_xform(Vector2(0.9, -0.45)).normalized()
	var best_d = float(s.hose_range)
	for body in _others(game, chassis):
		if body.burning <= 0.0: continue
		var d = body.global_position.distance_to(nozzle)
		if d < best_d:
			best_d = d
			aim = (body.global_position - nozzle).normalized()
	for i in range(14):
		game._spawn_projectile("foam", nozzle, aim.rotated(randf_range(-0.16, 0.16)) * randf_range(480.0, 720.0) + Vector2(0, -60), 0.0, chassis)
	# Себя пожарная тоже заливает.
	if chassis.burning > 0.0: chassis.douse(1.0)
	game.play_sound("spray", 0.5)
	return true

static func _repair(game: Node2D, chassis: LabBody, s: Dictionary) -> bool:
	# Полный ремонт всех роботов в полуторном радиусе: павшие встают.
	var radius = float(s.heal_radius) * 1.5
	var count = 0
	for robot in game.get_tree().get_nodes_in_group("robots"):
		if robot.parts.size() < 2: continue
		var at: Vector2 = robot.parts[1].global_position
		if at.distance_to(chassis.global_position) > radius: continue
		if not robot.dead and robot.health >= robot.max_health: continue
		# Живого только лечим: restore() ещё и размораживает пластины.
		if robot.dead: robot.restore()
		else: robot.health = robot.max_health
		count += 1
		game.fx.beam(chassis.global_transform * Vector2(-20, -62), at)
		game.fx.emit_sparks(at, 18, Color("65e39a"), Vector2.UP * 60.0)
	if count == 0:
		game.notify(game.t("Рядом нет повреждённых роботов", "No damaged robots nearby"))
		return false
	game.play_sound("revive", 0.45)
	game.notify(game.t("Скорая починила роботов: ", "Robots repaired: ") + str(count))
	return true

static func _arrest(game: Node2D, chassis: LabBody, s: Dictionary) -> bool:
	# Задержание: ближайший робот в любую сторону оглушён на три секунды.
	var from = chassis.global_transform * Vector2(0, -34)
	var target = _nearest_robot(game, from, Vector2.ZERO, float(s.stun_range) * 1.25, -2.0)
	if target == null:
		game.notify(game.t("Рядом нет роботов", "No robots nearby"))
		return false
	target.stun = maxf(target.stun, 3.0)
	game.fx.beam(from, target.parts[1].global_position)
	game.play_sound("zap", 0.4)
	game.play_sound("siren", 0.3)
	return true

static func _shove(game: Node2D, chassis: LabBody) -> bool:
	# Отвал бьёт вперёд: всё в полосе перед ним отлетает.
	var zone = Rect2(70, -150, 190, 190)
	var push = chassis.global_transform.basis_xform(Vector2(1.0, -0.35).normalized()) * 620.0
	for body in _others(game, chassis):
		if body.freeze or not zone.has_point(chassis.to_local(body.global_position)): continue
		body.apply_central_impulse(push * body.mass)
		body.sleeping = false
	chassis.apply_central_impulse(-_forward(chassis) * chassis.mass * 60.0)
	game.fx.emit_sparks(chassis.global_transform * Vector2(116, 0), 12, Color(0.72, 0.66, 0.55), push * 0.3)
	game.camera_shake = maxf(game.camera_shake, 3.0)
	game.play_sound("metal", 0.45)
	return true

static func _hook(game: Node2D, chassis: LabBody, id: String) -> bool:
	if hooked(game, chassis):
		for i in range(game.links.size() - 1, -1, -1):
			var link = game.links[i]
			if link.a != chassis and link.b != chassis: continue
			if is_instance_valid(link.joint): link.joint.queue_free()
			game.links.remove_at(i)
		game.play_sound("snap", 0.4)
		game.notify(game.t("Груз отцеплен", "Load released"))
		return true
	# Трактор цепляет то, что позади сцепки; вертолёт — то, что под брюхом.
	var tow = id == "tow"
	var anchor = chassis.global_transform * (Vector2(-60, -6) if tow else Vector2(0, 28))
	var reach = 230.0 if tow else 360.0
	var best: LabBody = null
	var best_d = reach
	for body in _others(game, chassis):
		var local = chassis.to_local(body.global_position)
		if tow and local.x > -40.0: continue
		if not tow and (body.global_position.y < anchor.y or absf(body.global_position.x - anchor.x) > 170.0): continue
		var target: LabBody = body
		if is_instance_valid(body.ragdoll) and body.ragdoll.parts.size() > 1: target = body.ragdoll.parts[1]
		if root(body) != null: target = root(body)
		var d = target.global_position.distance_to(anchor)
		if d < best_d:
			best_d = d
			best = target
	if best == null:
		game.notify(game.t("Сзади нечего цеплять", "Nothing to hitch behind") if tow else game.t("Под вертолётом нечего поднять", "Nothing below to lift"))
		return false
	var before = game.links.size()
	game.make_link(chassis, best, true)
	if game.links.size() == before:
		game.notify(game.t("Слишком много связей", "Too many links"))
		return false
	game.notify(game.t("Прицеплено: ", "Hitched: ") + game.hud.item_label(best.kind))
	return true

static func wreck(game: Node2D, chassis: LabBody) -> void:
	if chassis.wrecked: return
	chassis.wrecked = true
	chassis.gear = 0
	chassis.active = false
	chassis.health = 0.0
	if is_instance_valid(game):
		game.explode(chassis.global_position, 150.0 if chassis.kind != "car_tank" else 210.0, 0.7)
		chassis.burning = 0.0
		chassis.ignite(3.0, 9.0)
		game.play_sound("metal", 0.6)
		game.notify(game.t("Машина разбита", "The vehicle is wrecked"))

# --------------------------------------------------------------------------
# Рисование
# --------------------------------------------------------------------------
static func draw_icon(c: CanvasItem, kind: String, center: Vector2, scale_value: float, rot: float) -> void:
	# Каталог рисует предметы в масштабе ~0.64, а машина вчетверо шире ящика:
	# уменьшаем, чтобы влезла в ячейку. Призрак размещения идёт в реальном размере.
	var s = spec(kind)
	# Габариты рисунка: кузов плюс колёса. Центр кузова у высоких машин (трактор,
	# вертолёт) далеко от центра картинки, поэтому в каталоге иконку центрируем
	# по габаритам и вписываем и по ширине, и по высоте.
	var lo = Vector2(INF, INF)
	var hi = Vector2(-INF, -INF)
	for poly in s.hull:
		for p in poly:
			lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y)); hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	for w in s.wheels:
		var r: float = w[1]
		lo = Vector2(minf(lo.x, w[0].x - r), minf(lo.y, w[0].y - r)); hi = Vector2(maxf(hi.x, w[0].x + r), maxf(hi.y, w[0].y + r))
	var size = hi - lo
	var fit = 1.0
	var shift = Vector2.ZERO
	if scale_value < 0.45:
		fit = minf(0.36, minf(60.0 / size.x, 34.0 / size.y))
		shift = -(lo + hi) * 0.5
	elif scale_value < 0.8:
		fit = minf(0.55, minf(128.0 / size.x, 78.0 / size.y))
		shift = -(lo + hi) * 0.5
	var k = scale_value * fit
	c.draw_set_transform(center + (shift * k).rotated(rot), rot, Vector2.ONE * k)
	var rest: Array = []
	for w in s.wheels: rest.append(w[0])
	draw_body(c, kind, 1.0, false, 0, rest, 0.0)
	for w in s.wheels: draw_wheel(c, w[0], w[1], str(w[3]) if w.size() > 3 else str(s.style), 0.0)
	c.draw_set_transform(Vector2.ZERO)

static func draw_body(c: CanvasItem, kind: String, condition: float, active: bool, gear: int, wheel_pos: Array, track_phase: float) -> void:
	var s = spec(kind)
	var base: Color = s.color
	var paint = base.lerp(Color("2a2f33"), clampf((1.0 - condition) * 0.8, 0.0, 0.8))
	var dark = paint.darkened(0.35)
	var glass = Color("35596f")
	var metal = Color("8aa0ad")
	var steel = Color("3a4a55")
	# Стойки подвески — рисуются первыми, их верх уходит под кузов, а низ — в ступицу.
	for i in range(mini(wheel_pos.size(), s.wheels.size())):
		var mount: Vector2 = s.wheels[i][0]
		var top = mount - Vector2(0, float(s.travel_up) + 14.0)
		var at: Vector2 = wheel_pos[i]
		LabSurface.line(c,top, at, steel, 5.0 if kind != "car_tank" else 3.0, true)
		if kind == "car_monster":
			# Длинный ход подвески видно: пружина винтом вокруг амортизатора.
			var coils = 7
			var prev = top
			for k in range(1, coils * 2 + 1):
				var t = float(k) / float(coils * 2)
				var p = top.lerp(at, t) + Vector2(5.0 if k % 2 == 0 else -5.0, 0)
				LabSurface.line(c,prev, p, AMBER_SPRING, 2.0, true)
				prev = p
	match kind:
		"car_sedan":
			# Колёсные арки — тёмные ниши, в которых крутятся колёса.
			for w in s.wheels: LabSurface.circle(c,w[0], w[1] + 5.0, Color("141a20"))
			var lower = PackedVector2Array([Vector2(-80,-4),Vector2(-40,-8),Vector2(40,-8),Vector2(78,-6),Vector2(82,8),Vector2(74,18),Vector2(-74,18),Vector2(-82,8)])
			LabSurface.polygon(c,lower, paint)
			var roof = PackedVector2Array([Vector2(-46,-6),Vector2(-30,-31),Vector2(22,-31),Vector2(46,-6)])
			LabSurface.polygon(c,roof, paint)
			LabSurface.polygon(c,PackedVector2Array([Vector2(-40,-8),Vector2(-27,-27),Vector2(-8,-27),Vector2(-8,-8)]), glass)
			LabSurface.polygon(c,PackedVector2Array([Vector2(-3,-8),Vector2(-3,-27),Vector2(19,-27),Vector2(38,-8)]), glass)
			LabSurface.line(c,Vector2(-24,-24), Vector2(-14,-14), Color(1,1,1,0.35), 2.0, true)
			# Двери, ручки, пороги.
			LabSurface.line(c,Vector2(-6,-8), Vector2(-6,14), dark, 1.5)
			LabSurface.line(c,Vector2(40,-6), Vector2(40,12), dark, 1.5)
			LabSurface.line(c,Vector2(-44,-6), Vector2(-44,12), dark, 1.5)
			LabSurface.line(c,Vector2(-30,0), Vector2(-22,0), Color("d8e2e6"), 2.0)
			LabSurface.line(c,Vector2(10,0), Vector2(18,0), Color("d8e2e6"), 2.0)
			LabSurface.line(c,Vector2(-80,8), Vector2(80,8), paint.lightened(0.25), 1.2)
			c.draw_polyline(PackedVector2Array([Vector2(-78,-4),Vector2(-40,-8),Vector2(40,-8),Vector2(78,-6)]), paint.lightened(0.3), 1.5, true)
			_bumpers(c, Vector2(-84, 12), Vector2(84, 12))
			_lights(c, Vector2(80, 0), Vector2(-81, 0), active, gear)
		"car_pickup":
			for w in s.wheels: LabSurface.circle(c,w[0], w[1] + 5.0, Color("141a20"))
			LabSurface.polygon(c,PackedVector2Array([Vector2(-98,0),Vector2(96,0),Vector2(96,16),Vector2(-98,16)]), paint)
			# Кузов-платформа: борт, дно, задний откидной борт.
			LabSurface.rect(c,Rect2(-98,-24,8,26), paint)
			LabSurface.rect(c,Rect2(-90,-18,104,2), dark)
			LabSurface.rect(c,Rect2(-90,-2,104,4), Color("24303a"))
			for x in [-70, -46, -22]: LabSurface.line(c,Vector2(x,-1), Vector2(x,1), Color(1,1,1,0.12), 2.0)
			LabSurface.line(c,Vector2(-94,-20), Vector2(-94,-2), dark, 1.5)
			LabSurface.polygon(c,PackedVector2Array([Vector2(14,-44),Vector2(50,-44),Vector2(66,-14),Vector2(66,4),Vector2(14,4)]), paint)
			LabSurface.polygon(c,PackedVector2Array([Vector2(60,-16),Vector2(96,-10),Vector2(96,4),Vector2(60,4)]), paint)
			LabSurface.polygon(c,PackedVector2Array([Vector2(36,-40),Vector2(48,-40),Vector2(61,-16),Vector2(36,-16)]), glass)
			LabSurface.rect(c,Rect2(18,-40,14,24), glass)
			LabSurface.line(c,Vector2(34,-16), Vector2(34,10), dark, 1.5)
			LabSurface.line(c,Vector2(40,-8), Vector2(48,-8), Color("d8e2e6"), 2.0)
			# Решётка и выхлоп.
			for y in [-6, -2, 2]: LabSurface.line(c,Vector2(88,y), Vector2(95,y), steel, 1.5)
			LabSurface.rect(c,Rect2(-86,14,14,4), steel)
			LabSurface.line(c,Vector2(-98,8), Vector2(96,8), paint.lightened(0.25), 1.2)
			_bumpers(c, Vector2(-100, 12), Vector2(98, 10))
			_lights(c, Vector2(94, -4), Vector2(-97, -10), active, gear)
		"car_monster":
			# Рама над колёсами, толстые трубы каркаса.
			LabSurface.line(c,Vector2(-60,26), Vector2(60,26), steel, 6.0, true)
			LabSurface.line(c,Vector2(-60,-4), Vector2(-60,26), steel, 4.0)
			LabSurface.line(c,Vector2(60,-4), Vector2(60,26), steel, 4.0)
			LabSurface.polygon(c,PackedVector2Array([Vector2(-72,-22),Vector2(72,-24),Vector2(78,-6),Vector2(-74,-6)]), paint)
			LabSurface.polygon(c,PackedVector2Array([Vector2(-36,-24),Vector2(-22,-48),Vector2(24,-48),Vector2(40,-24)]), paint)
			LabSurface.polygon(c,PackedVector2Array([Vector2(-30,-26),Vector2(-19,-44),Vector2(-2,-44),Vector2(-2,-26)]), glass)
			LabSurface.polygon(c,PackedVector2Array([Vector2(3,-26),Vector2(3,-44),Vector2(21,-44),Vector2(33,-26)]), glass)
			# Языки пламени на борту — фирменная раскраска.
			for i in range(4):
				var x0 = -64.0 + float(i) * 18.0
				LabSurface.polygon(c,PackedVector2Array([Vector2(x0,-9),Vector2(x0+14,-17),Vector2(x0+12,-13),Vector2(x0+30,-19),Vector2(x0+20,-11),Vector2(x0+26,-8)]), Color("e0533f"))
			LabSurface.rect(c,Rect2(-20,-52,36,4), Color("2a3035"))
			for x in [-14, -2, 10]: LabSurface.circle(c,Vector2(x,-54), 2.5, AMBER_SPRING if active else Color("6d7f8c"))
			LabSurface.line(c,Vector2(-74,-6), Vector2(78,-6), dark, 2.0)
			_lights(c, Vector2(76, -16), Vector2(-73, -14), active, gear)
		"car_tank":
			var pts: Array = wheel_pos
			if pts.is_empty():
				for w in s.wheels: pts.append(w[0])
			_track(c, pts, 12.0, track_phase)
			LabSurface.polygon(c,PackedVector2Array([Vector2(-92,-6),Vector2(92,-6),Vector2(100,6),Vector2(84,14),Vector2(-84,14),Vector2(-98,6)]), paint)
			LabSurface.line(c,Vector2(-96,6), Vector2(98,6), dark, 2.0)
			for x in [-70, -40, 40, 70]: LabArt.bolt(c, Vector2(x, 0), 1.6, Color("aab8a0"))
			# Ящики на надгусеничной полке.
			LabSurface.rect(c,Rect2(-86,-14,26,9), dark)
			LabSurface.rect(c,Rect2(56,-13,22,8), dark)
			# Башня, ствол, дульный тормоз, люк.
			LabSurface.rect(c,Rect2(30,-24,78,8), Color("4a5a40"))
			LabSurface.line(c,Vector2(32,-22), Vector2(104,-22), Color(1,1,1,0.12), 1.5)
			LabSurface.rect(c,Rect2(102,-26,8,12), steel)
			LabSurface.polygon(c,PackedVector2Array([Vector2(-40,-6),Vector2(-30,-30),Vector2(26,-30),Vector2(40,-6)]), paint.lightened(0.05))
			LabSurface.rect(c,Rect2(-14,-35,20,5), dark)
			LabSurface.line(c,Vector2(-30,-30), Vector2(26,-30), paint.lightened(0.3), 1.5)
			LabSurface.circle(c,Vector2(18,-18), 3.0, Color("1a2226"))
			LabSurface.line(c,Vector2(-22,-30), Vector2(-26,-48), Color("2a3035"), 1.5)
			if active: LabSurface.circle(c,Vector2(-26,-48), 2.0, Color(1.0, 0.3, 0.25))
	_draw_more(c, kind, paint, dark, glass, steel, active, gear, wheel_pos, track_phase)
	# Fine seams on upward-facing hull edges read as stamped body panels.
	for poly in s.hull:
		for i in range(poly.size()):
			var a: Vector2=poly[i]
			var b: Vector2=poly[(i+1)%poly.size()]
			if b.x-a.x>18.0 and absf(b.y-a.y)<12.0:
				c.draw_line(a+Vector2(2,1.5),b+Vector2(-2,1.5),Color(0.91,0.97,1.0,0.26),0.9,true)
	if condition < 0.9:
		var r = Rect2(-float(s.dims.x) * 0.4, -18, float(s.dims.x) * 0.8, 26)
		LabArt.damage(c, r, 1.0 - condition, hash(kind) % 97)

const AMBER_SPRING = Color("ffbc70")
const CHROME = Color("d8e2e6")
const TIRE_WELL = Color("141a20")

static func _pv(points: Array) -> PackedVector2Array:
	return PackedVector2Array(points)

static func _arches(c: CanvasItem, s: Dictionary, extra: float = 5.0) -> void:
	for w in s.wheels: LabSurface.circle(c,w[0], float(w[1]) + extra, TIRE_WELL)

static func _siren(c: CanvasItem, at: Vector2, active: bool, width: float = 22.0) -> void:
	# Мигалка: половины меняются местами четыре раза в секунду.
	var on = active and int(Time.get_ticks_msec() / 250) % 2 == 0
	var left = Color(1.0, 0.25, 0.25) if (on or not active) else Color(0.45, 0.12, 0.12)
	var right = Color(0.3, 0.55, 1.0) if (not on or not active) else Color(0.12, 0.2, 0.45)
	if not active:
		left = Color(0.55, 0.2, 0.2); right = Color(0.2, 0.3, 0.55)
	LabSurface.rect(c,Rect2(at.x - width * 0.5, at.y - 5, width * 0.5, 6), left)
	LabSurface.rect(c,Rect2(at.x, at.y - 5, width * 0.5, 6), right)
	if active:
		LabArt.soft_glow(c, at + Vector2(-width * 0.25 if on else width * 0.25, -2), 18.0, Color(1.0, 0.3, 0.3) if on else Color(0.3, 0.55, 1.0), 0.9)

static func _draw_more(c: CanvasItem, kind: String, paint: Color, dark: Color, glass: Color, steel: Color, active: bool, gear: int, wheel_pos: Array, phase: float) -> void:
	var s = spec(kind)
	match kind:
		"car_sport":
			_arches(c, s, 4.0)
			LabSurface.polygon(c,_pv([Vector2(-84,-2),Vector2(-20,-10),Vector2(40,-10),Vector2(86,0),Vector2(84,10),Vector2(-84,10)]), paint)
			LabSurface.polygon(c,_pv([Vector2(-40,-10),Vector2(-18,-26),Vector2(16,-26),Vector2(44,-10)]), paint)
			LabSurface.polygon(c,_pv([Vector2(-34,-11),Vector2(-16,-23),Vector2(14,-23),Vector2(38,-11)]), Color(0.1, 0.16, 0.2, 0.85))
			LabSurface.line(c,Vector2(-12,-21), Vector2(-2,-13), Color(1,1,1,0.3), 2.0, true)
			# Спойлер, воздухозаборник, гоночная полоса.
			LabSurface.rect(c,Rect2(-90,-22,22,4), Color("20252b"))
			LabSurface.line(c,Vector2(-80,-18), Vector2(-76,-6), Color("20252b"), 3.0)
			LabSurface.polygon(c,_pv([Vector2(-6,0),Vector2(20,-2),Vector2(16,4),Vector2(-4,5)]), Color("20252b"))
			LabSurface.line(c,Vector2(-84,4), Vector2(84,2), Color("20252b"), 3.0)
			c.draw_polyline(_pv([Vector2(-84,-2),Vector2(-20,-10),Vector2(40,-10),Vector2(86,0)]), paint.lightened(0.35), 1.5, true)
			_lights(c, Vector2(82, -1), Vector2(-83, 0), active, gear)
		"car_bus":
			_arches(c, s)
			LabSurface.polygon(c,_pv(s.hull[0]), paint)
			LabSurface.rect(c,Rect2(-146,-26,292,6), Color("f1f5f2"))
			LabSurface.rect(c,Rect2(-146,4,292,12), dark)
			for i in range(7):
				LabSurface.rect(c,Rect2(-136 + i * 34, -62, 26, 28), glass)
				LabSurface.line(c,Vector2(-133 + i * 34, -58), Vector2(-127 + i * 34, -50), Color(1,1,1,0.3), 1.5)
			# Лобовое стекло и передняя дверь.
			LabSurface.polygon(c,_pv([Vector2(112,-64),Vector2(138,-64),Vector2(143,-56),Vector2(143,-30),Vector2(112,-30)]), glass)
			LabSurface.rect(c,Rect2(114,-24,24,38), dark)
			LabSurface.rect(c,Rect2(117,-21,8,30), glass)
			LabSurface.rect(c,Rect2(127,-21,8,30), glass)
			LabSurface.rect(c,Rect2(100,-69,34,7), Color("2a3035"))
			LabSurface.rect(c,Rect2(103,-67,20,3), AMBER_SPRING)
			LabSurface.line(c,Vector2(-146,-70), Vector2(140,-70), paint.lightened(0.3), 2.0)
			_bumpers(c, Vector2(-148, 10), Vector2(148, 10))
			_lights(c, Vector2(144, 0), Vector2(-145, -6), active, gear)
		"car_mixer":
			_arches(c, s)
			LabSurface.rect(c,Rect2(-122,0,240,16), Color("2a3035"))
			LabSurface.polygon(c,_pv(s.hull[1]), paint)
			LabSurface.polygon(c,_pv([Vector2(80,-54),Vector2(94,-54),Vector2(112,-32),Vector2(80,-32)]), glass)
			LabSurface.line(c,Vector2(76,-28), Vector2(76,0), dark, 1.5)
			# Барабан: крутится вместе с ходом машины, спираль бежит по нему.
			# Барабан — бочка на наклонной оси: эллипс, повёрнутый на 14°, с
			# винтовой лопастью, которая бежит по нему, пока машина едет.
			var axis_c = Vector2(-34, -40)
			var tilt = deg_to_rad(-14.0)
			var drum = _pv([])
			for i in range(28):
				var a = TAU * float(i) / 28.0
				drum.append(axis_c + Vector2(cos(a) * 76.0, sin(a) * 34.0).rotated(tilt))
			LabSurface.polygon(c,drum, Color("b8c1c7"))
			for i in range(28):
				var a = TAU * float(i) / 28.0
				if sin(a) > 0.2: LabSurface.line(c,axis_c + Vector2(cos(a) * 76.0, sin(a) * 34.0).rotated(tilt), axis_c + Vector2(cos(a) * 70.0, sin(a) * 28.0).rotated(tilt), Color("8d989e"), 3.0)
			var off = fposmod(phase * 0.04, 1.0)
			for k in range(5):
				var u = fposmod(float(k) / 5.0 + off, 1.0)
				var x = lerpf(-64.0, 64.0, u)
				var half = 34.0 * sqrt(maxf(0.0, 1.0 - pow(x / 76.0, 2)))
				LabSurface.line(c,axis_c + Vector2(x - 8.0, -half * 0.92).rotated(tilt), axis_c + Vector2(x + 8.0, half * 0.92).rotated(tilt), Color("e07b39"), 3.5, true)
			c.draw_polyline(drum + _pv([drum[0]]), Color("7d8a91"), 2.0, true)
			LabSurface.circle(c,axis_c + Vector2(-74, 0).rotated(tilt), 6.0, Color("7d8a91"))
			LabSurface.line(c,Vector2(-112,-8), Vector2(-124,-30), steel, 3.0)
			LabSurface.line(c,Vector2(40,-50), Vector2(58,-58), steel, 4.0)
			_lights(c, Vector2(116, -8), Vector2(-121, 6), active, gear)
		"car_jeep":
			LabSurface.polygon(c,_pv(s.hull[0]), paint)
			LabSurface.polygon(c,_pv(s.hull[1]), paint)
			LabSurface.polygon(c,_pv([Vector2(-46,-16),Vector2(-40,-40),Vector2(-10,-40),Vector2(-10,-16)]), glass)
			LabSurface.polygon(c,_pv([Vector2(-5,-16),Vector2(-5,-40),Vector2(20,-40),Vector2(34,-16)]), glass)
			# Расширители арок, запаска, багажник на крыше, шноркель.
			for w in s.wheels: c.draw_arc(w[0], float(w[1]) + 6.0, PI, TAU, 16, Color("2a3035"), 6.0, true)
			LabSurface.circle(c,Vector2(-88,-12), 13.0, Color("1c2328"))
			LabSurface.circle(c,Vector2(-88,-12), 6.0, Color("8aa0ad"))
			LabSurface.rect(c,Rect2(-46,-50,64,4), Color("2a3035"))
			for x in [-40, -24, -8, 8]: LabSurface.line(c,Vector2(x,-50), Vector2(x,-44), Color("2a3035"), 2.0)
			c.draw_polyline(_pv([Vector2(34,-10),Vector2(36,-46),Vector2(30,-50)]), Color("2a3035"), 3.0, true)
			LabSurface.line(c,Vector2(-8,-12), Vector2(-8,4), dark, 1.5)
			_bumpers(c, Vector2(-84, 2), Vector2(86, 2))
			_lights(c, Vector2(82, -8), Vector2(-81, -8), active, gear)
		"car_ambulance":
			_arches(c, s)
			LabSurface.polygon(c,_pv(s.hull[0]), paint)
			LabSurface.polygon(c,_pv(s.hull[1]), paint)
			LabSurface.rect(c,Rect2(-104,-24,208,7), Color("d62828"))
			# Красный крест на борту.
			LabSurface.rect(c,Rect2(-50,-52,12,30), Color("d62828"))
			LabSurface.rect(c,Rect2(-59,-43,30,12), Color("d62828"))
			LabSurface.polygon(c,_pv([Vector2(50,-42),Vector2(68,-42),Vector2(94,-16),Vector2(50,-16)]), glass)
			LabSurface.line(c,Vector2(46,-12), Vector2(46,12), dark, 1.5)
			LabSurface.line(c,Vector2(-102,-60), Vector2(-102,12), dark, 1.5)
			LabSurface.rect(c,Rect2(-98,-56,20,16), glass)
			_siren(c, Vector2(-20,-62), active, 26.0)
			_siren(c, Vector2(60,-46), active, 16.0)
			_bumpers(c, Vector2(-106, 10), Vector2(106, 10))
			_lights(c, Vector2(102, -2), Vector2(-103, -4), active, gear)
		"car_fire":
			_arches(c, s)
			LabSurface.polygon(c,_pv(s.hull[0]), paint)
			LabSurface.polygon(c,_pv(s.hull[1]), paint)
			LabSurface.rect(c,Rect2(-128,-6,256,5), Color("f1f5f2"))
			for i in range(4):
				LabSurface.rect(c,Rect2(-122 + i * 46, -36, 40, 26), dark)
				LabSurface.line(c,Vector2(-118 + i * 46, -24), Vector2(-90 + i * 46, -24), CHROME, 1.5)
			LabSurface.polygon(c,_pv([Vector2(80,-56),Vector2(96,-56),Vector2(118,-30),Vector2(80,-30)]), glass)
			LabSurface.line(c,Vector2(76,-26), Vector2(76,12), dark, 1.5)
			# Лестница на крыше и лафетный ствол.
			LabSurface.line(c,Vector2(-120,-46), Vector2(62,-54), CHROME, 3.0, true)
			LabSurface.line(c,Vector2(-120,-40), Vector2(62,-48), CHROME, 3.0, true)
			for i in range(13):
				var x = -114.0 + float(i) * 14.0
				LabSurface.line(c,Vector2(x, -46.0 - (x + 120.0) * 0.044), Vector2(x, -40.0 - (x + 120.0) * 0.044), CHROME, 2.0)
			LabSurface.circle(c,Vector2(-60,-20), 10.0, Color("2a3035"))
			c.draw_arc(Vector2(-60,-20), 7.0, 0, TAU, 16, AMBER_SPRING, 2.0, true)
			LabSurface.line(c,Vector2(56,-54), Vector2(66,-62), Color("2a3035"), 4.0)
			_siren(c, Vector2(90,-60), active, 22.0)
			_bumpers(c, Vector2(-130, 10), Vector2(130, 10))
			_lights(c, Vector2(126, -2), Vector2(-127, -30), active, gear)
		"car_police":
			_arches(c, s)
			LabSurface.polygon(c,_pv([Vector2(-80,-4),Vector2(-40,-8),Vector2(40,-8),Vector2(78,-6),Vector2(82,8),Vector2(74,18),Vector2(-74,18),Vector2(-82,8)]), paint)
			LabSurface.polygon(c,_pv([Vector2(-46,-6),Vector2(-30,-31),Vector2(22,-31),Vector2(46,-6)]), paint)
			# Белые двери с полосой и звездой.
			LabSurface.polygon(c,_pv([Vector2(-44,-8),Vector2(40,-8),Vector2(40,14),Vector2(-44,14)]), Color("f1f5f2"))
			LabSurface.rect(c,Rect2(-80,2,160,4), Color("d62828"))
			var star = _pv([])
			for i in range(10):
				star.append(Vector2(-2, -1) + Vector2.from_angle(-PI / 2 + float(i) * TAU / 10.0) * (5.0 if i % 2 == 0 else 2.2))
			LabSurface.polygon(c,star, AMBER_SPRING)
			LabSurface.polygon(c,_pv([Vector2(-40,-8),Vector2(-27,-27),Vector2(-8,-27),Vector2(-8,-8)]), glass)
			LabSurface.polygon(c,_pv([Vector2(-3,-8),Vector2(-3,-27),Vector2(19,-27),Vector2(38,-8)]), glass)
			LabSurface.line(c,Vector2(-6,-8), Vector2(-6,14), dark, 1.5)
			_siren(c, Vector2(-4,-31), active, 30.0)
			_bumpers(c, Vector2(-84, 12), Vector2(84, 12))
			_lights(c, Vector2(80, 0), Vector2(-81, 0), active, gear)
		"car_dozer":
			var pts: Array = wheel_pos
			if pts.is_empty():
				for w in s.wheels: pts.append(w[0])
			_track(c, pts, 11.0, phase)
			LabSurface.rect(c,Rect2(-96,-14,156,26), paint)
			for x in range(-6, 54, 8): LabSurface.line(c,Vector2(x,-10), Vector2(x,4), dark, 2.0)
			LabSurface.line(c,Vector2(-40,-14), Vector2(-40,-34), Color("2a3035"), 4.0)
			LabSurface.rect(c,Rect2(-44,-38,8,4), Color("2a3035"))
			# Кабина-каркас и стёкла.
			LabSurface.polygon(c,_pv(s.hull[1]), paint.darkened(0.1))
			LabSurface.polygon(c,_pv([Vector2(-64,-54),Vector2(-16,-54),Vector2(-9,-20),Vector2(-72,-20)]), glass)
			LabSurface.line(c,Vector2(-40,-54), Vector2(-40,-20), paint.darkened(0.1), 3.0)
			# Отвал на гидроцилиндрах.
			LabSurface.polygon(c,_pv(s.hull[3]), steel)
			LabSurface.line(c,Vector2(40,-14), Vector2(94,-30), Color("8aa0ad"), 4.0, true)
			LabSurface.polygon(c,_pv(s.hull[2]), Color("4a5660"))
			c.draw_polyline(_pv([Vector2(92,-44),Vector2(112,-40),Vector2(116,24)]), Color("aab8c0"), 2.0, true)
			LabSurface.line(c,Vector2(96,26), Vector2(116,24), Color("d8e2e6"), 3.0)
			_lights(c, Vector2(-14, -50), Vector2(-95, -4), active, gear)
		"car_tractor":
			LabSurface.polygon(c,_pv(s.hull[0]), paint)
			for y in [-24, -16, -8]: LabSurface.line(c,Vector2(70,y), Vector2(78,y), Color("2a3035"), 2.0)
			LabSurface.rect(c,Rect2(-70,-100,62,6), paint)
			for x in [-68, -14]: LabSurface.line(c,Vector2(x,-96), Vector2(x + (0 if x < 0 else 4), -38), Color("2a3035"), 4.0)
			LabSurface.polygon(c,_pv([Vector2(-62,-92),Vector2(-18,-92),Vector2(-15,-40),Vector2(-66,-40)]), Color(0.62, 0.9, 1.0, 0.35))
			c.draw_arc(Vector2(-44,6), 44.0, PI, TAU, 24, AMBER_SPRING, 7.0, true)
			LabSurface.line(c,Vector2(40,-30), Vector2(40,-62), Color("2a3035"), 4.0)
			LabSurface.rect(c,Rect2(36,-66,8,4), Color("2a3035"))
			if active and Engine.get_physics_frames() % 2 == 0:
				LabArt.soft_glow(c, Vector2(40,-70), 8.0, Color(0.5, 0.5, 0.5, 0.6), 0.5)
			_lights(c, Vector2(78, -14), Vector2(-39, -20), active, gear)
		"car_moto":
			var rear: Vector2 = wheel_pos[0] if wheel_pos.size() > 0 else s.wheels[0][0]
			var front: Vector2 = wheel_pos[1] if wheel_pos.size() > 1 else s.wheels[1][0]
			# Маятник к заднему колесу, вилка к переднему — стойки ходят вместе с колёсами.
			LabSurface.line(c,Vector2(-14,-4), rear, Color("2a3035"), 4.0, true)
			LabSurface.line(c,Vector2(30,-28), front, CHROME, 4.0, true)
			LabSurface.polygon(c,_pv([Vector2(-18,-12),Vector2(14,-14),Vector2(18,4),Vector2(-14,6)]), Color("4a5660"))
			for y in [-8, -3, 2]: LabSurface.line(c,Vector2(-14,y), Vector2(14,y), Color("2a3035"), 1.5)
			LabSurface.line(c,Vector2(-10,4), Vector2(-52,-2), CHROME, 3.0, true)
			LabSurface.polygon(c,_pv([Vector2(-6,-28),Vector2(24,-32),Vector2(30,-22),Vector2(-2,-16)]), paint)
			LabSurface.polygon(c,_pv([Vector2(-40,-24),Vector2(-6,-26),Vector2(-4,-18),Vector2(-42,-18)]), Color("1c2328"))
			LabSurface.polygon(c,_pv([Vector2(-52,-20),Vector2(-38,-22),Vector2(-38,-14),Vector2(-50,-14)]), paint)
			LabSurface.line(c,Vector2(28,-30), Vector2(22,-40), Color("2a3035"), 3.0)
			LabSurface.line(c,Vector2(18,-40), Vector2(30,-42), Color("2a3035"), 3.0)
			_lights(c, Vector2(36, -24), Vector2(-52, -18), active, gear)
		"car_atv":
			LabSurface.polygon(c,_pv(s.hull[0]), paint)
			for w in s.wheels: c.draw_arc(w[0], float(w[1]) + 5.0, PI + 0.3, TAU - 0.3, 14, paint.darkened(0.2), 7.0, true)
			LabSurface.polygon(c,_pv(s.hull[1]), Color("1c2328"))
			LabSurface.rect(c,Rect2(-58,-30,24,3), Color("2a3035"))
			LabSurface.rect(c,Rect2(34,-32,22,3), Color("2a3035"))
			LabSurface.line(c,Vector2(14,-24), Vector2(20,-40), Color("2a3035"), 3.0)
			LabSurface.line(c,Vector2(12,-40), Vector2(28,-40), Color("2a3035"), 3.0)
			LabSurface.rect(c,Rect2(-18,-18,30,12), Color("4a5660"))
			_lights(c, Vector2(56, -14), Vector2(-57, -12), active, gear)
		"car_kart":
			LabSurface.line(c,Vector2(-40,4), Vector2(42,4), Color("2a3035"), 4.0)
			LabSurface.polygon(c,_pv(s.hull[0]), paint)
			LabSurface.polygon(c,_pv([Vector2(-28,-24),Vector2(-8,-24),Vector2(-4,-6),Vector2(-32,-6)]), Color("1c2328"))
			LabSurface.rect(c,Rect2(-46,-14,14,10), Color("4a5660"))
			LabSurface.line(c,Vector2(-46,-10), Vector2(-54,-16), CHROME, 2.0)
			LabSurface.line(c,Vector2(2,-6), Vector2(12,-20), Color("2a3035"), 2.5)
			c.draw_arc(Vector2(12,-20), 6.0, 0, TAU, 14, Color("2a3035"), 2.5, true)
			LabSurface.line(c,Vector2(42,-2), Vector2(50,6), Color("2a3035"), 3.0)
			LabSurface.line(c,Vector2(-44,-2), Vector2(-52,6), Color("2a3035"), 3.0)
			LabSurface.circle(c,Vector2(20,-2), 3.0, Color("f1f5f2"))
		"car_limo":
			_arches(c, s)
			LabSurface.polygon(c,_pv([Vector2(-138,-4),Vector2(-70,-8),Vector2(70,-8),Vector2(136,-6),Vector2(140,8),Vector2(132,18),Vector2(-132,18),Vector2(-140,8)]), paint)
			LabSurface.polygon(c,_pv(s.hull[1]), paint)
			for i in range(5):
				var x0 = -76.0 + float(i) * 30.0
				LabSurface.rect(c,Rect2(x0, -26, 24, 18), Color(0.34, 0.44, 0.52, 0.95))
				LabSurface.rect(c,Rect2(x0, -26, 24, 18), CHROME, false, 1.0)
			LabSurface.polygon(c,_pv([Vector2(76,-8),Vector2(58,-26),Vector2(70,-26),Vector2(80,-8)]), Color(0.34, 0.44, 0.52, 0.95))
			c.draw_polyline(_pv([Vector2(-84,-6),Vector2(-66,-30),Vector2(56,-30),Vector2(80,-6)]), CHROME, 1.5, true)
			LabSurface.line(c,Vector2(-140,2), Vector2(140,0), CHROME, 2.0)
			for x in [-60, 0, 60]: LabSurface.line(c,Vector2(x,-6), Vector2(x,14), Color(1,1,1,0.12), 1.5)
			LabSurface.circle(c,Vector2(84,-30), 2.5, CHROME)
			_bumpers(c, Vector2(-142, 12), Vector2(142, 12))
			_lights(c, Vector2(138, 0), Vector2(-139, 0), active, gear)
		"car_apc":
			_arches(c, s, 3.0)
			LabSurface.polygon(c,_pv(s.hull[0]), paint)
			LabSurface.line(c,Vector2(-100,-6), Vector2(100,-4), dark, 2.0)
			for x in [-80, -40, 0, 40]: LabArt.bolt(c, Vector2(x, -18), 1.6, Color("d9c9a0"))
			for x in [60, 76]: LabSurface.rect(c,Rect2(x, -24, 10, 3), Color("1c2328"))
			LabSurface.rect(c,Rect2(-92,-38,30,8), dark)
			LabSurface.polygon(c,_pv(s.hull[1]), paint.lightened(0.05))
			LabSurface.rect(c,Rect2(28,-42,56,4), Color("2a3035"))
			LabSurface.rect(c,Rect2(82,-44,6,8), Color("2a3035"))
			LabSurface.rect(c,Rect2(-10,-50,16,4), dark)
			LabSurface.line(c,Vector2(-18,-46), Vector2(-22,-66), Color("2a3035"), 1.5)
			_lights(c, Vector2(100, -4), Vector2(-99, -20), active, gear)
		"car_heli":
			# Хвостовая балка, хвостовой винт, кабина-капля, лыжи.
			LabSurface.polygon(c,_pv(s.hull[1]), paint.darkened(0.08))
			LabSurface.polygon(c,_pv([Vector2(-112,-44),Vector2(-100,-44),Vector2(-96,-24),Vector2(-110,-24)]), paint)
			var tail_a = phase * 1.7
			for k in range(2):
				var a = tail_a + float(k) * PI / 2.0
				LabSurface.line(c,Vector2(-104,-36) - Vector2.from_angle(a) * 14.0, Vector2(-104,-36) + Vector2.from_angle(a) * 14.0, Color("2a3035"), 2.5, true)
			LabSurface.polygon(c,_pv(s.hull[0]), paint)
			LabSurface.polygon(c,_pv([Vector2(10,-36),Vector2(30,-38),Vector2(54,-14),Vector2(46,4),Vector2(10,4)]), glass)
			LabSurface.line(c,Vector2(22,-30), Vector2(38,-14), Color(1,1,1,0.3), 2.0, true)
			LabSurface.rect(c,Rect2(-26,-26,22,20), glass)
			LabSurface.line(c,Vector2(-36,-4), Vector2(44,-4), dark, 2.0)
			for x in [-30.0, 36.0]:
				LabSurface.line(c,Vector2(x, 8), Vector2(x - 4.0, 24), Color("2a3035"), 3.0)
			LabSurface.line(c,Vector2(-44,26), Vector2(50,26), Color("2a3035"), 4.0, true)
			LabSurface.line(c,Vector2(50,26), Vector2(58,20), Color("2a3035"), 4.0, true)
			# Несущий винт: сбоку лопасти видны как линия, длина которой пульсирует.
			LabSurface.line(c,Vector2(0,-40), Vector2(0,-50), Color("2a3035"), 4.0)
			LabSurface.rect(c,Rect2(-8,-54,16,5), Color("2a3035"))
			var reach = 112.0 * absf(cos(phase))
			var reach2 = 112.0 * absf(sin(phase))
			if active:
				LabSurface.line(c,Vector2(-112,-52), Vector2(112,-52), Color(0.2, 0.25, 0.3, 0.25), 5.0, true)
			LabSurface.line(c,Vector2(-reach,-52), Vector2(reach,-52), Color("2a3035"), 3.0, true)
			LabSurface.line(c,Vector2(-reach2,-51), Vector2(reach2,-51), Color("3a4a55"), 2.0, true)
			LabSurface.circle(c,Vector2(56,-8), 3.0, Color("fff2c2") if active else Color("b9b29a"))
			if active: LabSurface.circle(c,Vector2(-110,-24), 2.5, Color(1.0, 0.3, 0.25) if int(Time.get_ticks_msec() / 400) % 2 == 0 else Color(0.4, 0.1, 0.1))

static func _bumpers(c: CanvasItem, back: Vector2, front: Vector2) -> void:
	LabSurface.line(c,back - Vector2(0, 3), back + Vector2(0, 5), Color("2a3035"), 6.0, true)
	LabSurface.line(c,front - Vector2(0, 3), front + Vector2(0, 5), Color("2a3035"), 6.0, true)

static func _lights(c: CanvasItem, head: Vector2, tail: Vector2, active: bool, gear: int) -> void:
	LabSurface.circle(c,head, 4.0, Color("fff2c2") if active else Color("b9b29a"))
	if active:
		LabArt.soft_glow(c, head + Vector2(10, 0), 16.0, Color(1.0, 0.95, 0.7, 1.0), 0.8)
		LabSurface.polygon(c,PackedVector2Array([head, head + Vector2(70, -14), head + Vector2(70, 18)]), Color(1.0, 0.95, 0.7, 0.07))
	var tail_c = Color(1.0, 0.3, 0.25) if gear != 0 else Color(0.55, 0.16, 0.14)
	LabSurface.rect(c,Rect2(tail - Vector2(2, 4), Vector2(4, 8)), tail_c)
	if gear == -1:
		LabSurface.rect(c,Rect2(tail + Vector2(-2, 5), Vector2(4, 4)), Color(0.95, 0.97, 1.0))

static func _track(c: CanvasItem, pts: Array, r: float, phase: float) -> void:
	# Гусеница — лента вокруг катков: две прямые ветви и полукруги на концах.
	var min_x = INF; var max_x = -INF; var top = INF; var bottom = -INF
	for p in pts:
		min_x = minf(min_x, p.x); max_x = maxf(max_x, p.x)
		top = minf(top, p.y); bottom = maxf(bottom, p.y)
	var band = r + 5.0
	var cy = (top + bottom) * 0.5
	var half_h = (bottom - top) * 0.5 + band
	var belt = PackedVector2Array()
	for i in range(13):
		belt.append(Vector2(max_x + 8.0, cy) + Vector2.from_angle(-PI / 2 + PI * float(i) / 12.0) * half_h)
	for i in range(13):
		belt.append(Vector2(min_x - 8.0, cy) + Vector2.from_angle(PI / 2 + PI * float(i) / 12.0) * half_h)
	LabSurface.polygon(c,belt, Color("23292d"))
	belt.append(belt[0])
	c.draw_polyline(belt, Color("4b555b"), 2.0, true)
	# Траки бегут по ленте вместе с катками.
	var span = (max_x - min_x) + 16.0
	var step = 9.0
	var off = fposmod(phase, step)
	var x = min_x - 8.0 + off
	while x < max_x + 8.0:
		LabSurface.line(c,Vector2(x, cy - half_h), Vector2(x, cy - half_h + 4.0), Color("5d686e"), 2.0)
		LabSurface.line(c,Vector2(min_x - 8.0 + span - (x - min_x + 8.0), cy + half_h), Vector2(min_x - 8.0 + span - (x - min_x + 8.0), cy + half_h - 4.0), Color("5d686e"), 2.0)
		x += step

static func draw_wheel(c: CanvasItem, center: Vector2, r: float, style: String, spin: float) -> void:
	var tire = Color("1c2328")
	match style:
		"sport":
			# Низкий профиль: тонкая резина, крупный цветной диск, десять спиц.
			LabSurface.circle(c,center, r, tire)
			LabSurface.circle(c,center, r * 0.76, Color("2e373c"))
			LabSurface.circle(c,center, r * 0.7, Color("c9d3d8"))
			for i in range(10):
				var a = spin + float(i) * TAU / 10.0
				LabSurface.line(c,center + Vector2.from_angle(a) * r * 0.18, center + Vector2.from_angle(a) * r * 0.68, Color("5d6b74"), 1.5, true)
			LabSurface.circle(c,center, r * 0.18, Color("c1121f"))
		"tank":
			LabSurface.circle(c,center, r, Color("3b4247"))
			LabSurface.circle(c,center, r - 3.0, Color("6f7b70"))
			LabSurface.circle(c,center, r * 0.38, Color("48524a"))
			for i in range(5):
				LabArt.bolt(c, center + Vector2.from_angle(spin + float(i) * TAU / 5.0) * r * 0.6, 1.3, Color("b7c2b0"))
		"monster":
			LabSurface.circle(c,center, r, tire)
			# Крупные грунтозацепы по кругу.
			for i in range(16):
				var a = spin + float(i) * TAU / 16.0
				var n = Vector2.from_angle(a)
				var t = n.orthogonal()
				LabSurface.polygon(c,PackedVector2Array([center + n * (r - 3.0) - t * 4.0, center + n * (r + 3.0) - t * 3.0, center + n * (r + 3.0) + t * 3.0, center + n * (r - 3.0) + t * 4.0]), Color("262e33"))
			c.draw_arc(center, r - 7.0, 0, TAU, 32, Color("2e373c"), 3.0, true)
			LabSurface.circle(c,center, r * 0.5, Color("9aa8b0"))
			LabSurface.circle(c,center, r * 0.42, Color("5d6b74"))
			for i in range(6):
				var a = spin + float(i) * TAU / 6.0
				LabSurface.line(c,center + Vector2.from_angle(a) * r * 0.14, center + Vector2.from_angle(a) * r * 0.42, Color("c7d2d8"), 3.0, true)
			LabSurface.circle(c,center, r * 0.14, AMBER_SPRING)
		_:
			LabSurface.circle(c,center, r, tire)
			for i in range(14):
				var a = spin + float(i) * TAU / 14.0
				LabSurface.line(c,center + Vector2.from_angle(a) * (r - 2.5), center + Vector2.from_angle(a) * r, Color("2d363c"), 2.0)
			LabSurface.circle(c,center, r * 0.62, Color("b9c6cd"))
			LabSurface.circle(c,center, r * 0.5, Color("6d7f8c"))
			for i in range(5):
				var a = spin + float(i) * TAU / 5.0
				LabSurface.line(c,center + Vector2.from_angle(a) * r * 0.16, center + Vector2.from_angle(a) * r * 0.5, Color("d8e2e6"), 2.5, true)
			LabSurface.circle(c,center, r * 0.16, Color("3a4a55"))
			c.draw_arc(center, r * 0.62, -2.4, -1.2, 8, Color(1, 1, 1, 0.35), 1.5, true)
