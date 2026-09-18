class_name LabBody
extends RigidBody2D

var kind = "crate"
var dimensions = Vector2(48,48)
var tint = LabArt.TEAL
var health = 100.0
var max_health = 100.0
var active = false
var highlighted = false
var ragdoll: Node2D
var game: Node2D
var serial = 0
var impact_cooldown = 0.0
var age = 0.0
var detonating = false
var prior_velocity = Vector2.ZERO
var prior_angular_velocity = 0.0
var floor_contacts: Array[Node2D] = []
var floor_height = 0.0
var floor_velocity = Vector2.ZERO
var balance = false
var gravity_factor = 1.0
var mechanism_cooldown = 0.0
var attached = false
var holder: Node2D
var source: LabBody
var payload = 0.0
var grip_local = Vector2.ZERO
var part_index: int = -1
# Стихии. burning — сколько секунд ещё горит, wet — насколько мокрое (мокрое
# не занимается и тушит само себя), charge — заряд 0..1, scorch — копоть,
# нужна только для отрисовки и не влияет на физику.
var burning = 0.0
var wet = 0.0
var charge = 0.0
var scorch = 0.0
var elem_cooldown = 0.0
var spark_cooldown = 0.0
var submerged = 0.0
# Машины (см. vehicle.gd). У кузова — колёса, шарниры подвески и передача
# (0 стоп, 1 вперёд, -1 назад); у колеса — ссылка на кузов и стиль рисования.
var vehicle: LabBody
var vehicle_style = ""
var wheels: Array = []
var vehicle_joints: Array = []
var gear = 0
var wrecked = false
var track_phase = 0.0
# Второе действие машины (клавиша V): своя перезарядка и время работы нитро.
# Не сохраняются — это доли секунды.
var ability_cooldown = 0.0
var boost = 0.0

func _ready() -> void:
	add_to_group("bodies")
	collision_layer = 2
	collision_mask = 3
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 8
	linear_damp = 0.25
	angular_damp = 2.2
	var material = PhysicsMaterial.new()
	material.friction = 0.7
	material.bounce = 0.08
	if kind=="bumper": material.bounce=0.95; material.friction=0.25
	if kind=="trampoline": material.bounce=0.72; material.friction=0.9
	if kind=="grenade": material.bounce=0.38; material.friction=0.45
	if kind in ["bounce","disc"]: material.bounce=0.94; material.friction=0.12
	if is_instance_valid(game) and game.TOY_PHYS.has(kind):
		var s=game.TOY_PHYS[kind]
		material.bounce=float(s.get("bounce",material.bounce))
		material.friction=float(s.get("friction",material.friction))
		linear_damp=float(s.get("damp",linear_damp))
		angular_damp=float(s.get("adamp",angular_damp))
	physics_material_override = material
	max_health=health
	if is_instance_valid(game) and kind in game.FLUIDS:
		# Лужа — это область, а не предмет: она ничего не толкает корпусом,
		# стоит там, где её поставили, и рисуется под остальными телами.
		collision_layer = 0
		collision_mask = 0
		contact_monitor = false
		freeze = true
		gravity_scale = 0.0
		gravity_factor = 0.0
		z_index = -2
		linear_damp = 0.0
		angular_damp = 0.0
	if kind in LabParts.KINDS:
		# Детали конструктора: уголок, рама и косынка — не прямоугольники.
		LabParts.add_shapes(self)
		body_entered.connect(_on_collision)
		queue_redraw()
		return
	if kind in LabVehicle.KINDS:
		# Кузов собран из нескольких выпуклых многоугольников: крыша, капот,
		# борта кузова пикапа — одним прямоугольником этого не описать.
		LabVehicle.add_hull_shapes(self)
		body_entered.connect(_on_collision)
		queue_redraw()
		return
	if LabGeometry.add_shapes(self,kind,dimensions):
		body_entered.connect(_on_collision)
		queue_redraw()
		return
	var collision = CollisionShape2D.new()
	var round_toy=is_instance_valid(game) and game.TOY_PHYS.has(kind) and game.TOY_PHYS[kind].get("circle",0)
	if kind in ["head","ball","slug","grenade","emp","chill","bounce","disc","flame","cannonball",LabVehicle.WHEEL] or round_toy:
		var shape = CircleShape2D.new()
		shape.radius = dimensions.x/2
		collision.shape = shape
	else:
		var shape = RectangleShape2D.new()
		shape.size = dimensions
		collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_collision)
	queue_redraw()

func _physics_process(delta: float) -> void:
	age += delta
	impact_cooldown = maxf(0, impact_cooldown-delta)
	mechanism_cooldown=maxf(0,mechanism_cooldown-delta)
	elem_cooldown=maxf(0,elem_cooldown-delta)
	spark_cooldown=maxf(0,spark_cooldown-delta)
	if is_instance_valid(game):
		if kind in game.FLUIDS:
			_run_fluid(delta)
			# Волна на поверхности анимируется в _draw, а обычный queue_redraw
			# до лужи не доходит — она никогда не active и не highlighted.
			queue_redraw()
			return
		_run_elements(delta)
		if kind in LabParts.KINDS:
			LabParts.tick(game,self,delta)
		if kind in LabVehicle.KINDS:
			LabVehicle.drive(game,self,delta)
			queue_redraw()
	if active and kind == "thruster" and not freeze:
		apply_central_force(Vector2.UP.rotated(rotation)*mass*2100)
		if Engine.get_physics_frames()%3 == 0 and is_instance_valid(game):
			game.fx.emit_sparks(global_position+Vector2.DOWN.rotated(rotation)*27, 2, LabArt.AMBER, Vector2.DOWN.rotated(rotation)*160)
	if active and kind in ["barrel","mine","sticky"] and not detonating:
		damage(150,Vector2.ZERO)
	if active and kind=="grenade" and not detonating and mechanism_cooldown<=0:
		damage(200,Vector2.ZERO)
		return
	if active and not freeze:
		match kind:
			"magnet": _magnetize()
			"fan": _blow()
			"coil": _discharge()
			"wheel": apply_torque(19000.0*mass)
			"turret": _turret()
			"drone": _drone()
			"chainsaw": _chainsaw()
			"battery":
				# Источник тока: пока включена, держит на себе полный заряд,
				# а дальше он расходится по проводникам и связям.
				charge = 1.0
				if mechanism_cooldown<=0:
					mechanism_cooldown=0.22
					game.fx.emit_sparks(global_position+Vector2(0,-dimensions.y*0.5),2,Color("9fe8ff"))
			"firework":
				apply_central_force(Vector2.UP.rotated(rotation)*mass*2600)
				if Engine.get_physics_frames()%2==0:
					game.fx.emit_sparks(global_position+Vector2.DOWN.rotated(rotation)*22,2,LabArt.AMBER,Vector2.DOWN.rotated(rotation)*220)
				if age>1.5:
					_burst_firework()
					return
			"c4":
				active = false
				detonate()
				return
	if kind == "laser_cutter" and active and not freeze and is_instance_valid(game):
		var dir = Vector2.RIGHT.rotated(rotation)
		var start = global_position + dir * (dimensions.x * 0.52)
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(start, start + dir * 650.0)
		query.exclude = [get_rid()]
		var hit = space_state.intersect_ray(query)
		var end = start + dir * 650.0
		if not hit.is_empty():
			end = hit.position
			var col = hit.collider
			if col is LabBody and col != self:
				col.damage(delta * 80.0, dir * 25.0)
				if col.ragdoll != null and randf() < delta * 0.5:
					col.ragdoll.dismember_joint(randi() % 10, dir * 50.0)
			game.fx.emit_sparks(end, 3, Color(1.0, 0.4, 0.2), -dir * 50.0)
		game.fx.beam(start, end)
	if kind == "singularity" and active and not freeze and is_instance_valid(game):
		var torn: Dictionary={}
		for other in get_tree().get_nodes_in_group("bodies"):
			if other == self or not is_instance_valid(other): continue
			var offset = global_position - other.global_position
			var dist = offset.length()
			if dist > 6.0 and dist < 650.0:
				var pull_dir = offset.normalized()
				var tangent = Vector2(-pull_dir.y, pull_dir.x)
				var force_mag = clampf(14000.0 / (dist * 0.08 + 1.0), 200.0, 24000.0)
				# Тянуть надо каждую пластину — у каждой своя масса. А грызть
				# робота — один раз за такт, иначе урон умножается на 11.
				other.apply_central_force((pull_dir * force_mag + tangent * 500.0) * other.mass)
				if dist < 45.0:
					if other.is_attached_robot_part():
						if torn.has(other.ragdoll): continue
						torn[other.ragdoll]=true
					other.damage(delta * 90.0, pull_dir * 40.0)
					if other.is_attached_robot_part() and randf() < delta * 0.5:
						other.ragdoll.dismember_joint(randi() % 10, pull_dir * 60.0)
		if int(age * 20) % 5 == 0:
			game.fx.rings.append({"p": global_position, "r": 50.0 + sin(age * 8.0) * 20.0, "life": 0.25, "max_life": 0.25, "color": Color(0.7, 0.2, 1.0)})
			game.fx.emit_sparks(global_position, 4, Color(0.6, 0.2, 1.0))
		if age > 7.0:
			game.explode(global_position, 340, 2.5)
			game.call_deferred("remove_entity", self)
			return
	if active and not freeze and is_instance_valid(game) and game.TOY_PHYS.has(kind) and game.TOY_PHYS[kind].has("mode"):
		_run_machine(str(game.TOY_PHYS[kind].mode))
	if kind=="drone" and is_instance_valid(game):
		var g=0.16 if active and health>0 else (1.15 if health<=0 else 0.85)
		gravity_scale=g if game.gravity else 0.0
	if kind == "mine" and age > 1.0:
		for other in get_colliding_bodies():
			if other is LabBody and other.ragdoll != null:
				damage(200,Vector2.ZERO)
	if kind=="slug" and age>1.15 and is_instance_valid(game):
		game.call_deferred("remove_entity",self)
		return
	if kind=="nail" and age>12 and is_instance_valid(game):
		game.call_deferred("remove_entity",self)
		return
	if kind=="emp":
		_emp_seek()
		if age>1.4 and is_instance_valid(game):
			game.call_deferred("remove_entity",self)
			return
	if kind=="flame" and age>0.34 and is_instance_valid(game):
		game.call_deferred("remove_entity",self)
		return
	if kind in ["bounce","disc"] and age>2.1 and is_instance_valid(game):
		game.call_deferred("remove_entity",self)
		return
	if kind=="rocket" and age>2.0 and is_instance_valid(game):
		_rocket_burst()
		return
	if kind in ["chill","cannonball","tether"] and age>2.2 and is_instance_valid(game):
		game.call_deferred("remove_entity",self)
		return
	if kind=="disc":
		apply_torque(12000)
	if is_instance_valid(holder) and holder is LabRobot and holder.parts.size()>6 and not freeze:
		# Определяем какая рука держит это оружие
		var is_left = (holder.held_gun_left == self)
		var hand_idx = 4 if is_left else 6
		var busy=holder.act in ["slash", "slam", "thrust", "recoil"]
		if busy and not is_left:
			lock_rotation=false
		else:
			var away=signf(global_position.x-holder.parts[1].global_position.x)
			if away==0: away=1.0
			var desired=Vector2(away,0.18).angle()
			if kind=="grenade" or kind=="scythe":
				desired=0.0
			if is_left:
				desired=Vector2(-away,0.18).angle()
			lock_rotation=true
			rotation=lerp_angle(rotation,desired,0.45)
			angular_velocity=0
		var hand=holder.parts[hand_idx]
		var palm=hand.global_position+Vector2(0,hand.dimensions.y*0.45).rotated(hand.rotation)
		var to_palm=palm-(global_position+grip_local.rotated(rotation))
		if to_palm.length()>2.0:
			apply_central_force(to_palm*mass*70.0)
	prior_velocity = linear_velocity
	prior_angular_velocity = angular_velocity
	if linear_velocity.length() > 3000: linear_velocity = linear_velocity.limit_length(3000)
	if global_position.y > 1800 or global_position.y < -1600 or absf(global_position.x) > 5000:
		if is_instance_valid(game): game.remove_entity(self)
	if active or highlighted: queue_redraw()

