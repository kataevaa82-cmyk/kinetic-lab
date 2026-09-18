class_name LabRobot
extends Node2D

var parts: Array[LabBody] = []
var joints: Array[PinJoint2D] = []
var variant = "robot"
var health = 100.0
# Общий для всех частей барьер: одно приземление робота — одно попадание,
# а не одиннадцать (по числу пластин в группе "bodies").
var impact_guard = 0.0
var pending_impact = 0.0
var pending_impact_part: LabBody
# Тот же барьер для порезов от лежащего оружия: робот, прошедший через груду
# клинков, получает одну рану за 0.2 с, а не по ране от каждого клинка на
# каждую из одиннадцати пластин — иначе куча мечей убивает за полсекунды.
var cut_guard = 0.0
# Разряд бьёт робота целиком, а не каждую пластину по отдельности.
var shock_guard = 0.0
# Часть, которая начисляет урон от огня за весь корпус.
var fire_source: LabBody
var max_health = 100.0
var tint = LabArt.TEAL
var game: Node2D
var serial = 0
var stun = 0.0
var age = 0.0
var dead = false
var death_time = 0.0
var rest_time = 0.0
var wake_grace = 0.0
var corpse_settled = false
var corpse_supports: Dictionary = {}
var support_height = 620.0
var support_velocity = Vector2.ZERO
var active = false
var ability_cooldown = 0.0
var size_scale = 1.0
var mass_scale = 1.0
var gravity_factor = 1.0
var drive_direction = 1.0
var held_gun: LabBody
var gun_joint: PinJoint2D
var held_gun_left: LabBody
var gun_joint_left: PinJoint2D
var virus = ""
var act = ""
var act_time = 0.0
var act_span = 0.0
var act_strike_fired = false
var act_dir = Vector2.RIGHT
var act_power = 1.0
var act_spec: Dictionary = {}
var ai_target: LabRobot
var ai_weapon: LabBody
var think_timer = 0.0
var attack_timer = 0.0
var ai_state = "idle"
var life_timer = 0.0
var life_goal_x = 0.0
var life_focus: Node2D
var social_target: LabRobot
var laps = 0
var acid_timer = 0.0
var nitro = false
var overclock_timer = 0.0

const JOINT_SPECS = [
	{"a": 1, "b": 0, "offset": Vector2(0, -135), "limit": 0.4},
	{"a": 1, "b": 2, "offset": Vector2(0, -89), "limit": 0.3},
	{"a": 1, "b": 3, "offset": Vector2(-19, -127), "limit": 1.7},
	{"a": 3, "b": 4, "offset": Vector2(-24, -97), "limit": 1.5},
	{"a": 1, "b": 5, "offset": Vector2(19, -127), "limit": 1.7},
	{"a": 5, "b": 6, "offset": Vector2(24, -97), "limit": 1.5},
	{"a": 2, "b": 7, "offset": Vector2(-9, -67), "limit": 0.8},
	{"a": 7, "b": 8, "offset": Vector2(-9, -34), "limit": 1.0},
	{"a": 2, "b": 9, "offset": Vector2(9, -67), "limit": 0.8},
	{"a": 9, "b": 10, "offset": Vector2(9, -34), "limit": 1.0}
]

const PART_OFFSETS = [
	Vector2(0, -150),
	Vector2(0, -112),
	Vector2(0, -78),
	Vector2(-23, -113),
	Vector2(-24, -81),
	Vector2(23, -113),
	Vector2(24, -81),
	Vector2(-9, -51),
	Vector2(-9, -17),
	Vector2(9, -51),
	Vector2(9, -17)
]

func is_part_attached(idx: int) -> bool:
	if idx < 0 or idx >= parts.size() or not is_instance_valid(parts[idx]): return false
	if idx == 1: return true
	if joints.size() < 10: return true
	match idx:
		0: return is_instance_valid(joints[0])
		2: return is_instance_valid(joints[1])
		3: return is_instance_valid(joints[2])
		4: return is_instance_valid(joints[2]) and is_instance_valid(joints[3])
		5: return is_instance_valid(joints[4])
		6: return is_instance_valid(joints[4]) and is_instance_valid(joints[5])
		7: return is_instance_valid(joints[1]) and is_instance_valid(joints[6])
		8: return is_instance_valid(joints[1]) and is_instance_valid(joints[6]) and is_instance_valid(joints[7])
		9: return is_instance_valid(joints[1]) and is_instance_valid(joints[8])
		10: return is_instance_valid(joints[1]) and is_instance_valid(joints[8]) and is_instance_valid(joints[9])
	return false

func connected_parts(idx: int = 1) -> Array[LabBody]:
	var result: Array[LabBody] = []
	if idx < 0 or idx >= parts.size(): return result
	var indices: Array[int] = [idx]
	var cursor = 0
	while cursor < indices.size():
		var current = indices[cursor]
		cursor += 1
		if is_instance_valid(parts[current]): result.append(parts[current])
		for j_idx in range(joints.size()):
			if not is_instance_valid(joints[j_idx]): continue
			var spec: Dictionary = JOINT_SPECS[j_idx]
			var neighbor = -1
			if spec.a == current: neighbor = spec.b
			elif spec.b == current: neighbor = spec.a
			if neighbor >= 0 and neighbor not in indices: indices.append(neighbor)
	return result

func update_part_collisions() -> void:
	for body in parts:
		if not is_instance_valid(body): continue
		var connected = connected_parts(body.part_index)
		for other in parts:
			if other == body or not is_instance_valid(other): continue
			if other in connected: body.add_collision_exception_with(other)
			else: body.remove_collision_exception_with(other)

func queue_impact(body: LabBody, amount: float) -> void:
	if dead or impact_guard > 0.0 or not is_part_attached(body.part_index): return
	if amount <= pending_impact: return
	if pending_impact <= 0.0: _apply_impact.call_deferred()
	pending_impact = amount
	pending_impact_part = body

func _apply_impact() -> void:
	var amount = pending_impact
	var body = pending_impact_part
	pending_impact = 0.0
	pending_impact_part = null
	if dead or amount <= 0.0 or not is_instance_valid(body): return
	impact_guard = 0.18
	body.damage(amount, Vector2.ZERO)
	if is_instance_valid(game):
		game.fx.emit_sparks(body.global_position, 4, LabArt.AMBER)
		game.play_sound("hit", clampf(amount / 60.0, 0.12, 0.5))

func _place_rest_pose(idx: int, parent: LabBody) -> void:
	# Ставит деталь и всё, что к ней крепится ниже по цепочке, в позу покоя
	# относительно родителя — с учётом того, где родитель сейчас и как повёрнут.
	var part_b: LabBody = parts[idx]
	if not is_instance_valid(part_b) or not is_instance_valid(parent): return
	var rel: Vector2 = (PART_OFFSETS[idx] - PART_OFFSETS[parent.part_index]) * size_scale
	part_b.freeze = false
	part_b.global_position = parent.global_transform * rel
	part_b.rotation = parent.rotation
	part_b.linear_velocity = parent.linear_velocity
	part_b.angular_velocity = 0.0
	for spec in JOINT_SPECS:
		if spec["a"] == idx: _place_rest_pose(spec["b"], part_b)

func repair_all_joints() -> void:
	if parts.size() < 11: return
	# Сначала собираем детали, потом ставим шарниры. Раньше шарнир ставился
	# в точку относительно места появления робота, а не туда, где он сейчас:
	# стоило роботу отойти, и отремонтированные детали стягивало к пустому
	# месту в сотнях пикселей. Вдобавок ставилась на место только сама
	# оторванная деталь, а уцелевшее под ней (предплечье под плечом) оставалось
	# лежать и рвало новую сборку.
	for j_idx in range(JOINT_SPECS.size()):
		if not is_instance_valid(joints[j_idx]):
			_place_rest_pose(JOINT_SPECS[j_idx]["b"], parts[JOINT_SPECS[j_idx]["a"]])
	for a in parts:
		for b in parts:
			if a != b and is_instance_valid(a) and is_instance_valid(b):
				a.add_collision_exception_with(b)
	for j_idx in range(JOINT_SPECS.size()):
		if not is_instance_valid(joints[j_idx]):
			var spec: Dictionary = JOINT_SPECS[j_idx]
			var a_idx: int = spec["a"]
			var b_idx: int = spec["b"]
			var anchor: Vector2 = parts[a_idx].global_transform * ((spec["offset"] - PART_OFFSETS[a_idx]) * size_scale)
			var joint = PinJoint2D.new()
			joint.position = to_local(anchor)
			add_child(joint)
			joint.node_a = joint.get_path_to(parts[a_idx])
			joint.node_b = joint.get_path_to(parts[b_idx])
			joint.disable_collision = true
			joint.angular_limit_enabled = true
			var limit: float = spec["limit"]
			joint.angular_limit_lower = -limit
			joint.angular_limit_upper = limit
			joint.softness = 0.04
			joints[j_idx] = joint

func _ready() -> void:
	add_to_group("robots")
	configure_variant()
	# All coordinates are relative to the feet. Each limb is a real rigid body.
	part("head",Vector2(0,-150)*size_scale,Vector2(28,28)*size_scale,1.3)
	part("torso",Vector2(0,-112)*size_scale,Vector2(30,44)*size_scale,4.0)
	part("pelvis",Vector2(0,-78)*size_scale,Vector2(28,22)*size_scale,2.5)
	part("arm",Vector2(-23,-113)*size_scale,Vector2(11,32)*size_scale,0.8)
	part("arm",Vector2(-24,-81)*size_scale,Vector2(10,31)*size_scale,0.7)
	part("arm",Vector2(23,-113)*size_scale,Vector2(11,32)*size_scale,0.8)
	part("arm",Vector2(24,-81)*size_scale,Vector2(10,31)*size_scale,0.7)
	part("leg",Vector2(-9,-51)*size_scale,Vector2(13,34)*size_scale,1.6)
	part("leg",Vector2(-9,-17)*size_scale,Vector2(13,34)*size_scale,1.3)
	part("leg",Vector2(9,-51)*size_scale,Vector2(13,34)*size_scale,1.6)
	part("leg",Vector2(9,-17)*size_scale,Vector2(13,34)*size_scale,1.3)
	for a in parts:
		for b in parts:
			if a != b: a.add_collision_exception_with(b)
	for spec in JOINT_SPECS:
		pin(spec.a, spec.b, spec.offset * size_scale, spec.limit)

