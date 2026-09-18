extends SceneTree

const OUTPUT = "res://artifacts/yandex-publish-2026-09-14"
var game: Node2D
var language = "ru"
var mobile_capture = false
var stills_only = false
var subjects: Array = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--promo-lang="): language = arg.get_slice("=", 1)
	mobile_capture = "--mobile-test" in OS.get_cmdline_user_args()
	stills_only = "--promo-stills" in OS.get_cmdline_user_args()
	_run.call_deferred()

func _setup_scene(index: int) -> void:
	game.clear_scene()
	subjects.clear()
	game.scene_name = ["sandbox", "tower", "flight", "relay", "chain"][index]
	game.arena.set_theme(["lab", "lab", "sky", "track", "lab"][index])
	game.camera_center = Vector2(730, 411)
	game.camera.position = game.camera_center
	game.camera.zoom = Vector2.ONE * (0.88 if mobile_capture else 1.16)
	game.catalog_open = false
	game.placing = false
	game.tool = "grab"
	game.toast = ""
	game.toast_time = 0
	match index:
		0:
			for i in range(5):
				var robot = game.spawn_item(["robot", "robot_titan", "robot_jumper", "robot_medic", "robot_tesla"][i], Vector2(440 + i * 140, 616))
				subjects.append(robot)
			game.spawn_item("ball", Vector2(320, 590))
			game.spawn_item("crate", Vector2(1120, 594))
		1:
			for y in range(5):
				for x in range(3): game.spawn_item("crate", Vector2(680 + x * 49, 596 - y * 47))
			subjects.append(game.spawn_item("ball", Vector2(370, 400)))
			game.spawn_item("robot_titan", Vector2(1040, 616))
		2:
			var platform = game.spawn_item("plank", Vector2(680, 470))
			var left = game.spawn_item("thruster", Vector2(630, 515))
			var right = game.spawn_item("thruster", Vector2(730, 515))
			game.make_link(platform, left)
			game.make_link(platform, right)
			subjects = [left, right]
			game.spawn_item("robot", Vector2(680, 457))
			game.spawn_item("balloon", Vector2(950, 550))
			game.spawn_item("robot_antigrav", Vector2(1030, 616))
		3:
			game.camera.zoom = Vector2.ONE * (0.72 if mobile_capture else 1.0)
			subjects.append(game.spawn_item("car_monster", Vector2(450, 540)))
			game.spawn_item("robot_scout", Vector2(1100, 616))
			for i in range(4): game.spawn_item("crate", Vector2(730 + i * 55, 596))
			for i in range(2): game.spawn_item("crate", Vector2(760 + i * 55, 548))
		4:
			for i in range(6): subjects.append(game.spawn_item("barrel", Vector2(420 + i * 102, 590)))
			for i in range(3): game.spawn_item("crate", Vector2(650 + i * 48, 515))
			game.spawn_item("robot_titan", Vector2(1130, 616))
	game.select(null)
	game.hud.queue_redraw()

func _events(index: int, frame: int) -> void:
	match index:
		0:
			if frame == 25: subjects[2].process_ability()
			if frame == 92: subjects[2].ability_cooldown = 0; subjects[2].process_ability()
		1:
			if frame == 35: subjects[0].apply_central_impulse(Vector2(9000, -1000))
		2:
			if frame == 24:
				for thruster in subjects: thruster.active = true
			if frame == 72:
				for thruster in subjects:
					if is_instance_valid(thruster): thruster.active = false
		3:
			if frame == 25: LabVehicle.set_gear(subjects[0], 1)
			if frame == 105: LabVehicle.set_gear(subjects[0], 0)
		4:
			if frame == 58 and is_instance_valid(subjects[0]): subjects[0].damage(200, Vector2.ZERO)

func _run() -> void:
	seed(20260914)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i.ZERO
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	game.lang_override = language
	game._apply_language()
	game.stats.clear()
	game.completed.clear()
	game.muted = false
	game.menu_open = false
	game._update_pause()
	await process_frame
	var folder = OUTPUT + "/" + language + ("/mobile-screenshots" if mobile_capture else "/desktop-screenshots")
	DirAccess.make_dir_recursive_absolute(folder)
	var frames_folder = OUTPUT + "/sources/frames-" + language
	if not stills_only: DirAccess.make_dir_recursive_absolute(frames_folder)
	# Include the object catalog in the publication set. It occupies less than
	# 30% of the frame, so the screenshot still satisfies the gameplay-area rule.
	_setup_scene(0)
	game.catalog_open = true
	game.catalog_category = 0
	game.catalog_page = 0
	game.placing = true
	game.spawn_kind = "robot_titan"
	for warmup in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var catalog_picture = root.get_texture().get_image()
	catalog_picture.convert(Image.FORMAT_RGB8)
	var catalog_destination = "%s/00-catalog.png" % folder
	var catalog_error = catalog_picture.save_png(catalog_destination)
	if catalog_error != OK: push_error("Screenshot save failed: " + catalog_destination); quit(1); return
	for scene_index in range(2 if mobile_capture else 5):
		_setup_scene(scene_index)
		for frame in range(150):
			_events(scene_index, frame)
			await process_frame
			await RenderingServer.frame_post_draw
			# The movie writer fixes its viewport size before this tool resizes
			# the window. Save the actual 16:9 viewport frames for the final encode.
			if not stills_only:
				var frame_image = root.get_texture().get_image()
				frame_image.convert(Image.FORMAT_RGB8)
				var frame_error = frame_image.save_jpg("%s/frame-%04d.jpg" % [frames_folder, scene_index * 150 + frame], 0.97)
				if frame_error != OK: push_error("Video frame save failed"); quit(1); return
			if frame == [25, 53, 44, 64, 63][scene_index]:
				var picture = root.get_texture().get_image()
				picture.convert(Image.FORMAT_RGB8)
				var destination = "%s/%02d-%s.png" % [folder, scene_index + 1, ["robots", "physics", "flight", "vehicles", "chain-reaction"][scene_index]]
				var error = picture.save_png(destination)
				if error != OK: push_error("Screenshot save failed: " + destination); quit(1); return
			if stills_only and frame >= 80: break
	print("PUBLICATION_CAPTURE_OK language=", language, " mobile=", mobile_capture)
	quit()