func is_attached_robot_part() -> bool:
	return is_instance_valid(ragdoll) and ragdoll.is_part_attached(part_index)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not is_instance_valid(ragdoll): return
	floor_contacts.clear()
	floor_height = 0.0
	floor_velocity = Vector2.ZERO
	var floor_count = 0
	for i in range(state.get_contact_count()):
		var other = state.get_contact_collider_object(i)
		if not is_instance_valid(other) or not other is Node2D: continue
		if other is LabBody and (other.ragdoll == ragdoll or other.holder == ragdoll): continue
		var normal = state.get_contact_local_normal(i)
		var point = state.get_contact_local_position(i)
		var other_velocity = state.get_contact_collider_velocity_at_position(i)
		if normal.dot(Vector2.UP) > 0.55:
			if other not in floor_contacts: floor_contacts.append(other)
			floor_height += point.y
			floor_velocity += other_velocity
			floor_count += 1
		if ragdoll.dead or age < 0.12 or freeze or not ragdoll.is_part_attached(part_index): continue
		# Projectiles and melee weapons already deal their own calibrated hit.
		# Counting their closing speed again would add a second, lethal impact.
		if other is LabBody and is_instance_valid(game):
			if other.kind in game.EPHEMERAL or other.kind in game.MELEE or is_instance_valid(other.holder): continue
		if is_instance_valid(game) and other == game.dragging and other is LabBody and game.can_hold(other.kind): continue
		# Closing velocity along the contact normal measures the impact; sliding
		# across a floor at high horizontal speed must not count as a hard fall.
		var offset = point - state.transform.origin
		var velocity = prior_velocity + Vector2(-offset.y, offset.x) * prior_angular_velocity
		if other is LabBody and not other.freeze:
			var other_offset = state.get_contact_collider_position(i) - other.global_position
			other_velocity = other.prior_velocity + Vector2(-other_offset.y, other_offset.x) * other.prior_angular_velocity
		if ragdoll.act != "" and other is StaticBody2D:
			# Ignore the arm's own swing, but retain the speed of a falling robot.
			velocity = Vector2.ZERO
			var total_mass = 0.0
			for body in ragdoll.parts:
				if ragdoll.is_part_attached(body.part_index):
					velocity += body.prior_velocity * body.mass
					total_mass += body.mass
			velocity /= maxf(total_mass, 0.01)
		var speed = maxf(0.0, -(velocity - other_velocity).dot(normal))
		if speed > 290.0: ragdoll.queue_impact(self, (speed - 250.0) * 0.09)
	if floor_count > 0:
		floor_height /= floor_count
		floor_velocity /= floor_count

func _on_collision(other: Node) -> void:
	if kind=="c_spikes" and is_instance_valid(game):
		LabParts.on_contact(game,self,other)
	if kind.begins_with("syringe_"):
		if payload > 0: return
		if other is LabBody and other.is_attached_robot_part():
			payload = 1.0
			var bot = other.ragdoll
			match kind:
				"syringe_life":
					bot.revive()
					if is_instance_valid(game): game.notify(game.t("Введена реанимация: робот оживлён!","Revive serum injected: robot resurrected!"))
				"syringe_acid":
					bot.inject_acid()
					if is_instance_valid(game): game.notify(game.t("Введена кислота: металл разъедается!","Acid injected: chassis liquefying!"))
				"syringe_nitro":
					bot.inject_nitro()
					if is_instance_valid(game): game.notify(game.t("Введён нитро: ядро нестабильно!","Nitro injected: chassis explosive!"))
				"syringe_overclock":
					bot.inject_overclock()
					if is_instance_valid(game): game.notify(game.t("Оверклок: скорость сервоприводов 2.5x!","Overclock injected: 2.5x servo speed!"))
				"syringe_freeze":
					bot.inject_freeze()
					if is_instance_valid(game): game.notify(game.t("Криогенная заморозка!","Cryo freeze injected!"))
			if is_instance_valid(game):
				var col = Color("4ade80") if kind == "syringe_acid" else (LabArt.AMBER if kind == "syringe_nitro" else LabArt.TEAL)
				game.fx.flash(global_position, 22.0, col)
				game.fx.emit_sparks(global_position, 14, col)
				game.play_sound("pulse", 0.45)
			queue_redraw()
		return
	if kind == "c4":
		if attached or age < 0.05: return
		if other is LabBody and is_instance_valid(game) and other.kind not in game.EPHEMERAL:
			attached = true
			var joint = PinJoint2D.new()
			joint.position = global_position
			joint.node_a = get_path()
			joint.node_b = other.get_path()
			game.world.add_child(joint)
			game.play_sound("click", 0.4)
		return
	if kind=="emp":
		if age<0.05: return
		_emp_burst()
		return
	if kind=="rocket":
		if age<0.05: return
		_rocket_burst()
		return
	if kind=="chill":
		if age<0.04: return
		if other is LabBody and is_instance_valid(game) and other.kind not in game.EPHEMERAL:
			_freeze_body(other)
			other.damage(payload if payload>0 else 6.0,linear_velocity.normalized()*other.mass*30)
		if is_instance_valid(game): game.call_deferred("remove_entity",self)
		return
	if kind in ["flame","foam"] and other is LabBody and is_instance_valid(game) and other.kind in game.EPHEMERAL:
		# Огнемёт и огнетушитель выпускают струю из одной точки: языки пламени
		# и хлопья пены сталкивались друг с другом и гасли в первом же кадре,
		# не долетая до цели.
		return
	if kind=="flame":
		if other is LabBody and is_instance_valid(game) and other.kind not in game.EPHEMERAL:
			other.damage(payload if payload>0 else 7.0,linear_velocity.normalized()*other.mass*25)
			other.ignite(1.6,6.0)
		if is_instance_valid(game): game.call_deferred("remove_entity",self)
		return
	if kind=="foam":
		if other is LabBody and is_instance_valid(game) and other.kind not in game.EPHEMERAL:
			other.douse(0.9)
		if is_instance_valid(game):
			game.fx.emit_sparks(global_position,3,Color("dfeef5"))
			game.call_deferred("remove_entity",self)
		return
	if kind in ["bounce","disc","cannonball"]:
		if age<0.04 or impact_cooldown>0: return
		if other is LabBody and is_instance_valid(game) and other.kind not in game.EPHEMERAL:
			impact_cooldown=0.08
			other.damage(payload if payload>0 else 16.0,linear_velocity.normalized()*maxf(1.0,other.mass)*80)
			if kind=="cannonball":
				game.call_deferred("remove_entity",self)
			else:
				health-=1
				if health<=0: game.call_deferred("remove_entity",self)
		return
	if kind=="tether":
		if age<0.03 or attached: return
		if other is LabBody and is_instance_valid(game) and other.kind not in game.EPHEMERAL and is_instance_valid(source):
			attached=true
			game.make_link(source,other)
			linear_damp=5
			game.fx.emit_sparks(global_position,8,LabArt.TEAL)
			game.call_deferred("remove_entity",self)
		return
	if kind=="slug":
		if age<0.04: return
		if other is LabBody and is_instance_valid(game) and other.kind not in game.EPHEMERAL and other!=self:
			var push=linear_velocity.normalized()*maxf(1.0,other.mass)*70
			other.damage(payload if payload>0 else 18.0,push)
		if is_instance_valid(game): game.call_deferred("remove_entity",self)
		return
	if kind=="nail":
		if age<0.03 or attached: return
		if other is LabBody and is_instance_valid(game) and other.kind not in game.EPHEMERAL and other!=self:
			attached=true
			var push=linear_velocity.normalized()*maxf(1.0,other.mass)*40
			other.damage(payload if payload>0 else 10.0,push)
			game.make_link(self,other)
			linear_damp=4.5
			angular_damp=9.0
			linear_velocity*=0.12
			game.fx.emit_sparks(global_position,5,LabArt.TEAL)
			game.play_sound("hit",0.18)
		elif not other is LabBody:
			attached=true
			linear_damp=6.0
			angular_damp=10.0
			linear_velocity*=0.15
		return
	if is_instance_valid(game) and kind in game.MELEE:
		# Если оружие в руках робота — урон наносит _deliver_melee_strike робота,
		# а не физическая коллизия. Иначе два удара сразу и всё разлетается.
		if is_instance_valid(holder) and holder is LabRobot:
			return
		if age<0.08 or impact_cooldown>0: return
		# Клинок, который игрок несёт захватом к руке робота, не режет его:
		# иначе вручение оружия ранило робота на каждом касании.
		if game.dragging==self and other is LabBody and is_instance_valid(other.ragdoll): return
		if other is LabBody and other!=self and other.kind not in game.EPHEMERAL:
			# Одна рана на робота за 0.2 с. Без этого груда из пятнадцати
			# клинков на полу убивала прошедшего по ней робота за полсекунды:
			# каждый клинок бил каждую из одиннадцати пластин.
			if other.is_attached_robot_part():
				if other.ragdoll.cut_guard>0.0: return
			# Режет то оружие, которое само движется. Раньше в счёт шла только
			# относительная скорость, поэтому лежащий на полу меч "рубил"
			# всякого, кто его задел: робот, прошедший по груде клинков,
			# умирал, не сделав ничего. Клинок, отброшенный пинком, набирает
			# собственную скорость и режет уже на следующем касании.
			var own_speed=prior_velocity.length()+absf(angular_velocity)*18
			var bonus=payload if mechanism_cooldown>0 else 0.0
			if own_speed<60 and bonus<=0: return
			var speed=prior_velocity.length()
			if other is RigidBody2D: speed=(prior_velocity-other.linear_velocity).length()
			speed+=absf(angular_velocity)*18
			if speed<50 and bonus<=0: return
			impact_cooldown=0.14
			var spec: Dictionary = game.MELEE_STATS.get(kind, {})
			var shove_stat = float(spec.get("shove", 180.0))
			var hit_base  = float(spec.get("hit", 30.0))
			var wtype     = str(spec.get("type", "slash"))
			var is_hammer = kind == "hammer"

			# Урон зависит от типа оружия:
			# slash  — режущее: баланс скорость+hit, скорость умеренно важна
			# crush  — дробящее: hit доминирует, скорость менее значима (молот всегда бьёт тяжело)
			# pierce — колющее: скорость решает, hit как минимальный порог
			# fast   — хлёсткое: лёгкий удар, почти только от скорости
			var hurt: float
			match wtype:
				"crush":
					hurt = hit_base * 0.65 + (speed - 35) * 0.05
				"pierce":
					hurt = hit_base * 0.30 + (speed - 35) * 0.11
				"fast":
					hurt = hit_base * 0.20 + (speed - 35) * 0.10
				_: # slash (default)
					hurt = hit_base * 0.45 + (speed - 35) * 0.08

			hurt = maxf(hurt, 0.0) + bonus + (hit_base * 0.35 if bonus > 0 else 0.0)

			var push_dir = linear_velocity.normalized() if linear_velocity.length()>12 else (other.global_position - global_position).normalized()
			if push_dir.length_squared() < 0.1: push_dir = Vector2.RIGHT.rotated(rotation)

			var launch_dir = (push_dir + Vector2.UP * 0.38).normalized()
			var launch_speed = clampf(speed * 0.75 + shove_stat * 0.85, 120.0, 620.0)
			if is_hammer: launch_speed = clampf(launch_speed * 1.15, 180.0, 660.0)
			var knock_impulse = launch_dir * launch_speed * other.mass

			if other.is_attached_robot_part():
				var r = other.ragdoll
				r.cut_guard = 0.2
				var r_mass = 0.0
				for p in r.connected_parts(): r_mass += p.mass
				if r_mass <= 0.0: r_mass = 18.0
				other.damage(hurt, Vector2.ZERO)
				r.apply_knockback(launch_dir * launch_speed * r_mass, other.global_position, signf(launch_dir.x) * (1400.0 if is_hammer else 750.0))
			else:
				other.damage(hurt, knock_impulse)
				if not other.freeze:
					other.sleeping = false
					other.linear_velocity = launch_dir * launch_speed / clampf(sqrt(other.mass / 3.0), 0.75, 2.0)
					other.apply_torque_impulse(signf(launch_dir.x) * randf_range(120.0, 320.0) * other.mass)

			if kind=="hook" and is_instance_valid(holder) and holder.parts.size()>1:
				var to_hand=holder.parts[6].global_position-other.global_position
				other.apply_central_impulse(to_hand.normalized()*other.mass*160)
			if bonus>0: payload*=0.35

			# Эффекты — разные по типу оружия
			match wtype:
				"crush":
					game.camera_shake = maxf(game.camera_shake, 2.5 + hit_base * 0.025)
					if is_hammer:
						game.camera_shake = maxf(game.camera_shake, 3.8)
						game.impact_flash = maxf(game.impact_flash, 0.25)
						game.fx.emit_sparks(global_position, 16, LabArt.AMBER, launch_dir * 260.0)
						game.play_sound("explosion", 0.22)
						game.play_sound("hit", 0.8)
						game.play_sound("metal", 0.55)
					else:
						game.fx.emit_sparks(global_position, 10, LabArt.AMBER, launch_dir * 200.0)
						game.play_sound("hit", clampf(0.3 + hurt * 0.007, 0.3, 0.7))
					game.play_sound("metal", clampf(0.2 + hurt * 0.005, 0.2, 0.5))
				"pierce":
					game.fx.emit_sparks(global_position, 5, LabArt.TEAL, launch_dir * 140.0)
					game.play_sound("hit", clampf(0.15 + hurt * 0.008, 0.15, 0.45))
				"fast":
					game.fx.emit_sparks(global_position, 4, LabArt.TEAL, launch_dir * 120.0)
					game.play_sound("hit", clampf(0.12 + hurt * 0.006, 0.12, 0.35))
				_: # slash
					game.fx.emit_sparks(global_position, 8, LabArt.TEAL if kind=="plasma_blade" else LabArt.AMBER, launch_dir * 180.0)
					game.play_sound("hit", clampf(0.18 + hurt * 0.008, 0.18, 0.55))
		return
	if kind=="grenade" and active and not detonating and impact_cooldown<=0 and age>0.2:
		var speed=prior_velocity.length()
		if other is RigidBody2D: speed=(prior_velocity-other.linear_velocity).length()
		if speed>170:
			damage(200,Vector2.ZERO)
			return
	if kind=="sticky" and not attached and age>0.25 and other is LabBody and other!=self:
		attached=true
		game.make_link(self,other)
		linear_damp=2.5
		angular_damp=5.0
		game.fx.emit_sparks(global_position,6,LabArt.RED)
	if kind=="spring_block" and age>0.2 and impact_cooldown<=0 and other is LabBody:
		impact_cooldown=0.28
		var n=Vector2.UP.rotated(rotation)
		other.apply_central_impulse(n*other.mass*480.0)
		if is_instance_valid(game):
			game.fx.emit_sparks(other.global_position,8,LabArt.TEAL,n*100)
			game.play_sound("boing",0.34)
	if kind=="slime" and other is LabBody and impact_cooldown<=0:
		impact_cooldown=0.2
		other.linear_velocity*=0.62
		other.angular_velocity*=0.62
	if kind=="boost_pad" and active and other is LabBody and impact_cooldown<=0:
		impact_cooldown=0.3
		var n=Vector2.UP.rotated(rotation)
		other.apply_central_impulse(n*other.mass*700.0)
		if is_instance_valid(game): game.play_sound("rocket",0.3)
	if kind=="crystal" and other is LabBody and prior_velocity.length()>240:
		damage(20,Vector2.ZERO)
	if kind=="trampoline" and age>0.25 and impact_cooldown<=0 and other is LabBody:
		impact_cooldown=0.35
		var launch=Vector2.UP.rotated(rotation)*other.mass*620.0
		other.apply_central_impulse(launch)
		game.fx.emit_sparks(other.global_position,10,LabArt.TEAL,Vector2.UP.rotated(rotation)*120)
		game.play_sound("boing",0.45)
	if freeze:
		return
	# Robot contacts are evaluated from the solver's contact normals. The
	# generic speed-length rule below is kept for ordinary props and vehicles.
	if is_instance_valid(ragdoll): return
	if age < 0.8 or impact_cooldown > 0: return
	var speed = prior_velocity.length()
	if other is RigidBody2D: speed = (prior_velocity-other.linear_velocity).length()
	var threshold = 290.0
	if kind == LabVehicle.WHEEL: return
	if kind in LabVehicle.KINDS:
		# Порог 290 писался для брошенных предметов. Машина сама ездит под 700
		# и приземляется с прыжков: по старому правилу легковушка теряла около
		# 30 прочности за каждое падение и разбивалась от собственной езды.
		# Урон дают только удары сильнее, чем машина может выдать себе сама.
		if other is LabBody and LabVehicle.root(other) == self: return
		threshold = 1000.0
	if speed > threshold:
		impact_cooldown = 0.18
		damage((speed-250)*0.09,Vector2.ZERO)
		if is_instance_valid(game):
			game.fx.emit_sparks(global_position,4,LabArt.AMBER)
			var vol=clampf(speed/1000,0.12,0.5)
			game.play_sound("hit",vol)
			# Материал слышно: металл и роботы звенят, дерево и ящики стучат.
			if is_instance_valid(ragdoll) or game.conductivity(kind)>0.0: game.play_sound("metal",vol*0.8)
			elif game.flammability(kind)>0.0: game.play_sound("wood",vol*0.7)