func configure_variant() -> void:
	match variant:
		"robot_scout": tint=Color("54d9ff"); max_health=70; size_scale=0.78; mass_scale=0.62
		"robot_titan": tint=Color("d99b55"); max_health=280; size_scale=1.18; mass_scale=1.85
		"robot_jumper": tint=Color("a7e05c"); max_health=105; mass_scale=0.85
		"robot_magnet": tint=Color("b278e8"); max_health=125; mass_scale=1.15
		"robot_tesla": tint=Color("5da8ff"); max_health=110
		"robot_bomber": tint=Color("ef6f62"); max_health=85; mass_scale=1.1
		"robot_medic": tint=Color("65e39a"); max_health=115
		"robot_antigrav": tint=Color("df7cf2"); max_health=90; mass_scale=0.72; gravity_factor=0.28
		"robot_runner": tint=Color("ffcc55"); max_health=90; mass_scale=0.82
		"robot_acrobat": tint=Color("ff82ad"); max_health=80; size_scale=0.9; mass_scale=0.68
	health=max_health

func part(kind: String, offset: Vector2, dimensions: Vector2, weight: float) -> void:
	var body = LabBody.new()
	body.kind=kind
	body.position=offset
	body.dimensions=dimensions
	body.mass=weight*mass_scale
	body.health=max_health
	body.gravity_factor=gravity_factor
	body.ragdoll=self
	body.game=game
	body.tint=tint
	body.part_index=parts.size()
	body.serial=game.next_id()
	add_child(body)
	body.can_sleep = false
	# The head and torso are visual anchors. Extra damping prevents energy from
	# a held heavy weapon travelling through the ragdoll and spinning them.
	if kind=="head": body.angular_damp=8.0
	elif kind in ["torso","pelvis"]: body.angular_damp=4.5
	parts.append(body)

func pin(a: int, b: int, offset: Vector2, limit: float) -> void:
	var joint = PinJoint2D.new()
	joint.position=offset
	add_child(joint)
	joint.node_a=joint.get_path_to(parts[a])
	joint.node_b=joint.get_path_to(parts[b])
	joint.disable_collision=true
	joint.angular_limit_enabled=true
	joint.angular_limit_lower=-limit
	joint.angular_limit_upper=limit
	joint.softness=0.04
	joints.append(joint)

func _physics_process(delta: float) -> void:
	age+=delta
	impact_guard=maxf(0,impact_guard-delta)
	cut_guard=maxf(0,cut_guard-delta)
	shock_guard=maxf(0,shock_guard-delta)
	# Замах разгонял собственные конечности до 800-900 px/с: робот лупил
	# себя о пол, расшвыривал всё вокруг и налетал на отброшенное. Крутящие
	# моменты анимации остались прежними, ограничена только скорость — форма
	# движения сохраняется, взрывной разлёт пропадает.
	if not dead and stun <= 0.0 and act!="" and _has_nearby_support():
		# Отдача от собственного замаха не подбрасывает бойца: замером молот
		# отрывал его от пола на 40-60 пикселей со скоростью 200-300 px/с
		# вверх. Ограничение, а не сила: вниз скорость не трогаем, а держится
		# оно только на время самого замаха.
		for b in parts:
			if not is_instance_valid(b) or b.freeze or not is_part_attached(b.part_index): continue
			if b.linear_velocity.length()>420.0: b.linear_velocity=b.linear_velocity.limit_length(420.0)
			if b.linear_velocity.y<-70.0: b.linear_velocity.y=-70.0
	stun=maxf(0,stun-delta)
	ability_cooldown=maxf(0,ability_cooldown-delta)
	think_timer=maxf(0,think_timer-delta)
	attack_timer=maxf(0,attack_timer-delta)
	life_timer=maxf(0,life_timer-delta)
	# Syringe dynamic effects (run whether alive or dead!)
	if acid_timer > 0:
		acid_timer -= delta
		if not dead: hurt(delta * 22.0)
		if is_instance_valid(game) and parts.size() > 1 and int(age * 16) % 4 == 0:
			game.fx.emit_sparks(parts[1].global_position + Vector2(randf_range(-12, 12), randf_range(-14, 14)), 2, Color(0.3, 0.95, 0.2), Vector2.UP * 30.0)
		if randf() < delta * 0.75:
			var valid_j: Array[int] = []
			for j_i in range(joints.size()):
				if is_instance_valid(joints[j_i]): valid_j.append(j_i)
			if not valid_j.is_empty():
				dismember_joint(valid_j.pick_random())
	if overclock_timer > 0:
		overclock_timer -= delta
		attack_timer = maxf(0, attack_timer - delta * 1.5)
		if is_instance_valid(game) and parts.size() > 1 and int(age * 18) % 4 == 0:
			game.fx.emit_sparks(parts[1].global_position + Vector2(randf_range(-10, 10), randf_range(-12, 12)), 2, Color(0.3, 0.85, 1.0), Vector2.ZERO)
	if nitro and parts.size() > 1 and parts[1].linear_velocity.length() > 420:
		nitro = false
		if is_instance_valid(game): game.explode(parts[1].global_position, 280, 2.0)
		die()
		return
	# Extreme joint tension break check (runs for living and dead ragdolls!)
	for j_i in range(joints.size()):
		var j = joints[j_i]
		if is_instance_valid(j):
			var spec: Dictionary = JOINT_SPECS[j_i]
			var na = parts[spec.a]
			var nb = parts[spec.b]
			var anchor_a = na.global_transform * ((spec.offset - PART_OFFSETS[spec.a]) * size_scale)
			var anchor_b = nb.global_transform * ((spec.offset - PART_OFFSETS[spec.b]) * size_scale)
			if anchor_a.distance_to(anchor_b) > 60.0 * size_scale:
				dismember_joint(j_i)
	if dead:
		death_time+=delta
		wake_grace=maxf(0,wake_grace-delta)
		var moving=false
		var has_support=false
		for body in parts:
			if not is_instance_valid(body) or body.freeze: continue
			moving = moving or body.linear_velocity.length()>28 or absf(body.angular_velocity)>1.2
			has_support = has_support or not body.floor_contacts.is_empty()
		if corpse_settled:
			var support_changed = false
			for support in corpse_supports:
				if not is_instance_valid(support) or support.is_queued_for_deletion() or not support.global_transform.is_equal_approx(corpse_supports[support]):
					support_changed = true
					break
			if moving or support_changed: wake_for(0.3)
			else: return
		rest_time=0.0 if moving else rest_time+delta
		# Sleep only after actual rest. Freezing after a timeout could suspend a
		# moving corpse, and turned it into an immovable object on platforms.
		if not corpse_settled and has_support and wake_grace<=0 and rest_time>0.65:
			corpse_supports.clear()
			for body in parts:
				if not is_instance_valid(body) or body.freeze: continue
				for support in body.floor_contacts:
					if is_instance_valid(support): corpse_supports[support] = support.global_transform
				body.linear_velocity=Vector2.ZERO
				body.angular_velocity=0.0
				body.sleeping=true
			corpse_settled=true
		return
	# A living robot has neck and waist servos. Limit solver spikes coming from
	# heavy held objects; dead ragdolls remain completely unconstrained above.
	if stun>0: return
	if is_on_floor():
		for i in range(3):
			if is_part_attached(i) and not parts[i].freeze:
				var limit = [4.0, 3.5, 4.5][i]
				parts[i].angular_velocity=clampf(parts[i].angular_velocity,-limit,limit)
	if virus!="" and active:
		process_virus()
	elif active:
		process_ability()
		process_ai()
	if act_time>0:
		act_time=maxf(0,act_time-delta)
		if act_time<=0:
			act=""
			if is_instance_valid(held_gun): held_gun.angular_damp=12.0
	if is_instance_valid(held_gun):
		hold_weapon_pose(delta)
	if is_instance_valid(held_gun_left):
		hold_weapon_pose_left(delta)
	if not game.gravity and virus!="virus_float": return
	# A gentle posture controller gives the robot balance but yields to impacts.
	var on_floor = is_on_floor()
	if not on_floor and not (virus=="virus_float" and active): return
	var heights=[-150,-112,-78,-113,-81,-113,-81,-51,-17,-51,-17]
	var holding=is_instance_valid(held_gun)
	var holding_left=is_instance_valid(held_gun_left)
	for i in range(parts.size()):
		if not is_part_attached(i): continue
		var body = parts[i]
		if body.freeze: continue
		if holding and (i==5 or i==6): continue
		if holding_left and (i==3 or i==4): continue
		var angle = wrapf(body.rotation,-PI,PI)
		body.apply_torque(clampf(-angle*10000-body.angular_velocity*1100,-18000,18000)*body.mass)
		var height_error=support_height+heights[i]*size_scale-body.global_position.y
		var vertical_speed = body.linear_velocity.y - support_velocity.y
		body.apply_central_force(Vector2(0,clampf(height_error*70-vertical_speed*14-900*body.gravity_scale,-2400,1200)*body.mass))
	var torso = parts[1]
	if absf(torso.rotation)<0.7:
		var left_ok = is_part_attached(8)
		var right_ok = is_part_attached(10)
		if left_ok or right_ok:
			var foot_x = 0.0
			if left_ok and right_ok:
				foot_x = (parts[8].global_position.x+parts[10].global_position.x)*0.5
			elif left_ok:
				foot_x = parts[8].global_position.x
			else:
				foot_x = parts[10].global_position.x
			var stance_mult = 1.7 if act != "" else 1.0
			torso.apply_central_force(Vector2(clampf((foot_x-torso.global_position.x)*260*stance_mult-(torso.linear_velocity.x-support_velocity.x)*28*stance_mult,-1400,1400), 0))

func is_on_floor() -> bool:
	if parts.size() < 11: return false
	var count = 0
	var height = 0.0
	var velocity = Vector2.ZERO
	for idx in [8, 10]:
		if not is_part_attached(idx) or parts[idx].freeze: continue
		var foot = parts[idx]
		var support = _foot_support(foot)
		if support.is_empty(): continue
		var contact_height = support.position.y
		var contact_velocity = support.collider.linear_velocity if support.collider is RigidBody2D else Vector2.ZERO
		# A foot leaving a platform is airborne even while its last contact is
		# still reported for one physics tick.
		if act == "" and foot.linear_velocity.y - contact_velocity.y < -60.0: continue
		count += 1
		height += contact_height
		velocity += contact_velocity
	if count == 0: return false
	support_height = height / count
	support_velocity = velocity / count
	return true

