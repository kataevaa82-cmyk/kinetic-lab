extends SceneTree

const Game = preload("res://scripts/main.gd")
const Face = preload("res://assets/lab-sans.ttf")
const Heavy = preload("res://assets/lab-sans-bold.ttf")

class Preview extends Node2D:
	var kind: String
	func _draw() -> void:
		LabArt.icon(self,kind,Vector2.ZERO,1.0)

class Sheet extends Node2D:
	var title: String
	var entries: Array
	var names: Array
	func _draw() -> void:
		draw_rect(Rect2(0,0,1600,1060),Color("0c1822"))
		draw_string(Heavy,Vector2(42,52),title,HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("edf8fa"))
		draw_string(Face,Vector2(44,80),"KINETIC LAB  /  MATERIAL & GEOMETRY STUDY",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("70baa9"))
		for i in range(entries.size()):
			var at = Vector2(34+(i%5)*310,108+(i/5)*232)
			LabArt.box(self,Rect2(at,Vector2(294,216)),Color("182c3a"),10,Color("314b5c"))
			draw_line(at+Vector2(14,175),at+Vector2(280,175),Color("304657"),1)
			draw_string(Heavy,at+Vector2(14,196),names[i],HORIZONTAL_ALIGNMENT_LEFT,260,14,Color("e4f3f5"))
			draw_string(Face,at+Vector2(14,211),entries[i],HORIZONTAL_ALIGNMENT_LEFT,260,10,Color("7f9dac"))

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size=Vector2i(1600,1060)
	root.content_scale_size=Vector2i.ZERO
	DirAccess.make_dir_recursive_absolute("res://artifacts/catalog-upgrade")
	var hud=load("res://scripts/hud.gd").new()
	var stub=Game.new()
	stub.lang="ru"
	hud.game=stub
	var count=0
	for category in Game.CATALOG:
		var items: Array = category[3]
		for page in range(ceili(float(items.size())/20.0)):
			var sheet=Sheet.new()
			sheet.title=category[1]+"  /  "+str(page+1)
			sheet.entries=items.slice(page*20,mini((page+1)*20,items.size()))
			for kind in sheet.entries: sheet.names.append(hud.item_label(kind))
			root.add_child(sheet)
			for i in range(sheet.entries.size()):
				var kind: String=sheet.entries[i]
				var preview=Preview.new()
				preview.kind=kind
				preview.position=Vector2(181+(i%5)*310,197+(i/5)*232)
				var bounds=Rect2(-44,-38,88,76)
				if kind in LabVehicle.KINDS:
					var s=LabVehicle.spec(kind)
					bounds=Rect2(s.hull[0][0],Vector2.ZERO)
					for poly in s.hull:
						for p in poly: bounds=bounds.expand(p)
					for w in s.wheels:
						bounds=bounds.expand(w[0]-Vector2.ONE*w[1]).expand(w[0]+Vector2.ONE*w[1])
				elif kind in LabParts.KINDS:
					var s=LabParts.SPECS[kind]
					bounds=Rect2(Vector2(-s.w,-s.h)*0.5,Vector2(s.w,s.h)).grow(12)
				var zoom=minf(2.1,minf(244.0/bounds.size.x,142.0/bounds.size.y))
				preview.scale=Vector2.ONE*zoom
				preview.position-=bounds.get_center()*zoom
				sheet.add_child(preview)
				count+=1
			await process_frame
			await RenderingServer.frame_post_draw
			var filename="res://artifacts/catalog-upgrade/%s-%02d.png" % [category[0],page+1]
			var error=root.get_texture().get_image().save_png(filename)
			assert(error==OK,"Save visual sheet: "+filename)
			sheet.queue_free()
			await process_frame
	print("CATALOG_VISUAL_OK items=",count," categories=",Game.CATALOG.size())
	hud.free()
	stub.free()
	quit()