func damage(amount: float, impulse: Vector2) -> void:
	if detonating or is_queued_for_deletion(): return
	amount = maxf(0.0, amount)
	if is_instance_valid(ragdoll):
		if not ragdoll.is_part_attached(part_index):
			health = maxf(0.0, health - amount)
			if not freeze: apply_central_impulse(impulse)
			queue_redraw()
			return
		if ragdoll.dead:
			ragdoll.wake_for(3.0)
			if impulse.length() > 20.0:
				var target_impulse = impulse.limit_length(5500.0)
				ragdoll.apply_knockback(target_impulse)
			elif not freeze:
				apply_central_impulse(impulse)
			if ragdoll.nitro and amount >= 22.0:
				ragdoll.nitro = false
				if is_instance_valid(game) and ragdoll.parts.size() > 1:
					game.explode(ragdoll.parts[1].global_position, 280, 2.0)
			ragdoll.damage_joint(part_index, amount, impulse)
			return
		else:
			health = maxf(0, health - amount)
			if impulse.length() > 20.0:
				var target_impulse = impulse.limit_length(5500.0)
				ragdoll.apply_knockback(target_impulse)
			elif not freeze:
				apply_central_impulse(impulse)
			ragdoll.hurt(amount, part_index)
			queue_redraw()
			return
	if not freeze: apply_central_impulse(impulse)
	health = maxf(0,health-amount)
	queue_redraw()
	if health <= 0:
		if kind in LabVehicle.KINDS:
			LabVehicle.wreck(game,self)
			return
		if kind=="gas_can":
			_burst_gas()
			return
		if kind in ["barrel","mine","grenade"]:
			detonating = true
			var radius=190.0 if kind=="grenade" else 230.0
			var power=0.9 if kind=="grenade" else 1.0
			game.call_deferred("explode",global_position,radius,power)
			game.call_deferred("remove_entity",self)
		elif kind in ["crate","glass","crystal"]:
			detonating = true
			game.call_deferred("shatter",self)
		elif kind.begins_with("syringe_"):
			detonating = true
			if is_instance_valid(game):
				var col = Color("4ade80") if kind=="syringe_acid" else (LabArt.AMBER if kind=="syringe_nitro" else LabArt.TEAL)
				game.fx.explosion(global_position, 60.0)
				game.fx.emit_sparks(global_position, 20, col)
				game.play_sound("hit", 0.4)
				var injected: Dictionary = {}
				for other in game.get_tree().get_nodes_in_group("bodies"):
					if is_instance_valid(other) and other != self and other.is_attached_robot_part():
						if other.global_position.distance_to(global_position) < 130.0:
							if injected.has(other.ragdoll): continue
							injected[other.ragdoll] = true
							match kind:
								"syringe_life": other.ragdoll.revive()
								"syringe_acid": other.ragdoll.inject_acid()
								"syringe_nitro": other.ragdoll.inject_nitro()
								"syringe_overclock": other.ragdoll.inject_overclock()
								"syringe_freeze": other.ragdoll.inject_freeze()
				game.call_deferred("remove_entity", self)
		elif kind=="drone":
			active=false
			gravity_factor=1.15
			if is_instance_valid(game): gravity_scale=1.15 if game.gravity else 0.0
			linear_damp=0.5
			angular_damp=1.4

func _run_machine(mode: String) -> void:
	if not is_instance_valid(game): return
	match mode:
		"conveyor":
			var dir=Vector2.RIGHT.rotated(rotation)
			for other in get_colliding_bodies():
				if other is LabBody: other.apply_central_force(dir*other.mass*1100)
		"spin": apply_torque(14000.0)
		"updraft": _field_force(Vector2.UP,240,1600.0,false)
		"vacuum": _field_force(Vector2.ZERO,260,1400.0,true)
		"well": _field_force(Vector2.DOWN,240,1200.0,false)
		"hover":
			for other in get_colliding_bodies():
				if other is LabBody: other.apply_central_force(Vector2(0,-other.mass*980))
		"lift":
			for other in get_colliding_bodies():
				if other is LabBody: other.apply_central_force(Vector2.UP.rotated(rotation)*other.mass*1400)
		"boost":
			# The boost pad had no branch here at all, so the plate was inert:
			# it shoves whatever touches it along its own facing.
			for other in get_colliding_bodies():
				if other is LabBody: other.apply_central_force(Vector2.RIGHT.rotated(rotation)*other.mass*2200)
		"mag": _magnetize()
		"metro": apply_torque(sin(age*5.5)*9000.0)
		"mix":
			for other in get_tree().get_nodes_in_group("bodies"):
				if other==self or other.kind in game.EPHEMERAL: continue
				if global_position.distance_to(other.global_position)<160:
					other.apply_torque(2200.0)
		"slow":
			for other in get_tree().get_nodes_in_group("bodies"):
				if other==self or other.kind in game.EPHEMERAL: continue
				if global_position.distance_to(other.global_position)<170:
					other.apply_central_force(-other.linear_velocity*other.mass*7.0)
		"shake":
			if mechanism_cooldown<=0:
				mechanism_cooldown=0.1
				apply_central_impulse(Vector2(randf_range(-1,1),randf_range(-1,1))*mass*10)
		"pulse","speaker","pump","thump","scatter":
			if mechanism_cooldown>0: return
			mechanism_cooldown=0.75 if mode!="scatter" else 0.45
			var n=Vector2.UP.rotated(rotation)
			for other in get_tree().get_nodes_in_group("bodies"):
				if other==self or other.kind in game.EPHEMERAL: continue
				var offset=other.global_position-global_position
				var d=offset.length()
				if d<200 and d>8:
					var dir=n if mode in ["pump","thump"] else offset.normalized()
					if mode=="scatter": dir=Vector2(randf_range(-1,1),randf_range(-0.2,1)).normalized()
					other.apply_central_impulse(dir*(1.0-d/200.0)*other.mass*(280.0 if mode=="thump" else 160.0))
			game.fx.emit_sparks(global_position,8,LabArt.TEAL)
			game.play_sound("spawn",0.25)
		"chill","zap":
			if mechanism_cooldown>0: return
			mechanism_cooldown=0.55 if mode=="zap" else 0.8
			for other in get_colliding_bodies():
				if other is LabBody:
					other.linear_velocity*=0.15 if mode=="zap" else 0.35
					other.angular_velocity*=0.15 if mode=="zap" else 0.35
					if mode=="chill":
						other.linear_damp=maxf(other.linear_damp,3.0)
					game.fx.emit_sparks(other.global_position,4,Color("74cafa") if mode=="chill" else LabArt.AMBER)

func _field_force(direction: Vector2, radius: float, strength: float, pull: bool) -> void:
	for other in get_tree().get_nodes_in_group("bodies"):
		if other==self or other.kind in game.EPHEMERAL: continue
		var offset=other.global_position-global_position
		var d=offset.length()
		if d>12 and d<radius:
			var dir=-offset.normalized() if pull else (direction if direction.length()>0.1 else offset.normalized())
			other.apply_central_force(dir*(1.0-d/radius)*other.mass*strength)