func _foot_support(foot: LabBody) -> Dictionary:
	# Solver contacts may disappear briefly as an animated foot lifts a few
	# pixels. A short ray retains balance across that gap, on any surface.
	var half_height = (absf(cos(foot.rotation)) * foot.dimensions.y + absf(sin(foot.rotation)) * foot.dimensions.x) * 0.5
	var query = PhysicsRayQueryParameters2D.create(foot.global_position, foot.global_position + Vector2.DOWN * (half_height + 8.0), 3)
	var excluded: Array[RID] = []
	for body in parts:
		if is_instance_valid(body): excluded.append(body.get_rid())
	for gun in [held_gun, held_gun_left]:
		if is_instance_valid(gun): excluded.append(gun.get_rid())
	query.exclude = excluded
	var hit = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.normal.dot(Vector2.UP) > 0.55: return hit
	return {}

func _has_nearby_support() -> bool:
	for idx in [8, 10]:
		if is_part_attached(idx) and not parts[idx].freeze and not _foot_support(parts[idx]).is_empty(): return true
	return false

func process_ability() -> void:
	var torso=parts[1]
	match variant:
		"robot_runner":
			if torso.global_position.x>1800: drive_direction=-1
			elif torso.global_position.x<-800: drive_direction=1
			var target_speed=260.0
			var force=(target_speed*drive_direction-torso.linear_velocity.x)*torso.mass*18
			torso.apply_central_force(Vector2(clampf(force,-18000,18000),0))
		"robot_jumper":
			if ability_cooldown<=0 and is_on_floor():
				ability_cooldown=1.55
				for i in range(parts.size()):
					if is_part_attached(i): parts[i].apply_central_impulse(Vector2(0,-parts[i].mass*330))
				if is_part_attached(8): game.fx.emit_sparks(parts[8].global_position,10,tint,Vector2.UP*100)
		"robot_acrobat":
			if ability_cooldown<=0 and is_on_floor():
				ability_cooldown=1.8
				for i in range(parts.size()):
					if is_part_attached(i): parts[i].apply_central_impulse(Vector2(drive_direction*parts[i].mass*90,-parts[i].mass*300))
				torso.apply_torque_impulse(1500*drive_direction)
				drive_direction*=-1
		"robot_magnet":
			for body in game.get_tree().get_nodes_in_group("bodies"):
				if body in parts or body.freeze or body.kind in ["crate","plank","glass","balloon","debris"]: continue
				var offset=torso.global_position-body.global_position
				var dist=offset.length()
				if dist>15 and dist<320:
					body.apply_central_force(offset.normalized()*(1.0-dist/320.0)*body.mass*1850.0)
					if is_instance_valid(game) and int(age * 16) % 8 == 0 and randf() < 0.25:
						game.fx.emit_sparks(body.global_position, 1, Color("b278e8"), offset.normalized() * 35.0)
		"robot_tesla":
			if ability_cooldown<=0:
				ability_cooldown=0.7
				var target: LabRobot
				var best=260.0
				for other in game.get_tree().get_nodes_in_group("robots"):
					if other==self or other.dead: continue
					var distance=torso.global_position.distance_to(other.parts[1].global_position)
					if distance<best: best=distance; target=other
				if target:
					target.hurt(9)
					target.parts[1].apply_central_impulse((target.parts[1].global_position-torso.global_position).normalized()*target.parts[1].mass*90)
					game.fx.beam(torso.global_position,target.parts[1].global_position)
		"robot_medic":
			if ability_cooldown<=0:
				ability_cooldown=0.45
				for other in game.get_tree().get_nodes_in_group("robots"):
					if other!=self and not other.dead and torso.global_position.distance_to(other.parts[1].global_position)<230:
						other.heal(4)
						if is_instance_valid(game) and other.health < other.max_health:
							game.fx.emit_sparks(other.parts[1].global_position, 4, Color("65e39a"), Vector2.UP * 20.0)

func process_ai() -> void:
	if parts.size()<7 or dead or virus!="": return
	if game.robot_should_aim(self):
		ai_state="manual"
		return
	if think_timer<=0:
		think_timer=randf_range(0.22,0.42)
		ai_target=_choose_combat_target()
		ai_weapon=null
		if not is_instance_valid(held_gun) and is_instance_valid(ai_target) and _role_uses_weapons():
			ai_weapon=game.nearest_weapon(parts[1].global_position,620.0)
		if life_timer<=0:
			_choose_life_goal()
	var danger: LabBody
	var danger_distance=145.0
	for body in game.get_tree().get_nodes_in_group("bodies"):
		if body.kind not in ["barrel","mine","grenade","sticky"]: continue
		if body.kind!="barrel" and not body.active: continue
		var d=parts[1].global_position.distance_to(body.global_position)
		if d<danger_distance: danger_distance=d; danger=body
	if is_instance_valid(danger):
		ai_state="evade"
		_drive_x(signf(parts[1].global_position.x-danger.global_position.x)*190.0)
		if ability_cooldown<=0 and is_on_floor():
			ability_cooldown=0.9
			for part_body in parts: part_body.apply_central_impulse(Vector2(0,-part_body.mass*85))
		return
	# Bombers stalk their target and detonate only at close range. This makes
	# their autonomous life readable instead of exploding on activation.
	if variant=="robot_bomber" and is_instance_valid(ai_target):
		var bomb_dx=ai_target.parts[1].global_position.x-parts[1].global_position.x
		var bomb_distance=parts[1].global_position.distance_to(ai_target.parts[1].global_position)
		if bomb_distance<92.0 and age>0.75:
			ai_state="detonate"
			game.explode(parts[1].global_position,260,1.25)
			return
		ai_state="stalk"
		_drive_x(signf(bomb_dx)*92.0)
		return
	if not is_instance_valid(held_gun):
		if is_instance_valid(ai_weapon):
			var weapon_dx=ai_weapon.global_position.x-parts[1].global_position.x
			ai_state="seek_weapon"
			if absf(weapon_dx)>52.0:
				_drive_x(signf(weapon_dx)*(145.0 if variant in ["robot_scout","robot_runner"] else 105.0))
			elif parts[6].global_position.distance_to(ai_weapon.global_position)<105.0:
				game.equip_gun(self,ai_weapon,false)
				ai_weapon=null
				ai_state="armed"
			return
		if is_instance_valid(ai_target):
			var unarmed_dx=ai_target.parts[1].global_position.x-parts[1].global_position.x
			if absf(unarmed_dx)>70:
				ai_state="intercept"
				_drive_x(signf(unarmed_dx)*(82.0 if variant=="robot_titan" else 115.0))
			elif attack_timer<=0:
				attack_timer=0.85
				ai_state="shove"
				var shove_dir=Vector2(signf(unarmed_dx),-0.18).normalized()
				ai_target.parts[1].apply_central_impulse(shove_dir*ai_target.parts[1].mass*105)
				parts[1].apply_central_impulse(-shove_dir*parts[1].mass*24)
				game.fx.emit_sparks(ai_target.parts[1].global_position,5,tint,shove_dir*55)
			return
		_process_life()
		return
	if not is_instance_valid(ai_target):
		ai_state="guard"
		_drive_x(0)
		return
	var target_pos=ai_target.parts[1].global_position
	var dx=target_pos.x-parts[1].global_position.x
	var distance=parts[1].global_position.distance_to(target_pos)
	var melee=held_gun.kind in game.MELEE
	var preferred=62.0 if melee else (300.0 if held_gun.kind in ["rifle","railgun","crossbow","harpoon"] else 220.0)
	var retreat=health<max_health*0.28
	if retreat and distance<420:
		ai_state="retreat"
		_drive_x(-signf(dx)*145.0)
	elif distance>preferred+45:
		ai_state="advance"
		_drive_x(signf(dx)*(135.0 if melee else 90.0))
	elif not melee and distance<preferred-70:
		ai_state="space"
		_drive_x(-signf(dx)*100.0)
	else:
		ai_state="attack"
		_drive_x(0)
	if attack_timer<=0:
		if melee and distance<105:
			attack_timer=randf_range(0.55,0.85)
			game.fire_weapon(held_gun)
		elif not melee and distance<760:
			attack_timer=randf_range(0.28,0.62)
			game.fire_weapon(held_gun)

func _role_uses_weapons() -> bool:
	return is_part_attached(6) and (variant in ["robot","robot_titan","robot_tesla"])

func _is_dangerous(other: LabRobot) -> bool:
	if not is_instance_valid(other) or other.dead: return false
	if other.variant in ["robot_tesla","robot_bomber"] and other.active: return true
	return other.active and is_instance_valid(other.held_gun) and other.variant not in ["robot_medic","robot_scout"]

func _choose_combat_target() -> LabRobot:
	if variant in ["robot_tesla","robot_bomber"]: return _nearest_robot()
	var best: LabRobot
	var distance=520.0 if variant=="robot_titan" else 350.0
	for other in game.get_tree().get_nodes_in_group("robots"):
		if other==self or not _is_dangerous(other) or other.parts.size()<2: continue
		var d=parts[1].global_position.distance_to(other.parts[1].global_position)
		if d<distance:
			distance=d
			best=other
	return best

func _choose_life_goal() -> void:
	life_timer=randf_range(2.2,4.8)
	life_goal_x=randf_range(-560.0,1740.0)
	life_focus=null
	social_target=null
	var origin=parts[1].global_position
	match variant:
		"robot": life_focus=_nearest_body_of_kinds(["crate","plank","metal","glass","wheel"],480.0)
		"robot_scout": life_focus=_nearest_body_of_kinds(game.GADGETS+game.TOYS,650.0)
		"robot_titan": social_target=_nearest_role(["robot_medic","robot_scout","robot","robot_jumper"])
		"robot_jumper","robot_acrobat": social_target=_nearest_role(["robot_runner","robot_jumper","robot_acrobat","robot_scout"])
		"robot_magnet": life_focus=_nearest_body_of_kinds(["metal","weight","anvil","lead","wheel"]+game.WEAPONS+game.EXOTIC+game.MELEE,620.0)
		"robot_medic": social_target=_most_wounded_robot()
		"robot_antigrav": life_goal_x=clampf(origin.x+randf_range(-520.0,520.0),-600.0,1780.0)

