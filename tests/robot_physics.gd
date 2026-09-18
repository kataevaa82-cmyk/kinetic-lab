extends SceneTree

var game: Node2D
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func reset() -> void:
	game.clear_scene()
	await frames(2)

func robot_at(point: Vector2, variant: String = "robot") -> LabRobot:
	return game.spawn_item(variant, point)

func platform_at(point: Vector2) -> StaticBody2D:
	var body = StaticBody2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(240, 20)
	var collision = CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	body.position = point
	game.world.add_child(body)
	return body

func report(robot: LabRobot, label: String) -> void:
	print(label, " hp=", robot.health, " torso=", robot.parts[1].global_position,
		" floor=", robot.is_on_floor(), " support=", robot.support_height,
		" settled=", robot.corpse_settled, " speed=", robot.parts[1].linear_velocity.length())

func _run() -> void:
	seed(42)
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.muted = true
	await frames(2)
	game.menu_open = false
	game._update_pause()
	await reset()
	var standing = robot_at(Vector2(500, 616))
	await frames(240)
	report(standing, "standing")
	check(standing.health == standing.max_health, "Standing causes no damage")
	check(standing.is_on_floor() and absf(standing.parts[1].global_position.y - 508) < 20, "Standing posture uses actual floor")

	await reset()
	var platform = platform_at(Vector2(500, 440))
	var supported = robot_at(Vector2(500, 426))
	await frames(180)
	report(supported, "platform")
	check(supported.is_on_floor() and absf(supported.parts[1].global_position.y - 318) < 20, "Robot stands on an elevated platform")
	var old_y = supported.parts[1].global_position.y
	platform.position.x += 400
	await frames(50)
	check(supported.parts[1].global_position.y > old_y + 40, "Living robot falls when platform moves away")
	platform.queue_free()

	await reset()
	var low = robot_at(Vector2(350, 600))
	var high = robot_at(Vector2(750, 200))
	check(not high.is_on_floor(), "Airborne robot has no support")
	await frames(120)
	report(low, "low drop")
	report(high, "high drop")
	check(low.health == low.max_health, "Small drop is harmless")
	check(high.health < high.max_health, "Hard landing causes damage even shortly after spawning")

	await reset()
	var sliding = robot_at(Vector2(500, 600))
	sliding.stun = 10.0
	for body in sliding.parts: body.linear_velocity = Vector2(700, 0)
	await frames(18)
	check(sliding.health == sliding.max_health, "Fast horizontal sliding does not count as a hard landing")

	await reset()
	var falling_swing = robot_at(Vector2(500, 200))
	falling_swing.act = "recoil"
	falling_swing.act_time = 5.0
	await frames(100)
	check(falling_swing.health < falling_swing.max_health, "Weapon animation does not prevent fall damage")

	await reset()
	var bullet_target = robot_at(Vector2(750, 616))
	await frames(30)
	game._spawn_projectile("slug", Vector2(500, 508), Vector2(1500, 0), 18.0, null)
	await frames(16)
	check(is_equal_approx(bullet_target.health, 82.0), "Projectile damage is applied once without extra collision damage")

	await reset()
	var shooter = robot_at(Vector2(520, 616))
	var pistol = game.spawn_item("pistol", Vector2(400, 500))
	game.equip_gun(shooter, pistol, false)
	game.select(shooter.parts[1])
	game.cursor = shooter.palm() + Vector2(260, -110)
	for i in range(8): shooter.hold_weapon_pose(0.05)
	game.select(null)
	await frames(22)
	game.fire_weapon(pistol)
	await frames(24)
	report(shooter, "shooter")
	check(shooter.health == shooter.max_health and shooter.held_gun == pistol, "Aiming and firing preserve the shooter and its arm joints")
	game.save_snapshot()
	game.restore_snapshot(game.cached_scene.duplicate(true))
	shooter = get_nodes_in_group("robots")[0]
	check(is_instance_valid(shooter.held_gun) and shooter.held_gun.kind == "pistol", "Held firearm survives save and load after firing")

	await reset()
	var titan = robot_at(Vector2(500, 616), "robot_titan")
	titan.hurt(55)
	check(not titan.dead and titan.health == 225, "General damage cannot randomly sever a vital joint")
	titan.parts[4].damage(55, Vector2.ZERO)
	check(not titan.dead and titan.health == 170 and titan.is_part_attached(4), "Joint damage respects variant durability")
	var victim = robot_at(Vector2(850, 616))
	victim.parts[4].damage(55, Vector2.ZERO)
	check(not victim.dead and not victim.is_part_attached(4) and victim.is_part_attached(0) and victim.is_part_attached(6), "Heavy hit severs only the struck limb")
	check(victim.parts[4].can_sleep, "Detached limb can settle independently")
	var hp = victim.health
	victim.parts[4].damage(1000, Vector2(500, 0))
	check(victim.health == hp and not victim.dead, "Detached limb damage does not hurt the robot")
	victim.parts[4].charge = 1.0
	victim.parts[4]._run_charge(0.1)
	victim.parts[4].burning = 2.0
	victim.parts[4]._run_fire(0.1)
	check(victim.health == hp and victim.shock_guard == 0.0, "Detached burning or electrified limb cannot damage the robot")
	victim.fire_source = victim.parts[4]
	victim.parts[1].burning = 2.0
	victim.parts[1]._run_fire(0.1)
	check(victim.health < hp, "Detached fire source cannot suppress fire damage to the torso")
	var detached_velocity = victim.parts[4].linear_velocity
	victim.apply_knockback(Vector2(1000, 0))
	check(victim.parts[4].linear_velocity.is_equal_approx(detached_velocity), "Knockback does not move detached limbs")

	await reset()
	var repaired = robot_at(Vector2(500, 400))
	repaired.dismember_joint(0)
	await frames(30)
	var torso_position = repaired.parts[1].global_position
	repaired.restore()
	check(repaired.is_part_attached(0) and not repaired.dead, "Repair reattaches the head")
	check(repaired.parts[1].global_position.distance_to(torso_position) < 0.1, "Neck repair keeps torso in place")
	check(repaired.parts[0].global_position.distance_to(repaired.parts[1].global_transform * Vector2(0, -38)) < 0.1, "Repaired head follows current torso pose")

	await reset()
	var armed = robot_at(Vector2(500, 616))
	var right_gun = game.spawn_item("pistol", Vector2(550, 480))
	var left_gun = game.spawn_item("sword", Vector2(450, 480))
	check(game.equip_gun(armed, right_gun, false) and game.equip_gun_left(armed, left_gun, false), "Both hands can hold weapons before death")
	armed.die()
	check(not is_instance_valid(armed.held_gun) and not is_instance_valid(armed.held_gun_left) and not is_instance_valid(right_gun.holder) and not is_instance_valid(left_gun.holder), "Death releases both weapons")

	await reset()
	var fighter = robot_at(Vector2(620, 616))
	var hammer = game.spawn_item("hammer", Vector2(520, 580))
	game.equip_gun(fighter, hammer, false)
	var target = robot_at(Vector2(750, 616))
	await frames(30)
	var target_x = target.parts[1].global_position.x
	game.fire_weapon(hammer)
	await frames(21)
	report(fighter, "hammer fighter")
	report(target, "hammer target")
	check(target.health < target.max_health and (target.parts[1].global_position.x > target_x + 40 or target.parts[1].linear_velocity.x > 200), "Hammer hit damages and launches a robot")
	check(fighter.health == fighter.max_health and fighter.is_on_floor(), "Hammer swing does not damage or launch its holder")

	await reset()
	var corpse = robot_at(Vector2(500, 616))
	await frames(120)
	corpse.die()
	await frames(360)
	report(corpse, "corpse")
	check(corpse.corpse_settled, "Corpse comes to rest")
	check(corpse.parts[1].global_position.y > 570, "Dead robot collapses instead of sleeping upright")
	check(corpse.parts.all(func(b): return not b.freeze), "Resting corpse stays a dynamic body")
	corpse.parts[1].damage(1, Vector2(1000, -500))
	await frames(2)
	check(not corpse.corpse_settled and corpse.parts[1].linear_velocity.length() > 20, "Impact wakes a resting corpse")

	await reset()
	platform = platform_at(Vector2(500, 420))
	corpse = robot_at(Vector2(500, 406))
	corpse.die()
	await frames(360)
	check(corpse.corpse_settled, "Corpse settles on platform")
	old_y = corpse.parts[1].global_position.y
	platform.position.x += 400
	await frames(60)
	check(corpse.parts[1].global_position.y > old_y + 40, "Sleeping corpse falls after platform moves without deletion")
	platform.queue_free()

	await reset()
	corpse = robot_at(Vector2(500, -850))
	corpse.die()
	corpse.dismember_joint(7)
	corpse.parts[8].global_position = Vector2(950, 600)
	corpse.parts[8].linear_velocity = Vector2.ZERO
	await frames(190)
	check(not corpse.corpse_settled and not corpse.parts[1].freeze and corpse.parts[1].linear_velocity.y > 100, "Detached limb on floor cannot stop a corpse still falling after three seconds")

	await reset()
	var saved = robot_at(Vector2(500, 616))
	saved.dismember_joint(2)
	game.save_snapshot()
	game.restore_snapshot(game.cached_scene.duplicate(true))
	saved = get_nodes_in_group("robots")[0]
	check(not saved.is_part_attached(3) and not saved.is_part_attached(4), "Save/load preserves detached limbs")
	check(saved.parts[1] not in saved.parts[3].get_collision_exceptions() and saved.parts[4] in saved.parts[3].get_collision_exceptions(), "Save/load restores collision groups of separated parts")
	hp = saved.health
	saved.parts[4].damage(50, Vector2.ZERO)
	check(saved.health == hp, "Loaded detached limb remains independent")
	saved.restore()
	check(saved.is_part_attached(4) and saved.parts[1] in saved.parts[3].get_collision_exceptions(), "Repair restores the complete limb chain and its collision exceptions")

	await reset()
	var frozen = robot_at(Vector2(500, 400))
	frozen.inject_freeze()
	frozen.parts[1].damage(5, Vector2(1000, -500))
	check(frozen.parts.all(func(b): return b.freeze), "Damage preserves explicit freezing")
	frozen.die()
	frozen.wake_for(1)
	check(frozen.parts.all(func(b): return b.freeze), "Corpse wake preserves explicit freezing")

	await reset()
	var stretched = robot_at(Vector2(500, 400))
	stretched.parts[4].position.x += 200
	stretched._physics_process(0.0)
	check(not stretched.is_part_attached(4), "Excessive joint separation breaks the actual joint")

	print("ROBOT_PHYSICS_TESTS: ", "PASS" if failures == 0 else "FAIL", " failures=", failures)
	game.queue_free()
	await frames(2)
	quit(0 if failures == 0 else 1)