func _magnetize() -> void:
	for other in get_tree().get_nodes_in_group("bodies"):
		if other==self or other.freeze or other.is_queued_for_deletion(): continue
		if other.kind in ["crate","plank","glass","balloon","debris"]: continue
		var offset=global_position-other.global_position
		var distance=offset.length()
		if distance>12 and distance<285:
			other.apply_central_force(offset.normalized()*(1.0-distance/285.0)*other.mass*1450)
	if mechanism_cooldown<=0:
		mechanism_cooldown=0.16
		game.fx.emit_sparks(global_position,2,LabArt.TEAL)

func _blow() -> void:
	var direction=Vector2.RIGHT.rotated(rotation)
	for other in get_tree().get_nodes_in_group("bodies"):
		if other==self or other.freeze or other.is_queued_for_deletion(): continue
		var offset=other.global_position-global_position
		var distance=offset.length()
		if distance<360 and distance>10 and direction.dot(offset.normalized())>0.68:
			other.apply_central_force(direction*(1.0-distance/360.0)*other.mass*2100)
	if mechanism_cooldown<=0:
		mechanism_cooldown=0.09
		game.fx.emit_sparks(global_position+direction*32,2,Color("9fe8ff"),direction*220)

func _turret() -> void:
	if not is_instance_valid(game): return
	var target: LabBody
	var best=420.0
	for other in get_tree().get_nodes_in_group("bodies"):
		if other==self or other.freeze or other.is_queued_for_deletion(): continue
		if other.kind in game.EPHEMERAL: continue
		var distance=global_position.distance_to(other.global_position)
		if distance>24 and distance<best:
			best=distance
			target=other
	if target==null: return
	var desired=(target.global_position-global_position).angle()
	var err=wrapf(desired-rotation,-PI,PI)
	apply_torque(clampf(err*12000.0-angular_velocity*850,-20000,20000)*mass)
	if mechanism_cooldown>0 or absf(err)>0.24: return
	mechanism_cooldown=0.36
	var dir=Vector2.RIGHT.rotated(rotation)
	var muzzle=global_position+dir*(dimensions.x*0.55)
	game.call_deferred("_spawn_slug",muzzle,dir*1500,18,self)
	apply_central_impulse(-dir*55)
	game.fx.emit_sparks(muzzle,5,LabArt.AMBER,dir*180)
	game.fx.beam(muzzle,muzzle+dir*28)
	game.play_sound("shot",0.22)

func _chainsaw() -> void:
	if health<=0 or not is_instance_valid(game) or mechanism_cooldown>0: return
	mechanism_cooldown=0.1
	var cut: Dictionary={}
	for other in get_colliding_bodies():
		if other is LabBody and other.kind not in game.EPHEMERAL:
			if is_instance_valid(holder) and other.ragdoll==holder: continue
			if other.is_attached_robot_part():
				if cut.has(other.ragdoll): continue
				cut[other.ragdoll]=true
			other.damage(9,Vector2.RIGHT.rotated(rotation)*other.mass*40)
			game.fx.emit_sparks(global_position,3,LabArt.AMBER)
	game.play_sound("hit",0.12)

func _rocket_burst() -> void:
	if detonating or not is_instance_valid(game): return
	detonating=true
	game.call_deferred("explode",global_position,125.0,0.55)
	game.call_deferred("remove_entity",self)

func _freeze_body(other: LabBody) -> void:
	var bodies=other.ragdoll.connected_parts(other.part_index) if is_instance_valid(other.ragdoll) else [other]
	for b in bodies:
		b.freeze=true
		b.linear_velocity=Vector2.ZERO
		b.angular_velocity=0
		b.queue_redraw()
	game.fx.emit_sparks(other.global_position,10,Color("74cafa"))
	game.play_sound("freeze",0.36)

func _drone() -> void:
	if health<=0 or not is_instance_valid(game): return
	if payload==0: payload=1
	if global_position.x>1750: payload=-1
	elif global_position.x<-750: payload=1
	var hover=390.0
	var yerr=hover-global_position.y
	apply_central_force(Vector2(payload*mass*540,clampf(yerr*60-linear_velocity.y*18,-1500,1700)*mass))
	var ang=wrapf(rotation,-PI,PI)
	apply_torque(clampf(-ang*4200-angular_velocity*480,-7000,7000)*mass)
	if Engine.get_physics_frames()%4==0:
		game.fx.emit_sparks(global_position+Vector2(-16,8),1,LabArt.TEAL,Vector2(0,90))
		game.fx.emit_sparks(global_position+Vector2(16,8),1,LabArt.TEAL,Vector2(0,90))

func _emp_seek() -> void:
	if detonating or not is_instance_valid(game): return
	var best: LabBody
	var dist=300.0
	for other in get_tree().get_nodes_in_group("bodies"):
		if other.kind!="drone" or other==self or other.is_queued_for_deletion(): continue
		var d=global_position.distance_to(other.global_position)
		if d<52:
			_emp_burst()
			return
		if d<dist: dist=d; best=other
	if best:
		var to=(best.global_position-global_position).normalized()
		linear_velocity=linear_velocity.lerp(to*1100,0.12)

func _emp_burst() -> void:
	if detonating or is_queued_for_deletion() or not is_instance_valid(game): return
	detonating=true
	var struck: Dictionary={}
	for other in get_tree().get_nodes_in_group("bodies"):
		if other==self or other.is_queued_for_deletion(): continue
		var offset=other.global_position-global_position
		var distance=offset.length()
		if distance>=100: continue
		# По роботу — один раз, иначе 16 урона превращались в 176 на 11 частей.
		if other.is_attached_robot_part():
			if struck.has(other.ragdoll): continue
			struck[other.ragdoll]=true
		var strength=1.0-distance/100.0
		var hurt=16.0*strength
		if other.kind=="drone": hurt=240.0*strength+50.0
		var dir=offset.normalized() if distance>1 else Vector2.UP
		other.damage(hurt,dir*other.mass*90*strength)
	game.fx.emit_sparks(global_position,18,LabArt.TEAL)
	game.fx.beam(global_position+Vector2(-18,0),global_position+Vector2(18,0))
	game.play_sound("pulse",0.28)
	game.play_sound("zap",0.34)
	game.call_deferred("remove_entity",self)

func _discharge() -> void:
	if mechanism_cooldown>0: return
	mechanism_cooldown=0.55
	var target: LabBody
	var best=250.0
	for other in get_tree().get_nodes_in_group("bodies"):
		if other==self or other.freeze or other.is_queued_for_deletion(): continue
		var distance=global_position.distance_to(other.global_position)
		if distance<best:
			best=distance
			target=other
	if target:
		var direction=(target.global_position-global_position).normalized()
		target.damage(9,direction*target.mass*170)
		game.fx.beam(global_position+Vector2.UP.rotated(rotation)*30,target.global_position)
		game.play_sound("zap",0.32)

# --------------------------------------------------------------------------
# Жидкости. Лужа не сталкивается ни с чем: каждый такт она смотрит, что в неё
# погрузилось, и работает силами — выталкивающей и вязкого сопротивления.
# --------------------------------------------------------------------------
func _run_fluid(delta: float) -> void:
	var half = dimensions*0.5
	var top = global_position.y-half.y
	var bottom = global_position.y+half.y
	var left = global_position.x-half.x
	var right = global_position.x+half.x
	var live = charge>0.05
	if kind=="oil_pool" and burning>0.0:
		burning = maxf(burning, 0.6)
		if elem_cooldown<=0.0:
			elem_cooldown = 0.25
			game.ignite_area(global_position, maxf(half.x,half.y)+40.0, 4.0)
	# Робот погружается одиннадцатью пластинами. Выталкивать надо каждую — у
	# каждой своя масса и свой объём, — а жечь кислотой и бить током один раз.
	var doll_seen: Dictionary={}
	for other in get_tree().get_nodes_in_group("bodies"):
		if other==self or not is_instance_valid(other) or other.is_queued_for_deletion(): continue
		if other.kind in game.FLUIDS: continue
		var oh = other.dimensions*0.5
		var op = other.global_position
		if op.x+oh.x<left or op.x-oh.x>right: continue
		if op.y-oh.y>bottom or op.y+oh.y<top: continue
		var deep = clampf((minf(op.y+oh.y,bottom)-maxf(op.y-oh.y,top))/maxf(other.dimensions.y,1.0),0.0,1.0)
		if deep<=0.0: continue
		var first = true
		if other.is_attached_robot_part():
			if doll_seen.has(other.ragdoll): first=false
			else: doll_seen[other.ragdoll]=true
		_fluid_push(other,deep,delta,live,first)

func _fluid_push(other: LabBody, deep: float, delta: float, live: bool, first: bool) -> void:
	if other.freeze:
		other.submerged = deep
		return
	# Всплеск при входе: считается один раз, пока тело не высохнет.
	# Снаряды в воде тоже тормозят, но всплеск за них не засчитывается: очередь
	# из минигана иначе писала бы прогресс в хранилище десятки раз в секунду.
	if first and other.submerged<=0.01 and other.prior_velocity.length()>230.0 and other.kind not in game.EPHEMERAL:
		game.fx.emit_sparks(Vector2(other.global_position.x,global_position.y-dimensions.y*0.5),10,_fluid_tint().lightened(0.25),Vector2.UP*180)
		game.play_sound("splash",clampf(other.prior_velocity.length()/1400.0,0.25,0.6))
		game.record("splash")
	other.submerged = deep
	var area = maxf(other.dimensions.x*other.dimensions.y,1.0)
	var body_density = maxf(other.mass/area,0.00001)
	# Архимед: подъём равен весу вытесненной жидкости. Отношение плотностей и
	# решает, всплывёт тело или утонет, — таблиц для этого не нужно.
	var lift = clampf(game.FLUID_DENSITY/body_density,0.0,3.4)
	var g = 900.0 if game.gravity else 0.0
	other.apply_central_force(Vector2(0,-g*other.mass*lift*deep))
	var drag = 0.9 if kind=="oil_pool" else 3.2
	other.apply_central_force(-other.linear_velocity*other.mass*drag*deep)
	other.apply_torque(-other.angular_velocity*other.mass*46.0*deep)
	if kind!="oil_pool":
		other.wet = maxf(other.wet,0.85*deep)
		if other.burning>0.0:
			other.burning = 0.0
			game.fx.emit_sparks(other.global_position,6,Color("cfe6ee"),Vector2.UP*70)
			game.play_sound("fizz",0.34)
	else:
		other.wet = 0.0
		if burning>0.0: other.ignite(0.5,4.0)
	if not first: return
	match kind:
		"acid_pool":
			other.damage(delta*26.0*deep,Vector2.ZERO)
			if int(age*14)%5==0: game.fx.emit_sparks(other.global_position,1,Color("4ade80"),Vector2.UP*40)
			if randf()<delta*2.5: game.play_sound("sizzle",0.22)
		"water_pool":
			# Вода проводит: заряженная лужа бьёт всех, кто в ней стоит.
			if live: other.electrify(charge*0.9)
			elif other.charge>0.12: electrify(other.charge)

func _fluid_tint() -> Color:
	match kind:
		"oil_pool": return Color("2b2f36")
		"acid_pool": return Color("4ade80")
		_: return Color("4aa8e0")

# --------------------------------------------------------------------------
# Огонь и ток на обычных телах.
# --------------------------------------------------------------------------
func _run_elements(delta: float) -> void:
	if submerged>0.0: submerged = maxf(0.0,submerged-delta*4.0)
	if wet>0.0: wet = maxf(0.0,wet-delta*0.28)
	if charge>0.0:
		var keep = game.conductivity(kind)
		charge = maxf(0.0,charge-delta*(0.5 if keep>0.0 else 2.6))
	if charge>0.1: _run_charge(delta)
	if burning>0.0: _run_fire(delta)