func _process_life() -> void:
	var torso=parts[1]
	match variant:
		"robot":
			if is_instance_valid(life_focus):
				var dx=life_focus.global_position.x-torso.global_position.x
				if absf(dx)>82:
					ai_state="work_walk"
					_drive_x(signf(dx)*70.0)
				else:
					ai_state="inspect"
					_drive_x(0)
					if attack_timer<=0:
						attack_timer=1.4
						life_focus.apply_central_impulse(Vector2(signf(dx)*12.0,-5.0)*life_focus.mass)
			else: _roam("patrol",62.0)
		"robot_scout":
			if is_instance_valid(life_focus) and torso.global_position.distance_to(life_focus.global_position)<115:
				ai_state="scan_object"
				_drive_x(0)
			else: _roam("explore",145.0)
		"robot_titan":
			if is_instance_valid(social_target):
				var gap=social_target.parts[1].global_position.x-torso.global_position.x
				ai_state="escort"
				_drive_x(signf(gap)*72.0 if absf(gap)>155 else 0.0)
			else: _roam("guard_patrol",58.0)
		"robot_jumper": _follow_social("play",105.0,115.0)
		"robot_magnet":
			if is_instance_valid(life_focus):
				ai_state="collect"
				var gap=life_focus.global_position.x-torso.global_position.x
				_drive_x(signf(gap)*68.0 if absf(gap)>135 else 0.0)
			else: _roam("search_metal",55.0)
		"robot_medic":
			if is_instance_valid(social_target):
				ai_state="rescue"
				var gap=social_target.parts[1].global_position.x-torso.global_position.x
				_drive_x(signf(gap)*95.0 if absf(gap)>115 else 0.0)
			else: _roam("rounds",52.0)
		"robot_antigrav":
			ai_state="drift"
			var desired=signf(life_goal_x-torso.global_position.x)*72.0
			torso.apply_central_force(Vector2((desired-torso.linear_velocity.x)*torso.mass*5.5,(350.0-torso.global_position.y)*torso.mass*4.0))
		"robot_runner":
			ai_state="race"
			if torso.global_position.x>1800 and drive_direction>0: laps+=1
			elif torso.global_position.x<-700 and drive_direction<0: laps+=1
		"robot_acrobat": _follow_social("perform",135.0,155.0)
		_: _roam("wander",70.0)

func _roam(state: String, speed: float) -> void:
	var dx=life_goal_x-parts[1].global_position.x
	if absf(dx)<55:
		ai_state="observe"
		_drive_x(0)
	else:
		ai_state=state
		_drive_x(signf(dx)*speed)

func _follow_social(state: String, speed: float, spacing: float) -> void:
	if not is_instance_valid(social_target):
		_roam(state,speed*0.65)
		return
	var gap=social_target.parts[1].global_position.x-parts[1].global_position.x
	ai_state=state
	_drive_x(signf(gap)*speed if absf(gap)>spacing else 0.0)

func _nearest_role(roles: Array) -> LabRobot:
	var best: LabRobot
	var distance=720.0
	for other in game.get_tree().get_nodes_in_group("robots"):
		if other==self or other.dead or other.variant not in roles or other.parts.size()<2: continue
		var d=parts[1].global_position.distance_to(other.parts[1].global_position)
		if d<distance: distance=d; best=other
	return best

func _most_wounded_robot() -> LabRobot:
	var best: LabRobot
	var ratio=0.92
	for other in game.get_tree().get_nodes_in_group("robots"):
		if other==self or other.dead or other.parts.size()<2: continue
		var value=other.health/maxf(other.max_health,1.0)
		if value<ratio: ratio=value; best=other
	return best

func _nearest_body_of_kinds(kinds: Array, radius: float) -> LabBody:
	var best: LabBody
	var distance=radius
	for body in game.get_tree().get_nodes_in_group("bodies"):
		if body in parts or body.kind not in kinds or is_instance_valid(body.holder) or body.freeze: continue
		var d=parts[1].global_position.distance_to(body.global_position)
		if d<distance: distance=d; best=body
	return best

func current_aim_point() -> Vector2:
	if game.robot_should_aim(self): return game.cursor
	if is_instance_valid(held_gun) and held_gun.kind in game.MELEE:
		if is_instance_valid(game.selected) and (game.selected == held_gun or game.selected.ragdoll == self):
			if not game.placing and game.tool == "grab" and not game.menu_open and not game.help_open:
				return game.cursor
	if active and virus=="" and is_instance_valid(ai_target) and ai_target.parts.size()>1:
		return ai_target.parts[1].global_position+Vector2(0,-8)
	return Vector2.INF

func infect(kind: String, turn_on: bool=true) -> void:
	purge_virus(false)
	virus=kind
	if turn_on: active=true
	ability_cooldown=0
	_apply_virus_body()
	for p in parts: p.queue_redraw()

func purge_virus(redraw: bool=true) -> void:
	virus=""
	_restore_virus_body()
	if redraw:
		for p in parts: p.queue_redraw()

func _apply_virus_body() -> void:
	if virus=="virus_float":
		for p in parts:
			p.gravity_factor=0.3
			p.gravity_scale=0.3 if is_instance_valid(game) and game.gravity else 0.0
	else:
		_restore_virus_body()

func _restore_virus_body() -> void:
	for p in parts:
		p.gravity_factor=gravity_factor
		p.gravity_scale=gravity_factor if is_instance_valid(game) and game.gravity else 0.0

func virus_color() -> Color:
	match virus:
		"virus_rage": return Color("ef6f62")
		"virus_dance": return Color("ff82ad")
		"virus_panic": return Color("ffcc55")
		"virus_guard": return Color("5da8ff")
		"virus_leap": return Color("a7e05c")
		"virus_orbit": return Color("b278e8")
		"virus_float": return Color("df7cf2")
		"virus_hunter": return Color("54d9ff")
		"virus_follow": return Color("65e39a")
		"virus_spin": return Color("4ce0bd")
	return LabArt.TEAL

func toggle_active() -> void:
	if virus!="":
		active=not active
		ability_cooldown=0
		for body in parts: body.queue_redraw()
		return
	active=not active
	ability_cooldown=0
	think_timer=0
	ai_state="scan" if active else "idle"
	for body in parts: body.queue_redraw()

func ability_status() -> String:
	if virus!="":
		return game.t("Поведение включено","Behavior on") if active else game.t("Поведение выключено","Behavior off")
	if active: return game.t("Режим жизни: ","Life mode: ")+role_name()
	return game.t("Режим жизни выключен","Life mode disabled")

func role_name() -> String:
	match variant:
		"robot_scout": return game.t("разведчик","explorer")
		"robot_titan": return game.t("охранник","guardian")
		"robot_jumper": return game.t("попрыгун","playful jumper")
		"robot_magnet": return game.t("собиратель","collector")
		"robot_tesla": return game.t("охотник","hunter")
		"robot_bomber": return game.t("подрывник","ambusher")
		"robot_medic": return game.t("медик","medic")
		"robot_antigrav": return game.t("воздушный странник","air wanderer")
		"robot_runner": return game.t("гонщик","racer")
		"robot_acrobat": return game.t("акробат","performer")
	return game.t("рабочий","worker")

func _drive_x(speed: float) -> void:
	if not is_on_floor() or parts.size()<2: return
	var torso=parts[1]
	var effective_speed=speed*(2.2 if overclock_timer>0 else 1.0)
	var force_mult=26 if overclock_timer>0 else 16
	torso.apply_central_force(Vector2(clampf((effective_speed-torso.linear_velocity.x)*torso.mass*force_mult,-16000,16000),0))

func _nearest_robot() -> LabRobot:
	var best: LabRobot
	var dist=520.0
	if parts.size()<2: return best
	for other in game.get_tree().get_nodes_in_group("robots"):
		if other==self or other.dead or other.parts.size()<2: continue
		var d=parts[1].global_position.distance_to(other.parts[1].global_position)
		if d<dist: dist=d; best=other
	return best

func _nearest_thing() -> LabBody:
	var best: LabBody
	var dist=460.0
	if parts.size()<2: return best
	var origin=parts[1].global_position
	var other=_nearest_robot()
	if other: return other.parts[1]
	for body in game.get_tree().get_nodes_in_group("bodies"):
		if body in parts or body.kind in game.EPHEMERAL or body.kind in game.VIRUSES: continue
		var d=origin.distance_to(body.global_position)
		if d>24 and d<dist: dist=d; best=body
	return best

func process_virus() -> void:
	if parts.size()<2: return
	var torso=parts[1]
	match virus:
		"virus_rage","virus_hunter":
			var prey=_nearest_thing()
			if prey:
				var dx=prey.global_position.x-torso.global_position.x
				if absf(dx)>18: _drive_x(signf(dx)*130.0)
		"virus_follow":
			var buddy=_nearest_robot()
			if buddy:
				var gap=buddy.parts[1].global_position.x-torso.global_position.x
				if absf(gap)>70: _drive_x(signf(gap)*110.0)
				else: _drive_x(0)
		"virus_panic":
			if ability_cooldown<=0:
				ability_cooldown=0.55
				drive_direction=-1.0 if randf()<0.5 else 1.0
			_drive_x(drive_direction*160.0)
		"virus_dance":
			torso.apply_torque(sin(age*9.0)*2800.0)
			if ability_cooldown<=0 and is_on_floor():
				ability_cooldown=0.5
				for body in parts: body.apply_central_impulse(Vector2(sin(age*6.0)*body.mass*12,-body.mass*70))
		"virus_guard":
			for body in game.get_tree().get_nodes_in_group("bodies"):
				if body in parts or body.kind in game.EPHEMERAL: continue
				var offset=body.global_position-torso.global_position
				var d=offset.length()
				if d>20 and d<130:
					body.apply_central_force(offset.normalized()*(1.0-d/130.0)*body.mass*420)
		"virus_leap":
			if ability_cooldown<=0 and is_on_floor():
				ability_cooldown=1.7
				for body in parts: body.apply_central_impulse(Vector2(0,-body.mass*200))
		"virus_orbit":
			var hub=_nearest_thing()
			if hub:
				var offset=torso.global_position-hub.global_position
				var radius=offset.length()
				if radius>12:
					var tangent=offset.orthogonal().normalized()*drive_direction
					if drive_direction==0: drive_direction=1
					torso.apply_central_force(tangent*torso.mass*160+offset.normalized()*(180-radius)*torso.mass*6)
		"virus_float":
			var hover=400.0
			var yerr=hover-torso.global_position.y
			torso.apply_central_force(Vector2(sin(age*0.7)*torso.mass*40,clampf(yerr*28-torso.linear_velocity.y*12,-700,800)*torso.mass))
		"virus_spin":
			torso.apply_torque(clampf(4200-torso.angular_velocity*200,-6000,6000))

