extends SceneTree

const Game = preload("res://scripts/main.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size=Vector2i(1600,1000)
	var game=Game.new()
	game.test_mode=true
	root.add_child(game)
	await process_frame
	await process_frame
	game.muted=true
	game.menu_open=false
	game.user_paused=true
	game.catalog_open=false
	game._update_pause()
	game.hud.hide()
	var stages=[
		["robots-a",Game.ROBOTS.slice(0,6)],
		["robots-b",Game.ROBOTS.slice(6,11)],
		["materials",["anvil","crystal","slime","soap","pillow","rubber","tire","gel"]],
		["machines",["magnet","fan","coil","conveyor","thruster","metronome","trampoline"]],
		["elements",["water_pool","oil_pool","acid_pool","gas_can","battery"]],
		["fleet",["car_sedan","car_monster","car_moto","car_heli"]]
	]
	for stage in stages:
		game.clear_scene()
		await process_frame
		var items: Array=stage[1]
		var anchors=[]
		for i in range(items.size()):
			var x=lerpf(220.0,1100.0,float(i)/float(maxi(1,items.size()-1)))
			var item=game.spawn_item(items[i],Vector2(x,game.FLOOR_Y-4))
			assert(item!=null,"Preview item spawned: "+items[i])
			if item is LabBody:
				item.position.y=game.FLOOR_Y-item.dimensions.y*0.5
			anchors.append(item)
		game.camera_center=Vector2(660,445)
		game.camera.position=game.camera_center
		game.camera.zoom=Vector2.ONE*1.08
		# Actual silhouettes and collision coverage, including the hollow magnet.
		for body in get_nodes_in_group("bodies"):
			assert(is_finite(body.position.x) and is_finite(body.position.y))
			if body.kind in LabGeometry.SHAPED:
				var pieces=Geometry2D.decompose_polygon_in_convex(LabGeometry.outline(body.kind,body.dimensions))
				assert(not pieces.is_empty(),"Valid collision polygon: "+body.kind)
				for child in body.get_children():
					if child is CollisionShape2D: assert(child.shape!=null)
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://artifacts/catalog-upgrade/world-"+stage[0]+".png")==OK)
		print("WORLD_GEOMETRY_OK ",stage[0]," bodies=",get_nodes_in_group("bodies").size())
	print("VISUAL_GEOMETRY_OK")
	quit()