func _run_fire(delta: float) -> void:
	if freeze or wet>0.25:
		burning = 0.0
		game.fx.emit_sparks(global_position,4,Color("cfe6ee"),Vector2.UP*50)
		game.play_sound("fizz",0.3)
		queue_redraw()
		return
	burning -= delta
	scorch = minf(1.0,scorch+delta*0.5)
	var rate = 11.0*maxf(game.flammability(kind),0.3)
	# Горящая рука и горящая нога — это всё ещё один горящий робот: урон
	# начисляет только одна часть, иначе жар умножается на одиннадцать.
	if is_attached_robot_part():
		if not is_instance_valid(ragdoll.fire_source) or not ragdoll.fire_source.is_attached_robot_part() or ragdoll.fire_source.burning<=0.0: ragdoll.fire_source = self
		if ragdoll.fire_source==self: damage(delta*rate,Vector2.ZERO)
	else:
		damage(delta*rate,Vector2.ZERO)
	# Горячий воздух поднимает лёгкое: пламя чуть тянет тело вверх.
	apply_central_force(Vector2(0,-mass*90.0))
	# emit_sparks сам держит потолок в 550 частиц, а прямая вставка его обходит:
	# десяток горящих тел иначе забивает массив и роняет веб-сборку.
	if Engine.get_physics_frames()%3==0 and game.fx.particles.size()<520:
		var at = global_position+Vector2(randf_range(-dimensions.x,dimensions.x)*0.4,randf_range(-dimensions.y,dimensions.y)*0.4)
		game.fx.particles.append({"p":at,"v":Vector2(randf_range(-18,18),randf_range(-90,-40)),"life":randf_range(0.25,0.55),"max_life":0.55,"c":Color(1.0,randf_range(0.45,0.8),0.2),"s":randf_range(2.5,5.5),"gravity":-40.0,"glow":true,"smoke":false})
	if elem_cooldown<=0.0:
		elem_cooldown = 0.22
		# Треск пламени — изредка, чтобы горящая груда не гудела сплошным шумом.
		if randf()<0.3: game.play_sound("sizzle",0.12)
		if randf()<0.12: game.play_sound("flame",0.14)
		for other in get_colliding_bodies():
			if other is LabBody: other.ignite(0.7,4.5)
		var reach = maxf(dimensions.x,dimensions.y)*0.5+42.0
		for other in get_tree().get_nodes_in_group("bodies"):
			if other==self or not is_instance_valid(other): continue
			if global_position.distance_to(other.global_position)<reach: other.ignite(0.35,4.0)
	if burning<=0.0:
		queue_redraw()
		if kind=="gas_can": _burst_gas()

func _run_charge(delta: float) -> void:
	if spark_cooldown>0.0: return
	spark_cooldown = 0.12
	var pass_on = charge*0.74
	if pass_on>0.08:
		for other in get_colliding_bodies():
			if other is LabBody and other.charge<pass_on: other.electrify(pass_on)
		# Ток идёт и по связям: соединил пружиной — соединил проводом.
		for link in game.links:
			var mate: LabBody = null
			if link.a==self: mate = link.b
			elif link.b==self: mate = link.a
			if is_instance_valid(mate) and mate.charge<pass_on: mate.electrify(pass_on)
	# Заряженная лужа держит под током десятки тел разом — искрим выборочно.
	if randf()<0.4: game.fx.emit_sparks(global_position,2,Color("9fe8ff"))
	if randf()<charge*0.25: ignite(0.35*charge,3.0)
	# Разряд бьёт робота целиком и один раз за полсекунды, а не по пластине.
	if is_attached_robot_part():
		if ragdoll.shock_guard>0.0: return
		ragdoll.shock_guard = 0.5
		ragdoll.hurt(9.0*charge)
		ragdoll.stun = maxf(ragdoll.stun,0.55*charge)
		for p in ragdoll.connected_parts():
			if is_instance_valid(p) and not p.freeze:
				p.apply_central_impulse(Vector2(randf_range(-1,1),randf_range(-1,0.2)).normalized()*p.mass*130.0*charge)
		game.fx.emit_sparks(global_position,6,Color("9fe8ff"))
		game.play_sound("zap",clampf(0.2+charge*0.3,0.2,0.5))
	elif randf()<charge*0.08:
		game.play_sound("zap",0.1)

func ignite(chance: float=1.0, seconds: float=5.0) -> void:
	if not is_instance_valid(game) or is_queued_for_deletion(): return
	if freeze or wet>0.2 or kind in game.EPHEMERAL: return
	var f = game.flammability(kind)
	if f<=0.0: return
	if randf()>clampf(chance*f,0.0,1.0): return
	if burning<=0.0:
		game.fx.emit_sparks(global_position,7,LabArt.AMBER,Vector2.UP*80)
		game.play_sound("ignite",0.36)
		game.record("fire")
	burning = maxf(burning,seconds*clampf(f,0.5,2.0))
	queue_redraw()

func douse(amount: float=1.0) -> void:
	wet = clampf(maxf(wet,amount),0.0,1.0)
	if burning>0.0:
		burning = 0.0
		if is_instance_valid(game):
			game.fx.emit_sparks(global_position,8,Color("cfe6ee"),Vector2.UP*60)
			game.play_sound("fizz",0.34)
	queue_redraw()

func electrify(amount: float) -> void:
	if not is_instance_valid(game) or is_queued_for_deletion(): return
	if game.conductivity(kind)<=0.0 and kind not in game.FLUIDS: return
	if amount<=charge: return
	if charge<=0.05 and amount>0.2: game.record("shock")
	charge = clampf(amount,0.0,1.0)
	queue_redraw()

func _burst_gas() -> void:
	if detonating or not is_instance_valid(game): return
	detonating = true
	game.explode(global_position,205,1.15)
	game.ignite_area(global_position,235.0,7.0)
	game.call_deferred("remove_entity",self)

func _burst_firework() -> void:
	if detonating or not is_instance_valid(game): return
	detonating = true
	for i in range(mini(14,520-game.fx.particles.size())):
		var a = TAU*float(i)/14.0+randf_range(-0.2,0.2)
		game.fx.particles.append({"p":global_position,"v":Vector2.from_angle(a)*randf_range(220,420),"life":randf_range(0.6,1.1),"max_life":1.1,"c":Color(randf_range(0.7,1.0),randf_range(0.4,0.9),randf_range(0.2,0.9)),"s":randf_range(2.5,5.0),"gravity":120.0,"glow":true,"smoke":false})
	game.fx.flash(global_position,60.0,LabArt.AMBER)
	game.ignite_area(global_position,150.0,4.0)
	game.camera_shake = maxf(game.camera_shake,3.0)
	game.play_sound("explosion",0.3)
	game.call_deferred("remove_entity",self)

func _draw() -> void:
	if is_instance_valid(game) and kind in game.FLUIDS:
		_draw_fluid()
		return
	var damaged = health/max_health
	# A ragdoll spreads its own condition across every plate: robot.hurt()
	# lowers the robot's health, not each part's, so reading the part alone
	# left a near-dead robot looking factory fresh. A locally battered part
	# still shows worse than the rest.
	if is_instance_valid(ragdoll): damaged=minf(damaged,ragdoll.health/maxf(ragdoll.max_health,1.0))
	if kind in ["head","torso","pelvis","arm","leg"]:
		var c = LabArt.TEXT.lerp(Color("536372"),1-damaged)
		_draw_robot_part(damaged, c)
	elif kind == "debris":
		draw_rect(Rect2(-dimensions/2,dimensions),tint)
	elif kind == "slug":
		draw_circle(Vector2.ZERO,5.5,LabArt.TEAL)
		draw_circle(Vector2.ZERO,2.4,LabArt.TEXT)
	elif kind == "nail":
		draw_rect(Rect2(-8,-2,14,4),Color("8aa0ad"))
		draw_colored_polygon(PackedVector2Array([Vector2(6,-2.5),Vector2(13,0),Vector2(6,2.5)]),LabArt.TEAL)
	elif kind == "emp":
		draw_circle(Vector2.ZERO,8.5,Color("7cf0c8"))
		draw_arc(Vector2.ZERO,12,0,TAU,24,LabArt.TEAL,2,true)
		draw_circle(Vector2.ZERO,3.2,LabArt.TEXT)
	elif kind == "rocket":
		draw_rect(Rect2(-10,-4,16,8),Color("6d7f8c"))
		draw_colored_polygon(PackedVector2Array([Vector2(6,-4),Vector2(12,0),Vector2(6,4)]),LabArt.AMBER)
	elif kind == "chill":
		draw_circle(Vector2.ZERO,7.5,Color("74cafa"))
		draw_arc(Vector2.ZERO,10.5,0,TAU,16,Color("d6f4ff"),2,true)
	elif kind == "bounce":
		draw_circle(Vector2.ZERO,6.5,Color("e06f72"))
		draw_arc(Vector2.ZERO,7.5,0,TAU,16,LabArt.AMBER,2,true)
	elif kind == "disc":
		draw_circle(Vector2.ZERO,11.5,Color("5c6d78"))
		draw_arc(Vector2.ZERO,10.5,0,TAU,20,LabArt.AMBER,2,true)
	elif kind == "flame":
		draw_circle(Vector2.ZERO,6.5,LabArt.AMBER)
		draw_circle(Vector2.ZERO,3.2,Color("ffe8a0"))
	elif kind == "cannonball":
		draw_circle(Vector2.ZERO,11.5,Color("3a4a55"))
		draw_arc(Vector2.ZERO,10.5,0,TAU,16,Color("8aa0ad"),2,true)
	elif kind == "tether":
		draw_rect(Rect2(-9,-2,16,4),LabArt.TEAL)
	elif kind in LabParts.KINDS:
		LabParts.draw(self,kind,damaged,active,gear,track_phase)
	elif kind in LabVehicle.KINDS:
		var at: Array = []
		for w in wheels: if is_instance_valid(w): at.append(to_local(w.global_position))
		LabVehicle.draw_body(self,kind,damaged,active,gear,at,track_phase)
	elif kind == LabVehicle.WHEEL:
		LabVehicle.draw_wheel(self,Vector2.ZERO,dimensions.x*0.5,vehicle_style,0.0)
	else:
		LabArt.icon(self,kind,Vector2.ZERO,1.0,tint)
	if active and kind in ["magnet","fan","coil","wheel","turret","drone","chainsaw"] or (is_instance_valid(game) and game.TOY_PHYS.has(kind) and game.TOY_PHYS[kind].has("mode")):
		var aura_pulse = 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.008)
		draw_arc(Vector2.ZERO,maxf(dimensions.x,dimensions.y)*0.58,0,TAU,36,Color(0.3,1.0,0.78,0.75 * aura_pulse),2,true)
		draw_circle(Vector2(dimensions.x*0.43,-dimensions.y*0.43),3.2,LabArt.TEAL)
	if kind=="drone" and active and health>0:
		var spin=Time.get_ticks_msec()*0.05
		# Blurred rotor discs
		for p in [Vector2(-18,-5),Vector2(18,-5)]:
			draw_circle(p, 10, Color(0.35, 0.95, 0.85, 0.12))
			var a=Vector2.from_angle(spin)*10
			draw_line(p-a,p+a,Color(0.45,1,0.90,0.65),2)
		# Navigation lights: Red on left, Green on right, White strobe on bottom
		draw_circle(Vector2(-20, 2), 2.0, Color(1.0, 0.25, 0.2, 0.9))
		draw_circle(Vector2(20, 2), 2.0, Color(0.25, 1.0, 0.35, 0.9))
		var strobe = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.015)
		draw_circle(Vector2(0, 8), 1.8, Color(1.0, 1.0, 1.0, strobe * 0.95))
	if active and kind=="grenade":
		var blink=0.45+0.55*absf(sin(Time.get_ticks_msec()*0.012))
		draw_arc(Vector2.ZERO,16,0,TAU,28,Color(1,0.35,0.28,blink),2,true)
	if freeze:
		var fr_rect = Rect2(-dimensions/2-Vector2(5,5),dimensions+Vector2(10,10))
		_overlay(Color(0.42, 0.82, 1.0, 0.22))
		if kind in LabVehicle.KINDS: _hull_outline(Color("80d4ff"))
		if kind not in LabVehicle.KINDS: draw_rect(fr_rect, Color("80d4ff"), false, 1.8)
		for p in [fr_rect.position, Vector2(fr_rect.end.x, fr_rect.position.y), Vector2(fr_rect.position.x, fr_rect.end.y), fr_rect.end]:
			draw_circle(p, 2.2, Color("e4f7ff"))
		draw_line(fr_rect.position + Vector2(3, 3), fr_rect.position + Vector2(9, 9), Color(1, 1, 1, 0.45), 1.5)
		draw_line(fr_rect.end - Vector2(3, 3), fr_rect.end - Vector2(9, 9), Color(1, 1, 1, 0.45), 1.5)
	if scorch > 0.02:
		_overlay(Color(0.05,0.04,0.04,clampf(scorch*0.55,0.0,0.55)))
	if burning > 0.0:
		var t_fire = Time.get_ticks_msec()*0.004
		var w = dimensions.x*0.5
		LabArt.soft_glow(self,Vector2.ZERO,maxf(dimensions.x,dimensions.y)*0.75,Color(1.0,0.55,0.15,1.0),1.6)
		for i in range(5):
			var fx_x = lerp(-w,w,float(i)/4.0)
			var h = (12.0+sin(t_fire*3.0+float(i)*1.7)*7.0)+dimensions.y*0.22
			var base_y = -dimensions.y*0.5
			draw_colored_polygon(PackedVector2Array([
				Vector2(fx_x-5,base_y),Vector2(fx_x,base_y-h),Vector2(fx_x+5,base_y)]),Color(1.0,0.45,0.12,0.8))
			draw_colored_polygon(PackedVector2Array([
				Vector2(fx_x-2.4,base_y),Vector2(fx_x,base_y-h*0.55),Vector2(fx_x+2.4,base_y)]),Color(1.0,0.87,0.45,0.9))
	if charge > 0.1:
		var arc_c = Color(0.62,0.91,1.0,clampf(charge,0.25,1.0))
		LabArt.soft_glow(self,Vector2.ZERO,maxf(dimensions.x,dimensions.y)*0.6,arc_c,charge)
		var rng = RandomNumberGenerator.new()
		rng.seed = serial*31+Engine.get_physics_frames()/3
		for i in range(3):
			var a0 = Vector2(rng.randf_range(-1,1)*dimensions.x*0.5,rng.randf_range(-1,1)*dimensions.y*0.5)
			var a1 = a0+Vector2(rng.randf_range(-12,12),rng.randf_range(-12,12))
			draw_line(a0,a1,arc_c,1.6,true)
	if wet > 0.15 and burning <= 0.0:
		_overlay(Color(0.29,0.66,0.88,clampf(wet*0.22,0.0,0.22)))
	if highlighted:
		var glow = 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.008)
		var hr = Rect2(-dimensions/2 - Vector2(7, 7), dimensions + Vector2(14, 14))
		var c_teal = Color(LabArt.TEAL.r, LabArt.TEAL.g, LabArt.TEAL.b, glow)
		var blen = minf(12.0, minf(dimensions.x, dimensions.y) * 0.35)
		# Sci-fi corner brackets
		draw_line(hr.position, hr.position + Vector2(blen, 0), c_teal, 2.0, true)
		draw_line(hr.position, hr.position + Vector2(0, blen), c_teal, 2.0, true)
		draw_line(Vector2(hr.end.x, hr.position.y), Vector2(hr.end.x - blen, hr.position.y), c_teal, 2.0, true)
		draw_line(Vector2(hr.end.x, hr.position.y), Vector2(hr.end.x, hr.position.y + blen), c_teal, 2.0, true)
		draw_line(Vector2(hr.position.x, hr.end.y), Vector2(hr.position.x + blen, hr.end.y), c_teal, 2.0, true)
		draw_line(Vector2(hr.position.x, hr.end.y), Vector2(hr.position.x, hr.end.y - blen), c_teal, 2.0, true)
		draw_line(hr.end, hr.end - Vector2(blen, 0), c_teal, 2.0, true)
		draw_line(hr.end, hr.end - Vector2(0, blen), c_teal, 2.0, true)
		draw_rect(hr, Color(LabArt.TEAL.r, LabArt.TEAL.g, LabArt.TEAL.b, 0.05 * glow), true)
	if active and kind == "thruster":
		var time_f = Time.get_ticks_msec() * 0.001
		var flicker = 22.0 + sin(time_f * 45.0) * 6.0 + sin(time_f * 80.0) * 4.0
		# Outer fiery plume
		draw_colored_polygon(PackedVector2Array([Vector2(-10, 24), Vector2(0, 24 + flicker), Vector2(10, 24)]), Color(1.0, 0.45, 0.1, 0.85))
		# Inner core flame (cyan-white hot plasma)
		var core_flicker = flicker * 0.65
		draw_colored_polygon(PackedVector2Array([Vector2(-5, 24), Vector2(0, 24 + core_flicker), Vector2(5, 24)]), Color(0.75, 0.98, 1.0, 0.95))
		# Shock diamond
		var d_y = 24.0 + flicker * 0.35
		draw_colored_polygon(PackedVector2Array([Vector2(0, d_y - 3), Vector2(3, d_y), Vector2(0, d_y + 3), Vector2(-3, d_y)]), Color(1.0, 1.0, 0.95))
	if kind == "c4":
		var led_blink = 0.4 + 0.6 * absf(sin(Time.get_ticks_msec() * 0.015))
		draw_circle(Vector2(5, 4), 2.5, Color(1.0, 0.2, 0.2, led_blink))
	if kind.begins_with("syringe_") and payload > 0:
		draw_rect(Rect2(-3, -7, 6, 14), Color(0.1, 0.15, 0.2, 0.85))