func heal(amount: float) -> void:
	if dead or amount <= 0.0: return
	health=minf(max_health,health+amount)
	for body in parts:
		body.health=minf(body.max_health,body.health+amount)
		body.queue_redraw()

func damage_tier() -> int:
	# 0 intact, 1 scuffed, 2 damaged, 3 critical. Drives the plating scars,
	# the eye colour and the inspector readout.
	if dead: return 3
	var ratio=health/maxf(max_health,1.0)
	if ratio>0.75: return 0
	if ratio>0.45: return 1
	if ratio>0.18: return 2
	return 3

func damage_label() -> Array:
	return [["Целый","Intact"],["Помят","Scuffed"],["Повреждён","Damaged"],["Критический","Critical"]][damage_tier()]

func hurt(amount: float, hit_part: int = -1) -> void:
	if dead or amount <= 0.0: return
	var was=damage_tier()
	health=maxf(0,health-amount)
	stun=maxf(stun,minf(amount*0.07,3.0))
	# Local hits damage the joint at the impact site. General health loss has
	# no anatomical target and must not randomly decapitate a healthy titan.
	if hit_part >= 0: damage_joint(hit_part, amount)
	# Nitro volatile explosion
	if nitro and (amount>=22.0 or health<=0):
		nitro=false
		if is_instance_valid(game) and parts.size()>1:
			game.explode(parts[1].global_position,280,2.0)
		die()
		return
	if health<=0: die()
	# Crossing into a worse condition is an event, not just a repaint: the
	# robot throws sparks and starts venting where the plating gave way.
	var now=damage_tier()
	if now>was and not dead and is_instance_valid(game) and parts.size()>1:
		var at=parts[1].global_position
		game.fx.emit_sparks(at,6+now*5,LabArt.AMBER if now<3 else LabArt.RED,Vector2.UP*40)
		if now>=2:
			for i in range(4+now):
				game.fx.particles.append({"p":at+Vector2(randf_range(-8,8),randf_range(-10,6)),"v":Vector2(randf_range(-24,24),randf_range(-52,-18)),"life":randf_range(0.7,1.5),"max_life":1.5,"c":Color("4d565c"),"s":randf_range(3.5,7.0),"gravity":-18.0,"glow":false,"smoke":true})
	for b in parts: b.queue_redraw()