# Копоть, мокрость и иней ложатся по форме тела. У машины это многоугольники
# кузова — прямоугольник по габаритам висел бы над ней заплатой.
func _overlay(color: Color) -> void:
	if kind in LabVehicle.KINDS:
		for poly in LabVehicle.spec(kind).hull: draw_colored_polygon(PackedVector2Array(poly),color)
	else:
		if kind in LabGeometry.ROUND or kind in ["ball","cork","tire","gyro","gel","spinner_pad","pulsar","grav_well","zapper","slow_field","rotator"]:
			draw_circle(Vector2.ZERO,dimensions.x*0.5,color,true,-1,true)
		else:
			draw_colored_polygon(LabGeometry.outline(kind,dimensions),color)

func _hull_outline(color: Color) -> void:
	for poly in LabVehicle.spec(kind).hull:
		var pts=PackedVector2Array(poly)
		pts.append(pts[0])
		draw_polyline(pts,color,1.8,true)

func _draw_fluid() -> void:
	var half = dimensions*0.5
	var base = _fluid_tint()
	var body_a = 0.42 if kind=="oil_pool" else 0.34
	# Поверхность: две бегущие волны, чтобы лужа не выглядела наклейкой.
	var t_wave = Time.get_ticks_msec()*0.0013
	var steps = maxi(8,int(dimensions.x/14.0))
	var crest := PackedVector2Array()
	for i in range(steps+1):
		var x = lerp(-half.x,half.x,float(i)/float(steps))
		crest.append(Vector2(x,-half.y+sin(t_wave*2.0+x*0.05)*2.4+sin(t_wave*3.3+x*0.11)*1.2))
	var water_shape=crest.duplicate()
	water_shape.append(Vector2(half.x,half.y))
	water_shape.append(Vector2(-half.x,half.y))
	var water_colors=PackedColorArray()
	for i in range(crest.size()): water_colors.append(Color(base.r,base.g,base.b,body_a*0.52).lightened(0.15))
	water_colors.append(Color(base.r*0.65,base.g*0.72,base.b*0.85,body_a*1.55))
	water_colors.append(Color(base.r*0.65,base.g*0.72,base.b*0.85,body_a*1.55))
	draw_polygon(water_shape,water_colors)
	draw_polyline(crest,Color(base.r,base.g,base.b,0.9).lightened(0.3),2.0,true)
	for i in range(5):
		var shine_x=-half.x+dimensions.x*(float(i)+0.5)/5.0
		var shine_y=-half.y+12.0+sin(t_wave+float(i)*2.4)*3.0
		draw_line(Vector2(shine_x-10,shine_y),Vector2(shine_x+9,shine_y-1),Color(base.r,base.g,base.b,0.16).lightened(0.35),1.4,true)
	draw_rect(Rect2(-half,dimensions),Color(base.r,base.g,base.b,0.75),false,1.5)
	if kind=="acid_pool":
		for i in range(3):
			var bx = sin(t_wave*1.7+float(i)*2.1)*half.x*0.7
			var by = half.y-fposmod(t_wave*40.0+float(i)*30.0,dimensions.y)
			draw_circle(Vector2(bx,by),2.2,Color(0.8,1.0,0.6,0.5))
	if charge>0.1:
		LabArt.soft_glow(self,Vector2.ZERO,half.x,Color(0.62,0.91,1.0,1.0),charge)
		draw_rect(Rect2(-half,dimensions),Color(0.62,0.91,1.0,clampf(charge*0.3,0.0,0.3)))
	if burning>0.0:
		for i in range(6):
			var fx_x = lerp(-half.x,half.x,float(i)/5.0)
			var h = 16.0+sin(Time.get_ticks_msec()*0.005+float(i))*8.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(fx_x-7,-half.y),Vector2(fx_x,-half.y-h),Vector2(fx_x+7,-half.y)]),Color(1.0,0.5,0.15,0.75))
	if highlighted:
		draw_rect(Rect2(-half-Vector2(6,6),dimensions+Vector2(12,12)),LabArt.TEAL,false,2.0)

func detonate() -> void:
	if is_instance_valid(game):
		game.explode(global_position, 280, 2.0)
		game.call_deferred("remove_entity", self)

func _draw_robot_part(damaged: float, c: Color) -> void:
	var v: String = ragdoll.variant if is_instance_valid(ragdoll) else "robot"
	var eye = tint
	if is_instance_valid(ragdoll):
		var tier = ragdoll.damage_tier()
		eye = [tint, tint, LabArt.AMBER, LabArt.RED][tier]
	else:
		eye = LabArt.RED

	if kind == "head":
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE*(dimensions.x/28.0))
		_draw_robot_head(damaged, c, v, eye)
		draw_set_transform(Vector2.ZERO)
	elif kind == "torso":
		_draw_robot_torso(damaged, c, v, eye)
	elif kind == "pelvis":
		_draw_robot_pelvis(damaged, c, v)
	else:
		_draw_robot_limb(damaged, c, v)
	LabArt.damage(self, Rect2(-dimensions/2, dimensions), 1.0 - damaged, serial)

func _draw_robot_head(damaged: float, c: Color, v: String, eye: Color) -> void:
	LabSurface.circle(self, Vector2(3,4), 15, Color(0,0,0,0.18))
	if v != "robot_magnet":
		for side in [-1,1]: LabSurface.plate(self, Rect2(side*13-2,-7,5,12), Color("536b76"), 2, Color("8399a2"))
	LabSurface.plate(self, Rect2(-5,12,10,6), Color("4a626e"), 2, Color("7f959e"))
	
	var head_bg = c
	if v == "robot_medic": head_bg = Color("eaf2f5")
	elif v == "robot_titan": head_bg = Color("4b5c66")
	elif v == "robot_acrobat": head_bg = Color("2e222d")
	
	LabArt.bevel_box(self, Rect2(-14,-14,28,28), head_bg, 8, Color("718996"), 2)
	draw_arc(Vector2(-2,-2), 11, 3.45, 5.15, 14, Color(1,1,1,0.22), 2, true)
	
	match v:
		"robot_titan":
			LabSurface.plate(self, Rect2(-17,-16,34,10), Color("2b3840"), 3, Color("5b727d"))
			LabArt.bolt(self, Vector2(-12,-11), 1.5, Color("9ab0ba"))
			LabArt.bolt(self, Vector2(12,-11), 1.5, Color("9ab0ba"))
			LabArt.bevel_box(self, Rect2(-15,6,30,10), Color("243037"), 2, Color("526974"))
			for slit_x in [-6,0,6]: LabSurface.line(self, Vector2(slit_x,7), Vector2(slit_x,14), Color("0b1317"), 1.5)
			LabSurface.plate(self, Rect2(-11,-3,22,6), Color("0d171c"), 2)
			LabArt.soft_glow(self, Vector2(0,0), 10, Color(eye.r,eye.g,eye.b,0.7), 0.9)
			LabSurface.line(self, Vector2(-9,0), Vector2(9,0), eye, 2.5, true)
			LabSurface.line(self, Vector2(-5,0), Vector2(5,0), Color.WHITE, 1.2, true)
		"robot_scout":
			LabSurface.line(self, Vector2(-7,-14), Vector2(-15,-30), Color("7e95a0"), 2, true)
			LabSurface.line(self, Vector2(7,-14), Vector2(15,-30), Color("7e95a0"), 2, true)
			LabSurface.circle(self, Vector2(-15,-30), 2.5, LabArt.AMBER)
			LabSurface.circle(self, Vector2(15,-30), 2.5, LabArt.AMBER)
			LabArt.soft_glow(self, Vector2(-15,-30), 6, Color(1,0.7,0.3,0.5), 0.6)
			LabArt.soft_glow(self, Vector2(15,-30), 6, Color(1,0.7,0.3,0.5), 0.6)
			LabSurface.circle(self, Vector2(-4,-1), 5.2, Color("0b1d24"))
			LabArt.soft_glow(self, Vector2(-4,-1), 8, Color(eye.r,eye.g,eye.b,0.8), 0.9)
			LabSurface.circle(self, Vector2(-4,-1), 3.5, eye)
			LabSurface.circle(self, Vector2(-4,-1), 1.5, Color.WHITE)
			LabSurface.circle(self, Vector2(6,-4), 2.2, Color("0b1d24")); LabSurface.circle(self, Vector2(6,-4), 1.4, LabArt.AMBER)
			LabSurface.circle(self, Vector2(6,2), 2.2, Color("0b1d24")); LabSurface.circle(self, Vector2(6,2), 1.4, Color("54d9ff"))
			LabSurface.line(self, Vector2(-12,-8), Vector2(12,-8), Color("3d5460"), 2, true)
		"robot_jumper":
			LabSurface.polygon(self, PackedVector2Array([Vector2(0,-14), Vector2(-3,-25), Vector2(6,-27), Vector2(4,-14)]), Color("769c3a"))
			LabSurface.line(self, Vector2(0,-14), Vector2(6,-27), Color("b4e65e"), 1.5, true)
			for x in [-6, 6]:
				LabSurface.circle(self, Vector2(x,-1), 4.6, Color("14220b"))
				LabArt.soft_glow(self, Vector2(x,-1), 7, Color(eye.r,eye.g,eye.b,0.7), 0.8)
				LabSurface.circle(self, Vector2(x,-1), 3.2, eye)
				LabSurface.circle(self, Vector2(x-1,-2), 1.2, Color.WHITE)
		"robot_magnet":
			LabSurface.plate(self, Rect2(-21,-8,8,14), Color("b83b32"), 2)
			LabSurface.plate(self, Rect2(-24,-6,3,10), Color("dcdfe1"), 1)
			draw_string(ThemeDB.fallback_font, Vector2(-19,2), "N", HORIZONTAL_ALIGNMENT_CENTER, 6, 8, Color.WHITE)
			LabSurface.plate(self, Rect2(13,-8,8,14), Color("3269b8"), 2)
			LabSurface.plate(self, Rect2(21,-6,3,10), Color("dcdfe1"), 1)
			draw_string(ThemeDB.fallback_font, Vector2(15,2), "S", HORIZONTAL_ALIGNMENT_CENTER, 6, 8, Color.WHITE)
			for r in range(3): draw_arc(Vector2(0,-1), 7.0-float(r)*2.0, 0, TAU, 16, Color("9a5fe3"), 1.5, true)
			LabSurface.line(self, Vector2(-7,-1), Vector2(7,-1), eye, 2, true)
		"robot_tesla":
			LabSurface.line(self, Vector2(0,-14), Vector2(0,-26), Color("c47941"), 4, true)
			for y in [-17, -20, -23]: LabSurface.line(self, Vector2(-4,y), Vector2(4,y), Color("df9b63"), 1.8, true)
			draw_arc(Vector2(0,-27), 5, 0, TAU, 16, Color("c9dbe3"), 2.5, true)
			LabSurface.circle(self, Vector2(0,-27), 2, Color.WHITE)
			LabArt.soft_glow(self, Vector2(0,-27), 9, Color(0.4,0.8,1.0,0.6), 0.8)
			LabSurface.plate(self, Rect2(-11,-5,22,9), Color("0a1a24"), 3, Color("2f657d"))
			LabSurface.line(self, Vector2(-8,-1), Vector2(8,-1), Color("8ce7ff"), 2.5, true)
			LabSurface.line(self, Vector2(-4,-1), Vector2(4,-1), Color.WHITE, 1.2, true)
		"robot_bomber":
			LabSurface.plate(self, Rect2(-14,-14,28,7), Color("222222"), 2)
			for hs in range(5):
				LabSurface.line(self, Vector2(-14.0+float(hs)*6.0,-7), Vector2(-10.0+float(hs)*6.0,-14), Color("eab308"), 2.5, true)
			LabSurface.plate(self, Rect2(-11,-5,22,10), Color("15181a"), 2, Color("4a5257"))
			for mx in range(-9,10,3): LabSurface.line(self, Vector2(mx,-5), Vector2(mx,5), Color("3d454a"), 1)
			for my in range(-4,5,3): LabSurface.line(self, Vector2(-11,my), Vector2(11,my), Color("3d454a"), 1)
			LabSurface.circle(self, Vector2(-5,-0.5), 2.2, eye); LabSurface.circle(self, Vector2(5,-0.5), 2.2, eye)
			LabSurface.plate(self, Rect2(-17,-8,5,14), Color("451d18"), 2)
			LabSurface.plate(self, Rect2(12,-8,5,14), Color("451d18"), 2)
		"robot_medic":
			LabSurface.rect(self, Rect2(-2,-12,4,7), Color("22c55e"))
			LabSurface.rect(self, Rect2(-5,-10.5,10,4), Color("22c55e"))
			LabSurface.circle(self, Vector2(9,-8), 3.5, Color("344955"))
			LabSurface.circle(self, Vector2(9,-8), 2.2, Color.WHITE)
			LabArt.soft_glow(self, Vector2(9,-8), 10, Color(0.9,1.0,0.9,0.7), 0.9)
			LabSurface.plate(self, Rect2(-10,-4,16,8), Color("142823"), 3, Color("256653"))
			LabSurface.line(self, Vector2(-7,0), Vector2(3,0), Color("4ade80"), 2, true)
		"robot_antigrav":
			draw_arc(Vector2(0,-24), 14, 0, TAU, 28, Color(0.87,0.48,0.95,0.75), 2, true)
			LabArt.soft_glow(self, Vector2(0,-24), 14, Color(0.8,0.3,0.95,0.4), 0.7)
			for node in range(4): LabSurface.circle(self, Vector2.from_angle(float(node)*PI/2)*14+Vector2(0,-24), 2, Color.WHITE)
			LabSurface.plate(self, Rect2(-12,-6,24,12), Color("0d0814"), 5, Color("532a68"))
			draw_arc(Vector2(0,-1), 8, 3.3, 6.1, 14, Color(0.9,0.5,1.0,0.8), 2, true)
		"robot_runner":
			LabSurface.polygon(self, PackedVector2Array([Vector2(-14,-14), Vector2(0,-24), Vector2(14,-14), Vector2(12,8), Vector2(-12,8)]), Color("3d3624"))
			LabSurface.line(self, Vector2(0,-24), Vector2(0,10), Color("facc15"), 2, true)
			LabSurface.polygon(self, PackedVector2Array([Vector2(-11,-5), Vector2(0,-2), Vector2(11,-5), Vector2(9,3), Vector2(0,5), Vector2(-9,3)]), Color("eab308"))
			LabSurface.circle(self, Vector2(-5,0), 1.5, Color.WHITE); LabSurface.circle(self, Vector2(5,0), 1.5, Color.WHITE)
		"robot_acrobat":
			LabSurface.polygon(self, PackedVector2Array([Vector2(0,14), Vector2(-14,2), Vector2(-14,-14), Vector2(14,-14), Vector2(14,2)]), Color("2b1e2a"))
			LabSurface.line(self, Vector2(-9,-3), Vector2(-3,-1), eye, 2, true)
			LabSurface.line(self, Vector2(9,-3), Vector2(3,-1), eye, 2, true)
			LabSurface.line(self, Vector2(-14,-6), Vector2(-22,-14), Color("db2777"), 2, true)
			LabSurface.line(self, Vector2(14,-6), Vector2(22,-14), Color("db2777"), 2, true)
		_:
			LabSurface.line(self, Vector2(0,-14), Vector2(0,-22), Color("8ca3ad"), 2)
			LabSurface.circle(self, Vector2(0,-24), 3.5, Color("243c47"))
			LabSurface.circle(self, Vector2(0,-24), 2, tint)
			LabArt.soft_glow(self, Vector2(0,-24), 6, Color(tint.r,tint.g,tint.b,0.6), 0.7)
			LabSurface.plate(self, Rect2(-11,-6,22,11), Color("112a34"), 4, Color("3c5863"))
			for x in [-6,6]:
				LabSurface.circle(self, Vector2(x,-0.5), 2.6, Color("06151c"))
				LabArt.soft_glow(self, Vector2(x,-1), 6, Color(eye.r,eye.g,eye.b,0.60), 0.85)
				LabSurface.circle(self, Vector2(x,-1), 1.7, eye)
				LabSurface.circle(self, Vector2(x,-1), 0.75, Color.WHITE)
			LabSurface.line(self, Vector2(-9,-3), Vector2(2,3), Color(1.0,1.0,1.0,0.18), 1.2, true)
			LabSurface.line(self, Vector2(-5,9), Vector2(5,9), Color("728993"), 1)