func damage_joint(hit_part: int, amount: float, impulse: Vector2 = Vector2.ZERO) -> void:
	if hit_part < 0 or hit_part >= parts.size(): return
	if amount < maxf(50.0, max_health * 0.5): return
	var joint_indices = [0, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	dismember_joint(joint_indices[hit_part], impulse)

func apply_knockback(impulse: Vector2, hit_point: Vector2 = Vector2.ZERO, spin_torque: float = 0.0) -> void:
	if parts.is_empty(): return
	var imp_len = impulse.length()
	if imp_len < 5.0: return
	
	if dead:
		wake_for(3.0)
	else:
		var stun_time = clampf(imp_len * 0.0004 + 0.45, 0.5, 2.2)
		stun = maxf(stun, stun_time)
	
	var connected = connected_parts()
	for b in connected:
		if not b.freeze:
			b.sleeping = false
	
	var total_mass = 0.0
	for b in connected:
		if is_instance_valid(b): total_mass += b.mass
	if total_mass <= 0.01: total_mass = 1.0
	
	for b in connected:
		if not b.freeze:
			var part_imp = impulse * (b.mass / total_mass)
			b.apply_central_impulse(part_imp)
	
	if parts.size() > 1 and is_instance_valid(parts[1]) and not parts[1].freeze:
		var t = spin_torque
		if absf(t) < 1.0:
			t = (1.0 if impulse.x >= 0 else -1.0) * clampf(imp_len * 0.12, 250.0, 1400.0)
		else:
			t = clampf(t, -1800.0, 1800.0)
		parts[1].apply_torque_impulse(t)
		if is_part_attached(2) and not parts[2].freeze:
			parts[2].apply_torque_impulse(t * 0.4)

func palm() -> Vector2:
	if parts.size()<7: return global_position
	var hand=parts[6]
	return hand.global_position+Vector2(0,hand.dimensions.y*0.45).rotated(hand.rotation)

func hold_face() -> float:
	if parts.size()<7: return 1.0
	var face=signf(parts[6].global_position.x-parts[1].global_position.x)
	return 1.0 if face==0.0 else face

func palm_left() -> Vector2:
	if parts.size()<5: return global_position
	var hand=parts[4]
	return hand.global_position+Vector2(0,hand.dimensions.y*0.45).rotated(hand.rotation)
func hold_weapon_pose_left(delta: float) -> void:
	if parts.size()<5 or not is_instance_valid(held_gun_left): return
	if parts[3].freeze or parts[4].freeze or (joints.size()>3 and (not is_instance_valid(joints[2]) or not is_instance_valid(joints[3]))): return
	# Левая рука просто держит клинок в зеркальной стойке
	var face = hold_face()
	var hand = parts[4]
	var palm_pos = palm_left()
	var arm_dir = Vector2.DOWN.rotated(hand.rotation)
	var target_blade_ang = arm_dir.angle() + 0.80 * face
	var blend = 1.0 - exp(-delta * 24.0)
	held_gun_left.rotation = lerp_angle(held_gun_left.rotation, target_blade_ang, blend)
	var target_pos = palm_pos - held_gun_left.grip_local.rotated(held_gun_left.rotation)
	held_gun_left.global_position = target_pos
	held_gun_left.linear_velocity = hand.linear_velocity
	held_gun_left.angular_velocity = wrapf(target_blade_ang - held_gun_left.rotation, -PI, PI) * 16.0
	held_gun_left.set_deferred("lock_rotation", true)
	# Левая рука в зеркальной позе
	var u = 0.45 * face
	var f = 0.85 * face
	_torque_towards(parts[3], u, 1.0)
	_torque_towards(parts[4], f, 1.0)

func hold_weapon_pose(delta: float) -> void:
	if parts.size()<7 or not is_instance_valid(held_gun): return
	if parts[5].freeze or parts[6].freeze or (joints.size()>5 and (not is_instance_valid(joints[4]) or not is_instance_valid(joints[5]))): return
	var is_melee = held_gun.kind in game.MELEE
	var aim_point = current_aim_point()
	if not is_melee and held_gun.kind != "grenade":
		if aim_point != Vector2.INF:
			var hand_position = palm()
			var aim_vector = aim_point - hand_position
			if aim_vector.length() > 18.0:
				var aim_angle = aim_vector.angle()
				var blend = 1.0 - exp(-delta * 10.0)
				var next_angle = lerp_angle(held_gun.rotation, aim_angle, blend)
				held_gun.rotation = next_angle
				held_gun.global_position = hand_position - held_gun.grip_local.rotated(next_angle)
				held_gun.linear_velocity = parts[6].linear_velocity
				held_gun.angular_velocity = 0.0
				held_gun.set_deferred("lock_rotation", true)
				var lower = clampf(wrapf(aim_angle - PI/2.0, -PI, PI), -2.15, 2.15)
				var upper = clampf(lower * 0.56, -1.35, 1.35)
				if act == "recoil" and act_span > 0.0:
					var recoil_phase = 1.0 - act_time / act_span
					var recoil = sin(recoil_phase * PI) * 0.34 * (-1.0 if cos(aim_angle) >= 0 else 1.0)
					upper += recoil * 0.45
					lower += recoil
				_torque_towards_soft(parts[5], upper, 1.0)
				_torque_towards_soft(parts[6], lower, 1.15)
				if parts.size() > 4 and is_part_attached(3) and is_part_attached(4):
					_torque_towards_soft(parts[3], clampf(upper * 0.85, -1.2, 1.2), 0.9)
					_torque_towards_soft(parts[4], clampf(lower * 0.9, -1.7, 1.7), 0.9)
				return
		var face = hold_face()
		var u = -0.45 * face
		var f = -0.85 * face
		if act == "recoil" and act_span > 0.0:
			var recoil_phase = 1.0 - act_time / act_span
			var recoil = sin(recoil_phase * PI) * 0.35 * -face
			u += recoil * 0.5
			f += recoil
		_torque_towards(parts[5], u, 1.0)
		_torque_towards(parts[6], f, 1.0)
		return

	var face = hold_face()
	if act in ["slash", "slam", "thrust"] and absf(act_dir.x) > 0.05:
		face = signf(act_dir.x)
	elif aim_point != Vector2.INF and parts.size() > 1:
		var dx = aim_point.x - parts[1].global_position.x
		if absf(dx) > 16.0: face = signf(dx)

	var p = 0.0 if act_span <= 0.0 else clampf(1.0 - act_time / act_span, 0.0, 1.0)
	var is_two_handed = held_gun.kind in ["hammer", "mace", "katana", "scythe", "halberd", "axe", "spear", "bat"]
	
	var u = -0.45 * face
	var f = -0.85 * face
	var wrist_rot = 0.80
	var boost = 1.0
	var torso_target = 0.0
	var torso_boost = 1.5
	var head_target = 0.0
	var off_u = -0.35 * face if is_two_handed else 0.30 * face
	var off_f = -0.75 * face if is_two_handed else 0.75 * face
	var off_boost = 1.2 if is_two_handed else 1.0

	if act == "slash":
		boost = 3.2
		if p < 0.28:
			# Phase 1: Snappy wind-up (Замах) — 0.07 с, закручивание корпуса и занос клинка
			var t = p / 0.28
			var ease_in = t * t * (3.0 - 2.0 * t)
			u = lerp(-0.45, -2.25, ease_in) * face
			f = lerp(-0.85, -2.55, ease_in) * face
			wrist_rot = lerp(0.80, -0.70, ease_in)
			torso_target = -0.45 * face * ease_in
			torso_boost = 3.6
			head_target = 0.16 * face
			if is_two_handed:
				off_u = lerp(-0.35, -2.0, ease_in) * face
				off_f = lerp(-0.75, -2.3, ease_in) * face
				off_boost = 2.8
			else:
				off_u = lerp(0.30, 0.55, ease_in) * face
				off_f = lerp(0.75, 1.10, ease_in) * face
				off_boost = 1.8
		elif p < 0.60:
			# Phase 2: Explosive forward slash (Удар) — разгон и рассечение
			var t = (p - 0.28) / 0.32
			var strike_ease = sin(t * PI * 0.5)
			u = lerp(-2.25, 0.90, strike_ease) * face
			f = lerp(-2.55, 1.75, strike_ease) * face
			wrist_rot = lerp(-0.70, 0.65, strike_ease)
			torso_target = lerp(-0.45, 0.60, strike_ease) * face
			torso_boost = 5.2
			boost = 4.6
			head_target = 0.22 * face
			if is_two_handed:
				off_u = lerp(-2.0, 0.75, strike_ease) * face
				off_f = lerp(-2.3, 1.50, strike_ease) * face
				off_boost = 3.8
			else:
				off_u = lerp(0.55, -0.70, strike_ease) * face
				off_f = lerp(1.10, -0.85, strike_ease) * face
				off_boost = 2.4
			if p >= 0.32 and not act_strike_fired:
				act_strike_fired = true
				_deliver_melee_strike()
		elif p < 0.80:
			# Phase 3: Follow-through (Доводка)
			var t = (p - 0.60) / 0.20
			u = lerp(0.90, 0.60, t) * face
			f = lerp(1.75, 1.35, t) * face
			wrist_rot = lerp(0.65, 0.75, t)
			torso_target = lerp(0.60, 0.25, t) * face
			torso_boost = 2.4
			if is_two_handed:
				off_u = lerp(0.75, 0.40, t) * face
				off_f = lerp(1.50, 1.00, t) * face
				off_boost = 2.2
			else:
				off_u = lerp(-0.70, -0.15, t) * face
				off_f = lerp(-0.85, 0.20, t) * face
				off_boost = 1.6
		else:
			# Phase 4: Recovery (Возврат в стойку)
			var t = (p - 0.80) / 0.20
			u = lerp(0.60, -0.45, t) * face
			f = lerp(1.35, -0.85, t) * face
			wrist_rot = 0.80
			torso_target = lerp(0.25, 0.0, t) * face
			torso_boost = 1.8
			if is_two_handed:
				off_u = lerp(0.40, -0.35, t) * face
				off_f = lerp(1.00, -0.75, t) * face
				off_boost = 1.5
			else:
				off_u = lerp(-0.15, 0.30, t) * face
				off_f = lerp(0.20, 0.75, t) * face
				off_boost = 1.4
	elif act == "slam":
		boost = 3.2
		if p < 0.30:
			# Phase 1: Heavy two-handed hoist above head
			var t = p / 0.30
			var ease_in = t * t * (3.0 - 2.0 * t)
			u = lerp(-0.45, -2.75, ease_in) * face
			f = lerp(-0.85, -2.95, ease_in) * face
			wrist_rot = lerp(0.80, -0.75, ease_in)
			torso_target = -0.65 * face * ease_in
			torso_boost = 3.8
			head_target = -0.15 * face
			off_u = lerp(-0.35, -2.60, ease_in) * face
			off_f = lerp(-0.75, -2.80, ease_in) * face
			off_boost = 3.4
		elif p < 0.65:
			# Phase 2: Crushing downward slam
			var t = (p - 0.30) / 0.35
			var strike_ease = t * t * (3.0 - 2.0 * t)
			u = lerp(-2.75, 0.95, strike_ease) * face
			f = lerp(-2.95, 1.80, strike_ease) * face
			wrist_rot = lerp(-0.75, 0.55, strike_ease)
			torso_target = lerp(-0.65, 0.80, strike_ease) * face
			torso_boost = 5.5
			boost = 5.0
			head_target = 0.25 * face
			off_u = lerp(-2.60, 0.85, strike_ease) * face
			off_f = lerp(-2.80, 1.60, strike_ease) * face
			off_boost = 4.4
			if p >= 0.34 and not act_strike_fired:
				act_strike_fired = true
				_deliver_melee_strike()
		elif p < 0.82:
			# Phase 3: Impact rebound
			var t = (p - 0.65) / 0.17
			u = lerp(0.95, 0.70, t) * face
			f = lerp(1.80, 1.45, t) * face
			wrist_rot = lerp(0.55, 0.75, t)
			torso_target = lerp(0.80, 0.35, t) * face
			torso_boost = 2.4
			off_u = lerp(0.85, 0.55, t) * face
			off_f = lerp(1.60, 1.25, t) * face
			off_boost = 2.2
		else:
			# Phase 4: Recovery
			var t = (p - 0.82) / 0.18
			u = lerp(0.70, -0.45, t) * face
			f = lerp(1.45, -0.85, t) * face
			wrist_rot = 0.80
			torso_target = lerp(0.35, 0.0, t) * face
			torso_boost = 1.8
			off_u = lerp(0.55, -0.35, t) * face
			off_f = lerp(1.25, -0.75, t) * face
			off_boost = 1.5
	elif act == "thrust":
		boost = 2.8
		if p < 0.26:
			# Phase 1: Draw spear back along ribs
			var t = p / 0.26
			var ease_in = t * t * (3.0 - 2.0 * t)
			u = lerp(-0.45, -1.25, ease_in) * face
			f = lerp(-0.85, -0.10, ease_in) * face
			wrist_rot = lerp(0.80, 0.25, ease_in)
			torso_target = -0.35 * face * ease_in
			torso_boost = 3.0
			head_target = 0.12 * face
			off_u = lerp(-0.35, 0.45, ease_in) * face
			off_f = lerp(-0.75, 0.15, ease_in) * face
			off_boost = 2.4
		elif p < 0.58:
			# Phase 2: Lightning piercing thrust
			var t = (p - 0.26) / 0.32
			var strike_ease = sin(t * PI * 0.5)
			u = lerp(-1.25, 0.35, strike_ease) * face
			f = lerp(-0.10, 0.28, strike_ease) * face
			wrist_rot = lerp(0.25, 0.20, strike_ease)
			torso_target = lerp(-0.35, 0.52, strike_ease) * face
			torso_boost = 4.5
			boost = 4.0
			head_target = 0.18 * face
			off_u = lerp(0.45, 0.68, strike_ease) * face
			off_f = lerp(0.15, 0.35, strike_ease) * face
			off_boost = 3.0
			if p >= 0.30 and not act_strike_fired:
				act_strike_fired = true
				_deliver_melee_strike()
		elif p < 0.78:
			# Phase 3: Peak extension
			var t = (p - 0.58) / 0.20
			u = lerp(0.35, 0.15, t) * face
			f = lerp(0.28, 0.05, t) * face
			wrist_rot = 0.20
			torso_target = lerp(0.52, 0.25, t) * face
			torso_boost = 2.2
			off_u = lerp(0.68, 0.50, t) * face
			off_f = lerp(0.35, 0.10, t) * face
			off_boost = 2.0
		else:
			# Phase 4: Retract to guard
			var t = (p - 0.78) / 0.22
			u = lerp(0.15, -0.45, t) * face
			f = lerp(0.05, -0.85, t) * face
			wrist_rot = lerp(0.20, 0.80, t)
			torso_target = lerp(0.25, 0.0, t) * face
			torso_boost = 1.8
			off_u = lerp(0.50, -0.35 if is_two_handed else 0.30, t) * face
			off_f = lerp(0.10, -0.75 if is_two_handed else 0.75, t) * face
			off_boost = 1.5
	elif act == "recoil":
		boost = 1.8
		if p < 0.30:
			var t = p / 0.30
			u = lerp(-0.45, -1.05, t) * face
			f = lerp(-0.85, -1.55, t) * face
			torso_target = -0.20 * face * t
			torso_boost = 2.0
		else:
			var t = (p - 0.30) / 0.70
			u = lerp(-1.05, -0.45, t) * face
			f = lerp(-1.55, -0.85, t) * face
			torso_target = lerp(-0.20, 0.0, t) * face
			torso_boost = 1.5
	else:
		# Alert combat ready guard tracking target
		if aim_point != Vector2.INF and parts.size() > 1:
			var to_aim = aim_point - parts[1].global_position
			var aim_ang = to_aim.angle()
			var rel_ang = wrapf(aim_ang - (-PI / 2.0 * face), -PI, PI)
			var aim_bias = clampf(rel_ang * 0.28, -0.45, 0.45)
			u += aim_bias * face
			f += aim_bias * 0.75 * face
			wrist_rot += aim_bias * 0.35
			head_target = clampf(rel_ang * 0.35, -0.4, 0.4) * face
			if is_two_handed:
				off_u += aim_bias * 0.9 * face
				off_f += aim_bias * 0.7 * face
			else:
				off_u += aim_bias * 0.3 * face

	_torque_towards(parts[5], u, boost)
	_torque_towards(parts[6], f, boost)
	if parts.size() > 1 and is_part_attached(1):
		_torque_towards(parts[1], torso_target, torso_boost)
	if parts.size() > 0 and is_part_attached(0):
		_torque_towards_soft(parts[0], head_target, 1.4)
	if parts.size() > 4 and is_part_attached(3) and is_part_attached(4):
		_torque_towards(parts[3], off_u, off_boost)
		_torque_towards(parts[4], off_f, off_boost)

	# Firm weapon attachment and realistic physical blade orientation
	var hand_pos = palm()
	var arm_dir = Vector2.DOWN.rotated(parts[6].rotation)
	var target_blade_ang = arm_dir.angle() - wrist_rot * face
	var blend = 1.0 - exp(-delta * 24.0)
	held_gun.rotation = lerp_angle(held_gun.rotation, target_blade_ang, blend)
	var target_pos = hand_pos - held_gun.grip_local.rotated(held_gun.rotation)
	if held_gun.global_position.distance_to(target_pos) > 4.0 or act != "":
		held_gun.global_position = target_pos
	# The blade follows the hand. Adding a synthetic swing velocity here
	# injects momentum through the grip joint and launches the wielder.
	held_gun.linear_velocity = parts[6].linear_velocity
	held_gun.angular_velocity = wrapf(target_blade_ang - held_gun.rotation, -PI, PI) * 16.0
	held_gun.set_deferred("lock_rotation", true)

func _deliver_melee_strike() -> void:
	if not is_instance_valid(held_gun) or not is_instance_valid(game): return
	var face = hold_face()
	if absf(act_dir.x) > 0.05: face = signf(act_dir.x)
	var spin = float(act_spec.get("spin", 170.0))
	var shove = float(act_spec.get("shove", 180.0))
	var hit_dmg = float(act_spec.get("hit", 36.0))
	held_gun.payload = hit_dmg
	held_gun.impact_cooldown = 0
	
	game.play_sound("whoosh", 0.38)
	var reach = maxf(85.0, (held_gun.dimensions.x * 1.35 + 48.0)) * size_scale
	var hand_p = palm()
	var tip = hand_p + act_dir * reach
	
	# Attacker stays grounded and stable during the swing
	var swing_tangent = act_dir * 180.0 + act_dir.orthogonal() * face * 140.0
	held_gun.linear_velocity = parts[6].linear_velocity + swing_tangent
	held_gun.angular_velocity = wrapf(spin * face * 1.5, -12.0, 12.0)
	
	# Keep the attacker's feet firmly planted on the floor with ground adhesion
	parts[1].apply_central_force(Vector2(face * 140.0 * act_power, 420.0) * parts[1].mass)
	parts[6].apply_torque_impulse(450.0 * act_power * face)
	parts[5].apply_torque_impulse(280.0 * act_power * face)
	parts[1].apply_torque_impulse(120.0 * act_power * face)
	
	var col = LabArt.TEAL if held_gun.kind == "plasma_blade" else (Color(1.0, 0.35, 0.35) if held_gun.kind == "scythe" else (Color(1.0, 0.85, 0.3) if held_gun.kind in ["axe", "hammer"] else LabArt.TEXT))
	
	match act:
		"thrust":
			game.fx.beam(hand_p, tip + act_dir * 32.0)
			game.fx.emit_sparks(tip, 12, col, act_dir * 180.0)
			game.camera_shake = maxf(game.camera_shake, 1.8)
		"slam":
			var slam_dir = (act_dir * 0.45 + Vector2.DOWN * 0.89).normalized()
			var strike_a = slam_dir.angle()
			game.fx.slash_arc(hand_p, reach * 0.85, strike_a - 0.95, strike_a + 0.95, LabArt.AMBER)
			game.fx.emit_sparks(tip, 18, LabArt.AMBER, slam_dir * 180.0)
			game.play_sound("hit", 0.55)
			game.camera_shake = maxf(game.camera_shake, 2.8)
		"slash", _:
			var strike_a = act_dir.angle()
			game.fx.slash_arc(hand_p, reach * 0.85, strike_a - 1.05, strike_a + 1.05, col)
			game.fx.emit_sparks(tip, 14, col, act_dir * 160.0)
			game.camera_shake = maxf(game.camera_shake, 2.2)

	# Active hitbox check: point-to-segment distance along blade sweep
	var seg_a = hand_p
	var seg_b = tip
	var seg_v = seg_b - seg_a
	var seg_len2 = seg_v.length_squared()
	var hit_radius = 58.0 * size_scale
	var hit_count = 0
	var hit_robots: Dictionary = {}
	var hit_bodies: Dictionary = {}
	var own_left = held_gun_left
	
	var is_hammer = held_gun.kind == "hammer"
	var is_blunt = held_gun.kind in ["hammer", "bat", "mace"]
	
	var forward_x = act_dir.x if absf(act_dir.x) > 0.2 else face
	var lift_y = -0.38 if not (act == "slam") else -0.26
	var launch_normal = Vector2(forward_x, lift_y).normalized()
	
	# Weighted, physically natural launch velocity: 520 - 640 px/s for hammer, 220 - 420 px/s for blades
	var base_launch_speed = clampf(shove * 1.25 + 60.0, 160.0, 640.0)
	if act == "thrust":
		launch_normal = (act_dir + Vector2.UP * 0.18).normalized()
		base_launch_speed = clampf(shove * 1.1 + 70.0, 180.0, 560.0)
	
	for body in game.get_tree().get_nodes_in_group("bodies"):
		if not is_instance_valid(body) or body == held_gun or body == own_left or body.ragdoll == self or body.kind in game.EPHEMERAL or body.kind in game.FLUIDS or body.is_queued_for_deletion():
			continue
		var t_proj = clampf((body.global_position - seg_a).dot(seg_v) / maxf(1.0, seg_len2), 0.0, 1.0)
		var closest = seg_a + seg_v * t_proj
		var dist = body.global_position.distance_to(closest)
		var d_hand = body.global_position.distance_to(hand_p)
		var d_tip = body.global_position.distance_to(tip)
		var min_d = minf(dist, minf(d_hand, d_tip))
		
		var forward_bias = (body.global_position.x - parts[1].global_position.x) * face
		var to_body = body.global_position - hand_p
		# Полусфера вокруг направления удара: цель должна быть спереди от
		# замаха, а не просто "где-то рядом с ладонью". Замах вверх больше не
		# сносит всё, что лежит на полу, а удар за спину не проходит вовсе.
		var in_arc = to_body.length() <= 12.0 or act_dir.dot(to_body.normalized()) > -0.05
		if min_d <= hit_radius or (d_hand <= reach + 22.0 and in_arc and forward_bias > -20.0):
			var t_robot = body.ragdoll if body.is_attached_robot_part() else null
			if t_robot:
				if not hit_robots.has(t_robot):
					hit_robots[t_robot] = true
					hit_count += 1
					var r_mass = 0.0
					for p in t_robot.connected_parts():
						if is_instance_valid(p): r_mass += p.mass
					if r_mass <= 0.0: r_mass = 18.0
					var r_impulse = launch_normal * base_launch_speed * r_mass
					t_robot.apply_knockback(r_impulse, body.global_position, face * (1400.0 if is_blunt else 750.0))
					body.damage(hit_dmg, Vector2.ZERO)
					if is_hammer:
						game.camera_shake = maxf(game.camera_shake, 3.8)
						game.impact_flash = maxf(game.impact_flash, 0.25)
						game.fx.explosion(body.global_position, 38.0)
						game.fx.emit_sparks(body.global_position, 20, LabArt.AMBER, launch_normal * 260.0)
						game.play_sound("explosion", 0.22)
						game.play_sound("hit", 0.85)
					else:
						game.fx.emit_sparks(body.global_position, 14, col, launch_normal * 220.0)
			else:
				if not hit_bodies.has(body):
					hit_bodies[body] = true
					hit_count += 1
					var obj_mass = body.mass
					var obj_impulse = launch_normal * base_launch_speed * obj_mass
					body.damage(hit_dmg, obj_impulse)
					if not body.freeze:
						body.sleeping = false
						var speed_scale = clampf(sqrt(3.0 / maxf(0.8, obj_mass)), 0.6, 1.25)
						body.linear_velocity = launch_normal * base_launch_speed * speed_scale
						body.apply_torque_impulse(face * randf_range(120.0, 320.0) * obj_mass)
					if is_hammer:
						game.camera_shake = maxf(game.camera_shake, 3.4)
						game.fx.emit_sparks(body.global_position, 16, LabArt.AMBER, launch_normal * 240.0)
						game.play_sound("hit", 0.8)
					else:
						game.fx.emit_sparks(body.global_position, 12, col, launch_normal * 180.0)
	
	if hit_count > 0:
		if held_gun.kind == "torch":
			# Факел бьёт слабо, но поджигает всё, до чего дотянулся.
			# Шанс умножается на горючесть материала, поэтому прямому удару
			# факелом даём запас: по дереву и по роботу он поджигает всегда,
			# по металлу и стеклу по-прежнему не поджигает вовсе.
			for hb in hit_bodies: hb.ignite(2.5, 6.0)
			for hr in hit_robots:
				if hr.parts.size() > 1: hr.parts[1].ignite(2.5, 6.0)
			game.fx.emit_sparks(hand_p, 12, LabArt.AMBER, act_dir * 200.0)
		if not is_hammer:
			game.play_sound("hit", 0.55)
			game.camera_shake = maxf(game.camera_shake, 2.6)

func _torque_towards(body: RigidBody2D, desired: float, boost: float=1.0) -> void:
	var err=wrapf(desired-body.rotation,-PI,PI)
	body.apply_torque(clampf(err*14000.0*boost-body.angular_velocity*1400.0,-28000.0*boost,28000.0*boost)*body.mass)

func _torque_towards_soft(body: RigidBody2D, desired: float, boost: float=1.0) -> void:
	var err=wrapf(desired-body.rotation,-PI,PI)
	var torque=err*3600.0*boost-body.angular_velocity*1050.0
	body.apply_torque(clampf(torque,-6200.0*boost,6200.0*boost)*body.mass)

func start_act(kind: String, duration: float, dir: Vector2 = Vector2.RIGHT, power: float = 1.0, spec: Dictionary = {}) -> void:
	act=kind
	act_span=maxf(duration,0.08)
	act_time=act_span
	act_strike_fired=false
	act_dir=dir
	act_power=power
	act_spec=spec
	if is_instance_valid(held_gun):
		held_gun.angular_damp=2.0 if kind in ["slash","slam","thrust"] else 8.0
		held_gun.set_deferred("lock_rotation", (held_gun.kind in game.MELEE))

func play_slash(dir: Vector2, power: float, spec: Dictionary = {}) -> void:
	if parts.size()<7: return
	power=clampf(power,0.6,2.0)
	var face=hold_face()
	if absf(dir.x) > 0.05: face = signf(dir.x)
	var dur = clampf(float(spec.get("wait", 0.22)) * 0.95, 0.16, 0.34)
	start_act("slash", dur / (2.2 if overclock_timer > 0 else 1.0), dir, power, spec)
	parts[6].apply_torque_impulse(-750.0 * power * face)
	parts[5].apply_torque_impulse(-500.0 * power * face)
	parts[1].apply_torque_impulse(-220.0 * power * face)
	parts[6].apply_central_impulse(-dir * power * 35.0 + Vector2.UP * 45.0 * power)

func play_slam(dir: Vector2, power: float, spec: Dictionary = {}) -> void:
	if parts.size()<7: return
	power=clampf(power,0.6,2.2)
	var face=hold_face()
	if absf(dir.x) > 0.05: face = signf(dir.x)
	var dur = clampf(float(spec.get("wait", 0.34)) * 0.95, 0.22, 0.40)
	start_act("slam", dur / (2.2 if overclock_timer > 0 else 1.0), dir, power, spec)
	parts[6].apply_central_impulse(Vector2.UP * 65.0 * power - dir * 30.0 * power)
	parts[5].apply_central_impulse(Vector2.UP * 45.0 * power)
	parts[1].apply_torque_impulse(-320.0 * power * face)
	parts[6].apply_torque_impulse(-850.0 * power * face)

func play_thrust(dir: Vector2, power: float, spec: Dictionary = {}) -> void:
	if parts.size()<7: return
	power=clampf(power,0.6,1.9)
	var face=hold_face()
	if absf(dir.x) > 0.05: face = signf(dir.x)
	var dur = clampf(float(spec.get("wait", 0.25)) * 0.95, 0.18, 0.32)
	start_act("thrust", dur / (2.2 if overclock_timer > 0 else 1.0), dir, power, spec)
	parts[6].apply_central_impulse(-dir * power * 50.0)
	parts[1].apply_torque_impulse(-160.0 * power * face)

func play_recoil(dir: Vector2, kick: float) -> void:
	if parts.size()<7: return
	var power=clampf(kick/200.0,0.4,2.4)
	var face=hold_face()
	start_act("recoil",clampf(0.09+kick/900.0,0.09,0.24))
	parts[6].apply_central_impulse(-dir*power*24+Vector2(0,-12*power))
	parts[5].apply_central_impulse(-dir*power*13+Vector2(0,-6*power))
	parts[1].apply_central_impulse(-dir*power*8)
	parts[6].apply_torque_impulse(-face*power*150)
	parts[5].apply_torque_impulse(-face*power*75)

func drop_gun() -> void:
	if is_instance_valid(gun_joint):
		gun_joint.queue_free()
		gun_joint=null
	if is_instance_valid(held_gun):
		for part in parts:
			if is_instance_valid(part) and is_instance_valid(held_gun):
				held_gun.remove_collision_exception_with(part)
				part.remove_collision_exception_with(held_gun)
		held_gun.holder=null
		held_gun.angular_damp=2.2
		held_gun.set_deferred("lock_rotation", false)
		held_gun.gravity_scale=held_gun.gravity_factor if game.gravity else 0.0
		held_gun=null
	act=""
	act_time=0.0
	act_span=0.0

func drop_gun_left() -> void:
	if is_instance_valid(gun_joint_left):
		gun_joint_left.queue_free()
		gun_joint_left=null
	if is_instance_valid(held_gun_left):
		for part in parts:
			if is_instance_valid(part) and is_instance_valid(held_gun_left):
				held_gun_left.remove_collision_exception_with(part)
				part.remove_collision_exception_with(held_gun_left)
		held_gun_left.holder=null
		held_gun_left.angular_damp=2.2
		held_gun_left.set_deferred("lock_rotation", false)
		held_gun_left.gravity_scale=held_gun_left.gravity_factor if game.gravity else 0.0
		held_gun_left=null

func dismember_joint(idx: int, impact_impulse: Vector2 = Vector2.ZERO) -> void:
	if idx < 0 or idx >= joints.size(): return
	var joint = joints[idx]
	if not is_instance_valid(joint): return
	var spec: Dictionary = JOINT_SPECS[idx]
	var j_pos = parts[spec.a].global_transform * ((spec.offset - PART_OFFSETS[spec.a]) * size_scale)
	wake_for(0.3)
	joint.queue_free()
	joints[idx] = null
	var detached: Array[int] = []
	match idx:
		0: # Neck
			detached = [0]
			if not dead: die()
		1: # Waist
			detached = [2, 7, 8, 9, 10]
			if not dead: die()
		2: # Left shoulder
			detached = [3, 4]
			if is_instance_valid(held_gun_left): drop_gun_left()
		3: # Left elbow
			detached = [4]
			if is_instance_valid(held_gun_left): drop_gun_left()
		4: # Right shoulder
			detached = [5, 6]
			if is_instance_valid(held_gun): drop_gun()
		5: # Right elbow
			detached = [6]
			if is_instance_valid(held_gun): drop_gun()
		6: # Left hip
			detached = [7, 8]
		7: # Left knee
			detached = [8]
		8: # Right hip
			detached = [9, 10]
		9: # Right knee
			detached = [10]
	for p_idx in detached:
		if p_idx < parts.size() and is_instance_valid(parts[p_idx]):
			var limb = parts[p_idx]
			limb.can_sleep = true
			if limb.freeze: continue
			limb.sleeping = false
			limb.angular_velocity += randf_range(-10.0, 10.0)
			var push = impact_impulse * 0.4 if impact_impulse != Vector2.ZERO else Vector2(randf_range(-70, 70), randf_range(-140, -40))
			limb.apply_central_impulse(push)
	update_part_collisions()
	if is_instance_valid(game):
		game.fx.emit_sparks(j_pos, 18, LabArt.AMBER, Vector2.UP * 30.0)
		game.fx.emit_sparks(j_pos, 8, tint, Vector2.UP * 20.0)
		game.play_sound("hit", 0.4)
		game.play_sound("snap", 0.45)
		game.play_sound("metal", 0.3)

func revive() -> void:
	dead = false
	death_time = 0.0
	rest_time = 0.0
	wake_grace = 0.0
	corpse_settled = false
	health = max_health
	_reset_damage_state()
	acid_timer = 0.0
	nitro = false
	stun = 0.0
	repair_all_joints()
	for b in parts:
		if is_instance_valid(b):
			b.health = b.max_health
			b.freeze = false
			b.sleeping = false
			b.can_sleep = false
			b.linear_damp = 0.25
			b.angular_damp = 8.0 if b.kind == "head" else (4.5 if b.kind in ["torso", "pelvis"] else 2.2)
			b.apply_central_impulse(Vector2(0, -90))
			b.queue_redraw()
	for j in joints:
		if is_instance_valid(j):
			j.angular_limit_enabled = true
			j.softness = 0.04
	if is_instance_valid(game):
		game.fx.flash(parts[1].global_position, 36.0, LabArt.TEAL)
		game.fx.emit_sparks(parts[1].global_position, 24, LabArt.TEAL, Vector2.UP * 45)
		game.play_sound("revive", 0.45)
		game.notify(game.t("Робот реанимирован!","Robot revived!"))

func inject_acid() -> void:
	acid_timer = 4.5
	wake_for(5.0)
	if is_instance_valid(game):
		game.fx.emit_sparks(parts[1].global_position, 20, Color(0.3, 0.95, 0.2), Vector2.UP * 40)
		game.play_sound("pulse", 0.3)
		game.notify(game.t("Кислота разъедает системы!","Acid is corroding chassis!"))

func inject_nitro() -> void:
	nitro = true
	wake_for(5.0)
	if is_instance_valid(game):
		game.fx.emit_sparks(parts[1].global_position, 24, LabArt.AMBER, Vector2.UP * 40)
		game.play_sound("pulse", 0.3)
		game.notify(game.t("Ядро нестабильно (нитроглицерин)!","Core volatile (nitroglycerin)!"))

func inject_overclock() -> void:
	overclock_timer = 20.0
	wake_for(5.0)
	if is_instance_valid(game):
		game.fx.emit_sparks(parts[1].global_position, 30, Color(0.3, 0.85, 1.0), Vector2.UP * 50)
		game.play_sound("chip", 0.4)
		game.play_sound("switch_on", 0.3)
		game.notify(game.t("Оверклок активирован (суперскорость)!","Overclock activated!"))

func inject_freeze() -> void:
	for b in parts:
		if is_instance_valid(b):
			b.freeze = true
			b.linear_velocity = Vector2.ZERO
			b.angular_velocity = 0.0
			b.queue_redraw()
	if is_instance_valid(game):
		game.fx.emit_sparks(parts[1].global_position, 25, Color(0.65, 0.92, 1.0), Vector2.ZERO)
		game.play_sound("freeze", 0.45)
		game.notify(game.t("Робот заморожен!","Robot frozen!"))

func die() -> void:
	if dead: return
	dead=true
	active=false
	# Труп не доигрывает замах: иначе act остаётся выставленным навсегда и
	# стабилизация замаха продолжает дёргать мёртвое тело, не давая ему лечь.
	act=""
	act_time=0.0
	act_span=0.0
	health=0
	drop_gun()
	drop_gun_left()
	if is_instance_valid(game): game.play_sound("power_down", 0.42)
	death_time=0
	rest_time=0
	wake_grace=0
	corpse_settled=false
	for body in parts:
		body.health=0
		body.active=false
		body.constant_force=Vector2.ZERO
		body.constant_torque=0
		body.linear_damp=1.8
		body.angular_damp=5.0
		body.can_sleep=true
		if not body.freeze: body.sleeping=false
		body.queue_redraw()
	# Break the perfectly symmetric upright pose once the balance servos stop.
	# Frozen robots keep their pose; a moving robot keeps its existing fall.
	if not parts[1].freeze and parts[1].linear_velocity.length() < 50.0:
		parts[1].apply_central_impulse(Vector2(drive_direction * 25.0, 0) * parts[1].mass)
		parts[1].apply_torque_impulse(drive_direction * 180.0 * parts[1].mass)
	# Tight angular limits fight the floor solver when a collapsed ragdoll
	# is compressed. A dead robot keeps all limbs, but its joints go loose.
	for joint in joints:
		if is_instance_valid(joint):
			joint.angular_limit_enabled=false
			joint.softness=0.25

func restore() -> void:
	health=max_health
	_reset_damage_state()
	dead=false
	death_time=0
	rest_time=0
	wake_grace=0
	corpse_settled=false
	stun=0
	repair_all_joints()
	for b in parts:
		b.health=b.max_health
		# Repair also releases deliberate freezing and old saved frozen corpses.
		b.freeze=false
		b.linear_damp=0.25
		b.angular_damp=8.0 if b.kind == "head" else (4.5 if b.kind in ["torso", "pelvis"] else 2.2)
		b.sleeping=false
		b.can_sleep=false
		b.queue_redraw()
	for joint in joints:
		if is_instance_valid(joint):
			joint.angular_limit_enabled=true
			joint.softness=0.04

func _reset_damage_state() -> void:
	impact_guard = 0.0
	cut_guard = 0.0
	shock_guard = 0.0
	pending_impact = 0.0
	pending_impact_part = null
	corpse_supports.clear()
	acid_timer = 0.0
	nitro = false
	for body in parts:
		body.prior_velocity = Vector2.ZERO
		body.prior_angular_velocity = 0.0
		body.floor_contacts.clear()

func wake_for(seconds: float) -> void:
	if not dead: return
	wake_grace=maxf(wake_grace,seconds)
	rest_time=0
	corpse_settled=false
	corpse_supports.clear()
	for body in parts:
		if is_instance_valid(body) and not body.freeze: body.sleeping=false