func _draw_robot_torso(damaged: float, c: Color, v: String, eye: Color) -> void:
	var col = tint.darkened(0.13)
	if v == "robot_medic": col = Color("38505c")
	elif v == "robot_titan": col = Color("2e3d45")
	elif v == "robot_acrobat": col = Color("251c27")
	
	LabSurface.plate(self, Rect2(-dimensions/2+Vector2(3,5), dimensions), Color(0,0,0,0.16), 5)
	LabSurface.polygon(self,LabGeometry.outline("torso",dimensions),col)
	# Separate shoulder yoke, chest shell and lower service ribs.
	LabSurface.polygon(self,PackedVector2Array([Vector2(-dimensions.x*0.38,-dimensions.y*0.43),Vector2(dimensions.x*0.38,-dimensions.y*0.43),Vector2(dimensions.x*0.31,-dimensions.y*0.29),Vector2(-dimensions.x*0.31,-dimensions.y*0.29)]),c.darkened(0.18))
	for rib in range(3):
		var y=dimensions.y*(0.28+float(rib)*0.065)
		LabSurface.line(self,Vector2(-dimensions.x*0.28,y),Vector2(dimensions.x*0.28,y),Color("29424e"),1.4)
	LabSurface.plate(self, Rect2(-dimensions/2+Vector2(3,3), Vector2(3,dimensions.y-6)), Color(1,1,1,0.12), 1)
	LabSurface.line(self, Vector2(-dimensions.x*0.42,-dimensions.y*0.34), Vector2(dimensions.x*0.42,-dimensions.y*0.34), col.lightened(0.22), 2, true)
	
	match v:
		"robot_titan":
			LabArt.bevel_box(self, Rect2(-dimensions.x*0.62,-dimensions.y*0.48,dimensions.x*1.24,13), Color("2f3e46"), 3, Color("5c7582"))
			LabArt.bolt(self, Vector2(-dimensions.x*0.5,-dimensions.y*0.42), 2, Color("9ab0ba"))
			LabArt.bolt(self, Vector2(dimensions.x*0.5,-dimensions.y*0.42), 2, Color("9ab0ba"))
			LabSurface.rect(self, Rect2(-dimensions.x*0.42,-dimensions.y*0.25,dimensions.x*0.84,dimensions.y*0.65), Color("1e2a30"))
			LabSurface.line(self, Vector2(-8,-4), Vector2(8,-4), Color("5c7582"), 3)
			LabSurface.line(self, Vector2(0,-12), Vector2(0,4), Color("5c7582"), 3)
			LabArt.soft_glow(self, Vector2(0,-4), 10, Color(tint.r,tint.g,tint.b,0.4), 0.6)
		"robot_scout":
			for ch in range(3):
				var cy = -dimensions.y*0.25 + float(ch)*10.0
				draw_polyline(PackedVector2Array([Vector2(-8,cy-4), Vector2(0,cy), Vector2(8,cy-4)]), Color("54d9ff"), 2, true)
			LabSurface.circle(self, Vector2(-dimensions.x*0.35,-dimensions.y*0.35), 2.5, LabArt.AMBER)
		"robot_jumper":
			LabSurface.plate(self, Rect2(-8,-16,16,30), Color("182410"), 3, Color("3b5420"))
			for sc in range(5): LabSurface.line(self, Vector2(-6,-12+sc*5), Vector2(6,-10+sc*5), Color("a7e05c"), 2, true)
			LabArt.soft_glow(self, Vector2(0,0), 10, Color(0.65,0.9,0.3,0.5), 0.7)
		"robot_magnet":
			LabSurface.circle(self, Vector2(0,-4), 12, Color("1a1226"))
			for coil_a in range(8):
				var ang = float(coil_a)*PI/4.0
				LabSurface.line(self, Vector2(0,-4)+Vector2.from_angle(ang)*7, Vector2(0,-4)+Vector2.from_angle(ang)*11, Color("e08852"), 2, true)
			LabSurface.circle(self, Vector2(0,-4), 6, Color("8a4fe0"))
			LabArt.soft_glow(self, Vector2(0,-4), 12, Color(0.6,0.3,0.95,0.6), 0.8)
			LabSurface.circle(self, Vector2(-10,-12), 3, Color("b83b32"))
			LabSurface.circle(self, Vector2(10,-12), 3, Color("3269b8"))
		"robot_tesla":
			LabSurface.plate(self, Rect2(-9,-16,18,28), Color("08151f"), 4, Color("4587a3"))
			LabSurface.line(self, Vector2(-4,-10), Vector2(2,-3), Color("7de8ff"), 1.8, true)
			LabSurface.line(self, Vector2(2,-3), Vector2(-2,4), Color("7de8ff"), 1.8, true)
			LabSurface.line(self, Vector2(-2,4), Vector2(4,9), Color("7de8ff"), 1.8, true)
			LabArt.soft_glow(self, Vector2(0,-1), 12, Color(0.4,0.85,1.0,0.65), 0.8)
			draw_string(ThemeDB.fallback_font, Vector2(-4,18), "⚡", HORIZONTAL_ALIGNMENT_CENTER, 8, 9, Color("ffea79"))
		"robot_bomber":
			for hs in range(3): LabSurface.line(self, Vector2(-dimensions.x*0.4,-dimensions.y*0.3+hs*7), Vector2(dimensions.x*0.4,-dimensions.y*0.3+hs*7), Color("eab308"), 2.5, true)
			LabSurface.plate(self, Rect2(-11,-5,22,14), Color("701c14"), 2, Color("a8382c"))
			for dy in [-6,0,6]: LabSurface.circle(self, Vector2(dy,2), 2.5, Color("a8382c"))
			LabSurface.circle(self, Vector2(0,-12), 2, LabArt.RED)
			LabArt.soft_glow(self, Vector2(0,-12), 5, Color(1,0,0,0.7), 0.8)
		"robot_medic":
			LabSurface.plate(self, Rect2(-10,-12,20,20), Color("e8eff2"), 3, Color("9bb2bd"))
			LabSurface.rect(self, Rect2(-3,-9,6,14), Color("22c55e"))
			LabSurface.rect(self, Rect2(-7,-5,14,6), Color("22c55e"))
			LabSurface.plate(self, Rect2(-dimensions.x*0.48,-8,4,16), Color("12291d"), 1, Color("4ade80"))
			LabSurface.plate(self, Rect2(dimensions.x*0.48-4,-8,4,16), Color("12291d"), 1, Color("4ade80"))
		"robot_antigrav":
			draw_arc(Vector2(0,-4), 9, 0, TAU, 24, Color(0.87,0.48,0.95), 1.5, true)
			draw_arc(Vector2(0,-4), 5, 0, TAU, 18, Color(0.95,0.75,1.0), 2, true)
			LabSurface.circle(self, Vector2(0,-4), 2.5, Color.WHITE)
			LabArt.soft_glow(self, Vector2(0,-4), 12, Color(0.8,0.3,0.95,0.65), 0.8)
			LabSurface.line(self, Vector2(-8,dimensions.y*0.35), Vector2(-12,dimensions.y*0.48), Color("b55fe6"), 2.5, true)
			LabSurface.line(self, Vector2(8,dimensions.y*0.35), Vector2(12,dimensions.y*0.48), Color("b55fe6"), 2.5, true)
		"robot_runner":
			LabSurface.line(self, Vector2(-3,-dimensions.y*0.45), Vector2(-3,dimensions.y*0.45), Color("facc15"), 2, true)
			LabSurface.line(self, Vector2(3,-dimensions.y*0.45), Vector2(3,dimensions.y*0.45), Color("facc15"), 2, true)
			LabSurface.plate(self, Rect2(-dimensions.x*0.48,-4,4,12), Color("171717"), 1, Color("525252"))
			LabSurface.plate(self, Rect2(dimensions.x*0.48-4,-4,4,12), Color("171717"), 1, Color("525252"))
		"robot_acrobat":
			for rip in range(4): LabSurface.line(self, Vector2(-dimensions.x*0.35,-12+rip*8), Vector2(dimensions.x*0.35,-12+rip*8), Color("db2777"), 1.8, true)
			LabSurface.line(self, Vector2(-dimensions.x*0.4,-dimensions.y*0.3), Vector2(-dimensions.x*0.6,-dimensions.y*0.45), Color("ec4899"), 2, true)
			LabSurface.line(self, Vector2(dimensions.x*0.4,-dimensions.y*0.3), Vector2(dimensions.x*0.6,-dimensions.y*0.45), Color("ec4899"), 2, true)
		_:
			LabSurface.circle(self, Vector2(0,-4), 10.5, Color("102832"))
			LabSurface.circle(self, Vector2(0,-4), 8, Color("1b3d44"))
			LabArt.soft_glow(self, Vector2(0,-4), 11, Color(tint.r,tint.g,tint.b,0.45), 0.75)
			draw_arc(Vector2(0,-4), 6, -PI/2, TAU*damaged-PI/2, 28, tint.lightened(0.22), 2.5, true)
			LabSurface.circle(self, Vector2(0,-4), 2.4, Color("d9faf3"))
			for i in range(3):
				LabSurface.line(self, Vector2(-8,11+i*4), Vector2(8,11+i*4), Color("173b3a"), 2, true)
				LabSurface.line(self, Vector2(-7,10+i*4), Vector2(5,10+i*4), Color(0.55,1,0.88,0.14), 1, true)
	
	if is_instance_valid(ragdoll) and ragdoll.virus != "":
		LabSurface.circle(self, Vector2(10,10), 4, ragdoll.virus_color())
		if ragdoll.active: draw_arc(Vector2.ZERO, dimensions.x*0.7, 0, TAU, 28, ragdoll.virus_color(), 2, true)
	elif is_instance_valid(ragdoll) and ragdoll.active:
		draw_arc(Vector2.ZERO, dimensions.x*0.64, 0, TAU, 28, tint, 1.8, true)

func _draw_robot_pelvis(damaged: float, c: Color, v: String) -> void:
	var col = tint.darkened(0.18)
	LabSurface.plate(self, Rect2(-dimensions/2+Vector2(3,5), dimensions), Color(0,0,0,0.16), 5)
	LabSurface.polygon(self,LabGeometry.outline("pelvis",dimensions),col)
	for side in [-1,1]:
		LabSurface.circle(self,Vector2(side*dimensions.x*0.28,dimensions.y*0.25),dimensions.x*0.12,Color("839eae"))
	match v:
		"robot_titan":
			LabSurface.plate(self, Rect2(-dimensions.x*0.4,-5,dimensions.x*0.8,11), Color("28353c"), 2, Color("526974"))
			LabArt.bolt(self, Vector2(0, 0), 2.2, Color("9ab0ba"))
		"robot_medic":
			LabSurface.plate(self, Rect2(-dimensions.x*0.42,-4,dimensions.x*0.84,9), Color("294339"), 2, Color("4ade80"))
			LabArt.bolt(self, Vector2(0, 0), 1.8, Color("4ade80"))
		"robot_bomber":
			LabSurface.plate(self, Rect2(-dimensions.x*0.42,-4,dimensions.x*0.84,9), Color("451d18"), 2, Color("a8382c"))
			LabArt.bolt(self, Vector2(0, 0), 1.8, Color("eab308"))
		_:
			LabSurface.plate(self, Rect2(-dimensions.x*0.34,-4,dimensions.x*0.68,9), Color("173039"), 3, Color("49636e"))
			LabArt.bolt(self, Vector2.ZERO, 2, Color("a9bbc1"))

func _draw_robot_limb(damaged: float, c: Color, v: String) -> void:
	LabSurface.plate(self, Rect2(-dimensions/2+Vector2(2,4), dimensions), Color(0,0,0,0.14), 4)
	LabSurface.polygon(self,LabGeometry.outline(kind,dimensions),c)
	LabSurface.plate(self,Rect2(-dimensions.x*0.22,-dimensions.y*0.23,dimensions.x*0.44,dimensions.y*0.46),Color("3b5362"),1.5)
	LabSurface.line(self,Vector2(-dimensions.x*0.10,-dimensions.y*0.20),Vector2(-dimensions.x*0.10,dimensions.y*0.20),Color("c9dce5"),1.4)
	LabSurface.circle(self,Vector2(0,-dimensions.y*0.37),dimensions.x*0.31,Color("718d9e"))
	LabSurface.line(self,Vector2(-dimensions.x*0.27,dimensions.y*0.32),Vector2(dimensions.x*0.27,dimensions.y*0.32),tint.darkened(0.18),2.4)
	if part_index in [8,10]:
		LabSurface.plate(self,Rect2(-dimensions.x*0.40,dimensions.y*0.31,dimensions.x*0.80,dimensions.y*0.18),Color("3c5260"),1.5)
	LabArt.bolt(self, Vector2(0,-dimensions.y/2+5), 2.2, Color("91a6ae"))
	LabSurface.circle(self, Vector2(0,dimensions.y/2-4), 2, Color("3a525f"))
	
	match v:
		"robot_titan":
			LabSurface.plate(self, Rect2(-dimensions.x/2-2,-5,dimensions.x+4,10), Color("26343b"), 2, Color("4c626d"))
			LabArt.bolt(self, Vector2(0,0), 2.0, Color("9ab0ba"))
		"robot_jumper":
			if kind == "leg":
				for coil_i in range(5):
					var cy = -dimensions.y*0.32 + float(coil_i)*6.5
					LabSurface.line(self, Vector2(-dimensions.x*0.4, cy), Vector2(dimensions.x*0.4, cy+3.2), Color("a7e05c"), 2.2, true)
		"robot_runner":
			if kind == "leg":
				draw_arc(Vector2(0, dimensions.y*0.25), 8, 0.4, 2.7, 10, Color("facc15"), 2.5, true)
		"robot_tesla":
			for ring_y in [-5, 5]:
				LabSurface.line(self, Vector2(-dimensions.x/2-1, ring_y), Vector2(dimensions.x/2+1, ring_y), Color("74c6de"), 2, true)
		"robot_medic":
			LabSurface.rect(self, Rect2(-dimensions.x/2, -4, dimensions.x, 8), Color("e8eff2"))
			LabSurface.line(self, Vector2(0, -3), Vector2(0, 3), Color("22c55e"), 1.5, true)
			LabSurface.line(self, Vector2(-3, 0), Vector2(3, 0), Color("22c55e"), 1.5, true)
		"robot_antigrav":
			LabSurface.circle(self, Vector2(0, dimensions.y*0.2), 2.8, Color("b55fe6"))
			LabArt.soft_glow(self, Vector2(0, dimensions.y*0.2), 6, Color(0.8,0.3,0.95,0.4), 0.6)
		"robot_magnet":
			var is_left = (part_index in [3, 4, 7, 8])
			var band_col = Color("b83b32") if is_left else Color("3269b8")
			LabSurface.line(self, Vector2(-dimensions.x/2, -2), Vector2(dimensions.x/2, -2), band_col, 2.5, true)
		"robot_bomber":
			LabSurface.plate(self, Rect2(-dimensions.x/2-1, -5, dimensions.x+2, 10), Color("291512"), 1, Color("703028"))
		"robot_acrobat":
			LabSurface.line(self, Vector2(-dimensions.x/2, 0), Vector2(-dimensions.x/2-4, 5), Color("db2777"), 2, true)
