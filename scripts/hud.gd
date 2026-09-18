extends Control

# Порядок вкладок каталога. Индексы перечислены руками, поэтому новая
# категория в CATALOG обязана появиться и здесь, иначе её просто не видно.
# Покрытие проверяется в --smoke-test.
const CATEGORY_ROW_TOP=[0,8,1,3,2,10]
const CATEGORY_ROW_BOTTOM=[5,7,6,4,9,11]

var game: Node2D
var font: Font=preload("res://assets/lab-sans.ttf")
var bold: Font=preload("res://assets/lab-sans-bold.ttf")
var hits: Array[Dictionary]=[]
var panels: Array[Rect2]=[]
var sw=1280.0
var sh=800.0
var side=216.0
var top=66.0
var bottom=44.0
var hover=""
var hovered_kind=""
var hovered_rect=Rect2()
var _str_cache: Dictionary = {}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _measure_str(face: Font, text: String, sz: int) -> Vector2:
	var k = (1 if face == bold else 0) * 1000 + sz
	var m: Dictionary = _str_cache.get(k, {})
	if m.is_empty():
		_str_cache[k] = m
	if m.has(text):
		return m[text]
	var s = face.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz)
	m[text] = s
	return s

func txt(at: Vector2, value: String, size_value: int=14, color: Color=LabArt.TEXT, heavy: bool=false, width: float=-1) -> void:
	draw_string(bold if heavy else font,at,value,HORIZONTAL_ALIGNMENT_LEFT,width,size_value,color)

func center(rect: Rect2, value: String, size_value: int=14, color: Color=LabArt.TEXT, heavy: bool=false) -> void:
	if value.is_empty(): return
	var face = bold if heavy else font
	var target_w = maxf(10.0, rect.size.x - 8.0)
	var sz = size_value
	var text_size = _measure_str(face, value, sz)
	while text_size.x > target_w and sz > 7:
		sz -= 1
		text_size = _measure_str(face, value, sz)
	var x_pos = maxf(rect.position.x + 3.0, rect.position.x + (rect.size.x - text_size.x) / 2.0)
	var y_pos = rect.position.y + (rect.size.y + sz * 0.7) / 2.0
	txt(Vector2(x_pos, y_pos), value, sz, color, heavy, target_w)

func trr(ru: String,en: String) -> String:
	return game.t(ru,en)

func panel(rect: Rect2, color: Color=LabArt.PANEL, border: bool=true) -> void:
	LabArt.box(self,Rect2(rect.position+Vector2(0,5),rect.size),Color(0.0,0.0,0.0,0.36),8)
	LabArt.box(self,rect,color,8,LabArt.LINE if border else Color.TRANSPARENT)
	if border:
		draw_line(rect.position+Vector2(9,1),rect.position+Vector2(rect.size.x-9,1),Color(0.65,0.90,0.94,0.13),1)
		draw_line(rect.position+Vector2(9,rect.size.y-1),rect.position+Vector2(rect.size.x-9,rect.size.y-1),Color(0.0,0.02,0.04,0.30),1)
	panels.append(rect)

func button(id: String, rect: Rect2, label: String, selected: bool=false, small: bool=false, color: Color=LabArt.TEAL) -> void:
	var over=rect.has_point(get_viewport().get_mouse_position())
	var bg=Color("23504a") if selected else (Color("2b4050") if over else Color("1b2c39"))
	LabArt.box(self,rect,bg,6,color if selected else LabArt.LINE)
	if selected:
		LabArt.soft_glow(self,rect.get_center(),minf(rect.size.x,rect.size.y)*0.55,Color(color.r,color.g,color.b,0.2),0.5)
		draw_line(rect.position+Vector2(7,1),rect.position+Vector2(rect.size.x-7,1),Color(color.r,color.g,color.b,0.42),1)
	elif over:
		draw_line(rect.position+Vector2(7,1),rect.position+Vector2(rect.size.x-7,1),Color(0.7,0.9,0.95,0.18),1)
	center(rect,label,11 if small else 13,color if selected else LabArt.TEXT,selected)
	hits.append({"id":id,"rect":rect})

func tool_label(kind: String) -> String:
	match kind:
		"grab": return trr("Захват","Grab")
		"pulse": return trr("Импульс","Pulse")
		"blast": return trr("Взрыв","Blast")
		"freeze": return trr("Стоп","Freeze")
		"link": return trr("Связь","Link")
		"delete": return trr("Удалить","Delete")
		"clear_scene","clear": return trr("Очистка","Clear")
		"pan": return trr("Камера","Camera")
	return kind

func _item_tooltip() -> void:
	if game.mobile or not game.catalog_open or game.menu_open or game.help_open: return
	var about=item_about(hovered_kind)
	if about=="": return
	var wrapped=_wrap(about,214.0,11)
	var height=34+wrapped.size()*16
	var at=Vector2(side+12,clampf(hovered_rect.position.y-8,top+8,sh-bottom-height-20))
	panel(Rect2(at,Vector2(238,height)))
	txt(at+Vector2(14,22),item_label(hovered_kind).to_upper(),10,LabArt.TEAL,true)
	for i in range(wrapped.size()):
		txt(at+Vector2(14,42+i*16),wrapped[i],11,LabArt.TEXT)

func item_about(kind: String) -> String:
	if kind=="" or not game.ITEM_ABOUT.has(kind): return ""
	var about=game.ITEM_ABOUT[kind]
	return trr(str(about[0]),str(about[1]))

func _wrap(value: String, width: float, size_value: int) -> PackedStringArray:
	# The fallback font has no wrapping helper, so lines are measured by hand.
	var lines=PackedStringArray()
	var line=""
	for word in value.split(" "):
		var candidate=word if line=="" else line+" "+word
		if font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value).x>width and line!="":
			lines.append(line)
			line=word
		else:
			line=candidate
	if line!="": lines.append(line)
	return lines

func item_label(kind: String) -> String:
	match kind:
		"robot","head","torso","pelvis","arm","leg": return trr("Робот","Robot")
		"robot_scout": return trr("Разведчик","Scout")
		"robot_titan": return trr("Титан","Titan")
		"robot_jumper": return trr("Прыгун","Jumper")
		"robot_magnet": return trr("Магнетрон","Magnetron")
		"robot_tesla": return trr("Искровик","Sparkbot")
		"robot_bomber": return trr("Подрывник","Bomber")
		"robot_medic": return trr("Ремонтник","Repairbot")
		"robot_antigrav": return trr("Антиграв","Antigrav")
		"robot_runner": return trr("Бегун","Runner")
		"robot_acrobat": return trr("Акробат","Acrobat")
		"crate": return trr("Ящик","Crate")
		"barrel": return trr("Бочка","Barrel")
		"ball": return trr("Стальной шар","Steel ball")
		"plank": return trr("Балка","Plank")
		"metal": return trr("Металл","Metal")
		"thruster": return trr("Двигатель","Thruster")
		"mine": return trr("Мина","Mine")
		"magnet": return trr("Магнит","Magnet")
		"fan": return trr("Вентилятор","Fan")
		"coil": return trr("Разрядник","Tesla coil")
		"sticky": return trr("Липкая бомба","Sticky bomb")
		"glass": return trr("Стекло","Glass")
		"trampoline": return trr("Батут","Trampoline")
		"bumper": return trr("Бампер","Bumper")
		"weight": return trr("Груз","Weight")
		"balloon": return trr("Шар","Balloon")
		"wheel": return trr("Мотор-колесо","Motor wheel")
		"pistol": return trr("Пистолет","Pistol")
		"revolver": return trr("Револьвер","Revolver")
		"rifle": return trr("Винтовка","Rifle")
		"shotgun": return trr("Дробовик","Shotgun")
		"sawed": return trr("Обрез","Sawed-off")
		"nailgun": return trr("Гвоздомёт","Nailgun")
		"grenade": return trr("Граната","Grenade")
		"turret": return trr("Турель","Turret")
		"drone": return trr("Дрон","Drone")
		"flak": return trr("Противодрон","Flak gun")
		"railgun": return trr("Рельса","Railgun")
		"crossbow": return trr("Арбалет","Crossbow")
		"rocket_gun": return trr("Ракетница","Rocket")
		"flamer": return trr("Огнемёт","Flamethrower")
		"freezer": return trr("Мороз","Freeze ray")
		"tesla_gun": return trr("Тесла","Tesla gun")
		"harpoon": return trr("Гарпун","Harpoon")
		"glue_gun": return trr("Клей","Glue gun")
		"bouncer": return trr("Рикошет","Ricochet")
		"cannon": return trr("Пушка","Cannon")
		"minigun": return trr("Миниган","Minigun")
		"pulse_gun": return trr("Волна","Wave gun")
		"grapple": return trr("Кошка","Grapple")
		"mine_gun": return trr("Миномёт","Mine launcher")
		"balloon_gun": return trr("Шаромёт","Balloon gun")
		"vortex": return trr("Вихрь","Vortex")
		"disc_gun": return trr("Дискомёт","Disc gun")
		"taser": return trr("Тазер","Taser")
		"cluster": return trr("Кассета","Cluster")
		"wind_gun": return trr("Ветромёт","Wind gun")
		"sword": return trr("Меч","Sword")
		"axe": return trr("Топор","Axe")
		"spear": return trr("Копьё","Spear")
		"hammer": return trr("Молот","Hammer")
		"knife": return trr("Нож","Knife")
		"katana": return trr("Катана","Katana")
		"scythe": return trr("Коса","Scythe")
		"mace": return trr("Булава","Mace")
		"chainsaw": return trr("Пила","Chainsaw")
		"bat": return trr("Бита","Bat")
		"whip": return trr("Кнут","Whip")
		"plasma_blade": return trr("Плазма","Plasma blade")
		"crowbar": return trr("Лом","Crowbar")
		"halberd": return trr("Алебарда","Halberd")
		"hook": return trr("Багор","Hook")
		"syringe_life": return trr("Жизнь","Life")
		"syringe_acid": return trr("Кислота","Acid")
		"syringe_nitro": return trr("Нитро","Nitro")
		"syringe_overclock": return trr("Оверклок","Overclock")
		"syringe_freeze": return trr("Крио","Cryo")
	if kind.begins_with("virus_"): return game.virus_label(kind)
	if game.ITEM_NAMES.has(kind):
		var n=game.ITEM_NAMES[kind]
		return trr(str(n[0]),str(n[1]))
	return trr("Обломок","Debris")

func handle_click(point: Vector2) -> bool:
	for i in range(hits.size()-1,-1,-1):
		if hits[i].rect.has_point(point):
			game.action(hits[i].id)
			return true
	return blocks(point)

func blocks(point: Vector2) -> bool:
	if game.menu_open or game.help_open or game.platform.suspended: return true
	for rect in panels:
		if rect.has_point(point): return true
	for hit in hits:
		if hit.rect.has_point(point): return true
	return false

func _draw() -> void:
	if not is_instance_valid(game): return
	sw=get_viewport_rect().size.x
	sh=get_viewport_rect().size.y
	side=160 if game.mobile else 216
	top=54 if game.mobile else 66
	bottom=28 if game.mobile else 36
	hits.clear()
	panels.clear()
	hovered_kind=""
	_topbar()
	if game.catalog_open: _catalog()
	_workspace()
	_toolbar()
	_statusbar()
	if not game.mobile: _inspector()
	if game.toast_time>0 and not game.menu_open:
		var width=minf(sw-40,font.get_string_size(game.toast,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+40)
		var rect=Rect2((sw-width)/2,top+12,width,40)
		LabArt.box(self,rect,Color("244941"),7,LabArt.TEAL)
		center(rect,game.toast,14,LabArt.TEXT)
	if game.user_paused and not game.menu_open:
		var r=Rect2(sw/2-95,top+65,190,34)
		LabArt.box(self,r,Color("4a3829"),6,LabArt.AMBER)
		center(r,trr("ФИЗИКА НА ПАУЗЕ","PHYSICS PAUSED"),12,LabArt.AMBER)
	_item_tooltip()
	if game.menu_open: _menu()
	if game.help_open: _help()
	if game.platform.suspended and not game.menu_open:
		draw_rect(Rect2(0,0,sw,sh),Color(0.025,0.04,0.06,0.55))
		center(Rect2(0,sh/2-20,sw,40),trr("Пауза","Paused"),30,LabArt.TEXT,true)

func _topbar() -> void:
	panel(Rect2(-8,-8,sw+16,top+8),Color("0f1b27"),false)
	draw_line(Vector2(0,top),Vector2(sw,top),LabArt.LINE)
	LabArt.box(self,Rect2(17,15,30,30),LabArt.TEAL,7)
	LabArt.soft_glow(self,Vector2(32,30),22,Color(0.3,1.0,0.8,0.32),0.8)
	txt(Vector2(23,38),"K",22,LabArt.BG,true)
	txt(Vector2(57,32),"KINETIC LAB",19 if game.mobile else 20,LabArt.TEXT,true)
	if not game.mobile and sw >= 760: txt(Vector2(58,49),trr("ЛАБОРАТОРИЯ ФИЗИКИ","PHYSICS SANDBOX"),9,LabArt.MUTED)
	var x=205.0 if game.mobile else (220.0 if sw < 880 else 246.0)
	button("menu",Rect2(x,12,72,top-24),trr("Сцены","Scenes"),false,true)
	button("catalog",Rect2(x+78,12,84,top-24),trr("Объекты","Objects"),game.catalog_open,true)
	var right_space=sw-(x+168.0)
	var bw=46.0 if game.mobile else 52.0
	var btn_gap=6.0
	if right_space < (bw+btn_gap)*6.0+18.0:
		bw=clampf((right_space-18.0)/6.0-btn_gap,32.0,52.0)
		btn_gap=clampf((right_space-18.0-bw*6.0)/5.0,2.0,6.0)
	var start=sw-(bw+btn_gap)*6-14
	button("pause",Rect2(start,10,bw,top-20),">" if game.user_paused else "II",game.user_paused)
	button("slow",Rect2(start+(bw+btn_gap),10,bw,top-20),"¼×" if game.slow else "1×",game.slow)
	button("gravity",Rect2(start+(bw+btn_gap)*2,10,bw,top-20),"G",game.gravity)
	button("mute",Rect2(start+(bw+btn_gap)*3,10,bw,top-20),trr("Звук","SFX") if not game.muted else trr("Тихо","Off"),not game.muted,true)
	button("lang",Rect2(start+(bw+btn_gap)*4,10,bw,top-20),"RU" if game.lang=="ru" else "EN",false,true)
	button("help",Rect2(start+(bw+btn_gap)*5,10,bw,top-20),"?",game.help_open)

func _catalog() -> void:
	panel(Rect2(-8,top,side+8,sh-top-bottom),Color("11202c"),false)
	draw_line(Vector2(side,top),Vector2(side,sh-bottom),LabArt.LINE)
	txt(Vector2(18,top+29),trr("КАТАЛОГ","CATALOG"),11,LabArt.MUTED,true)
	var cats=game.CATALOG
	game.catalog_category=clampi(game.catalog_category,0,cats.size()-1)
	var items=game.catalog_items()
	txt(Vector2(side-41,top+29),str(items.size()),11,LabArt.TEAL)
	var tab_y=top+34
	var tab_h=23.0 if game.mobile else 25.0
	var tab_gap=4.0
	var cat_icons={
		0: "robot",
		1: "virus_rage",
		2: "crate",
		3: "thruster",
		4: "rubber",
		5: "pistol",
		6: "tesla_gun",
		7: "sword",
		8: "syringe_life",
		9: "water_pool",
		10: "car_sedan",
		11: "c_girder"
	}
	var row1=CATEGORY_ROW_TOP
	var row2=CATEGORY_ROW_BOTTOM
	var total_w=side-36
	for r_idx in range(2):
		var r_cats = row1 if r_idx==0 else row2
		var count = r_cats.size()
		var tab_w = (total_w - (count-1)*tab_gap) / count
		var ry = tab_y + r_idx * (tab_h + 3)
		for c_idx in range(count):
			var cat_i: int = r_cats[c_idx]
			var rect = Rect2(18 + c_idx * (tab_w + tab_gap), ry, tab_w, tab_h)
			var sel = cat_i == game.catalog_category
			var over = rect.has_point(get_viewport().get_mouse_position())
			LabArt.box(self, rect, Color("23504a") if sel else (Color("2b4050") if over else Color("1b2c39")), 5, LabArt.TEAL if sel else LabArt.LINE)
			var icon_kind: String = cat_icons.get(cat_i, "crate")
			LabArt.icon(self, icon_kind, rect.position + Vector2(tab_w/2, tab_h/2+1), 0.32 if game.mobile else 0.40, LabArt.TEAL if sel else LabArt.MUTED)
			hits.append({"id":"catalog_cat:"+str(cat_i), "rect":rect})

	var label_y = tab_y + (tab_h + 3) * 2 + 2
	center(Rect2(18, label_y, side-36, 16), trr(cats[game.catalog_category][1], cats[game.catalog_category][2]).to_upper(), 10, LabArt.TEAL, true)
	var gap=7.0 if game.mobile else 8.0
	var width=(side-36-gap)/2
	var start=label_y + 18
	var by=sh-bottom-50
	var page_size=game.catalog_page_size()
	var page_count=maxi(1,(items.size()+page_size-1)/page_size)
	game.catalog_page=clampi(game.catalog_page,0,page_count-1)
	var first=game.catalog_page*page_size
	var last=mini(first+page_size,items.size())
	var visible_count=maxi(0,last-first)
	var rows=maxi(1,(visible_count+1)/2)
	var available=by-start-6
	if page_count>1: available-=33
	var ch=clampf(available/rows-gap,54.0 if game.mobile else 72.0,68.0 if game.mobile else 88.0)
	for slot in range(visible_count):
		var kind=items[first+slot]
		var rect=Rect2(18+(slot%2)*(width+gap),start+(slot/2)*(ch+gap),width,ch)
		var sel=game.placing and game.spawn_kind==kind
		var over=rect.has_point(get_viewport().get_mouse_position())
		if over or (sel and hovered_kind==""):
			hovered_kind=kind
			hovered_rect=rect
		LabArt.box(self,rect,Color("224943") if sel else (Color("293d4b") if over else Color("192936")),7,LabArt.TEAL if sel else Color("355064"))
		LabArt.icon(self,kind,rect.position+Vector2(width/2,ch*0.38),0.48 if game.mobile else 0.64)
		center(Rect2(rect.position+Vector2(1,ch-22),Vector2(width-2,20)),item_label(kind),8 if game.mobile else 10)
		if sel: draw_circle(rect.position+Vector2(width-9,9),3,LabArt.TEAL)
		hits.append({"id":"item:"+kind,"rect":rect})
	var below=start+rows*(ch+gap)+2
	if page_count>1:
		button("catalog_prev",Rect2(18,below,36,29),"‹",game.catalog_page>0,true)
		center(Rect2(59,below,side-118,29),str(game.catalog_page+1)+" / "+str(page_count),10,LabArt.MUTED,true)
		button("catalog_next",Rect2(side-54,below,36,29),"›",game.catalog_page<page_count-1,true)
		below+=35
	# What the object is for. Paged categories get this too — the toy shelf is
	# exactly the one that needs explaining, and it always pages.
	if not game.mobile and below+96<by:
		var about=item_about(hovered_kind)
		draw_line(Vector2(18,below+6),Vector2(side-18,below+6),LabArt.LINE)
		if about!="":
			var wrapped=_wrap(about,side-36,10)
			txt(Vector2(18,below+30),item_label(hovered_kind).to_upper(),10,LabArt.TEAL,true)
			for i in range(mini(wrapped.size(),4)):
				txt(Vector2(18,below+52+i*16),wrapped[i],10,LabArt.MUTED)
		elif below+128<by:
			txt(Vector2(18,below+30),trr("ИЗ ЧЕГО НАЧАТЬ","QUICK START"),10,LabArt.MUTED,true)
			var steps=[trr("Выбери объект в каталоге","Choose an object above"),trr("Нажми в лаборатории","Click inside the laboratory"),trr("Экспериментируй!","See what happens!")]
			for i in range(3):
				draw_circle(Vector2(26,below+53+i*26),9,Color("233e3d"))
				txt(Vector2(23,below+57+i*26),str(i+1),10,LabArt.TEAL)
				txt(Vector2(43,below+57+i*26),steps[i],10,LabArt.MUTED)
	button("save",Rect2(14,by,(side-34)/2,36),trr("Сохранить","Save"),false,true)
	button("load",Rect2(20+(side-34)/2,by,(side-34)/2,36),trr("Загрузить","Load"),false,true)

func _workspace() -> void:
	var left=side+28 if game.catalog_open else 24.0
	if not game.mobile:
		draw_circle(Vector2(left+4,top+35),3,LabArt.TEAL)
		txt(Vector2(left+16,top+39),game.scene_title().to_upper(),10,LabArt.TEAL,true)
		txt(Vector2(left,top+75),trr("А что, если…","What happens if…"),27,LabArt.TEXT,true)
		txt(Vector2(left,top+100),trr("Создавай. Соединяй. Проверяй на прочность.","Build. Connect. Push the limits."),13,LabArt.MUTED)
	var x=sw-58
	var y=sh-bottom-200 if not game.mobile else top+14
	button("zoom_in",Rect2(x,y,42,38),"+")
	button("zoom_out",Rect2(x,y+44,42,38),"−")
	button("reset_view",Rect2(x,y+88,42,38),"◎")
	if game.mobile and is_instance_valid(game.selected):
		var labels=[trr("Пуск","Use"),trr("Стоп","Hold"),"↻",trr("Клон","Clone"),trr("Убр.","Del")]
		var ids=["activate","freeze","rotate","clone","delete"]
		for i in range(5): button(ids[i],Rect2(sw-60,top+130+i*40,46,34),labels[i],false,true)
		# У машины на телефоне «Пуск» перебирает передачи, а рядом — её действие.
		var car=LabVehicle.root(game.selected)
		if car: button("vehicle_ability",Rect2(sw-112,top+130,46,34),LabVehicle.ability_label(game,car),false,true)

func _toolbar() -> void:
	var slots = [
		{"type":"tool", "id":"grab", "key":"1"},
		{"type":"tool", "id":"pulse", "key":"2"},
		{"type":"tool", "id":"blast", "key":"3"},
		{"type":"tool", "id":"freeze", "key":"4"},
		{"type":"tool", "id":"link", "key":"5"},
		{"type":"tool", "id":"delete", "key":"6"},
		{"type":"action", "id":"clear_scene", "key":"Del"},
		{"type":"tool", "id":"pan", "key":"7"},
	]
	var width = 48.0 if game.mobile else (58.0 if sw < 1140 else 64.0)
	var gap = 4.0 if game.mobile else 5.0
	var total = (width + gap) * slots.size() + 14.0
	var available_left = side if game.catalog_open and not game.mobile else 0.0
	var available_right = (sw - 236.0) if (not game.mobile and is_instance_valid(game.selected)) else sw
	var available_w = maxf(total, available_right - available_left)
	var x = clampf(available_left + (available_w - total) / 2.0, available_left + 6.0, sw - total - 6.0)
	var y = sh - bottom - (73 if game.mobile else 96)
	panel(Rect2(x, y, total, 65 if game.mobile else 80), Color("101c27"))
	var mouse_p = get_viewport().get_mouse_position()
	for i in range(slots.size()):
		var slot = slots[i]
		var rect = Rect2(x + 7 + i * (width + gap), y + 7, width, 51 if game.mobile else 66)
		var is_over = rect.has_point(mouse_p)
		var is_tool = (slot.type == "tool")
		var kind: String = slot.id
		var sel = is_tool and (game.tool == kind and not game.placing)
		if sel or is_over:
			LabArt.box(self, rect, Color("23423e") if sel else Color("253441"), 5, LabArt.TEAL if sel else Color.TRANSPARENT)
		var text_col = LabArt.TEAL if (sel or is_over) else LabArt.MUTED
		LabArt.icon(self, kind, rect.position + Vector2(width / 2, 22 if not game.mobile else 19), 0.55 if game.mobile else 0.67, text_col)
		center(Rect2(rect.position + Vector2(0, 34 if not game.mobile else 29), Vector2(width, 20)), tool_label(kind), 9 if game.mobile else 10, text_col)
		if not game.mobile: txt(rect.position + Vector2(5, 12), slot.key, 8, Color("687e8e"))
		hits.append({"id": ("tool:" + kind) if is_tool else kind, "rect": rect})
	if not game.mobile:
		LabArt.box(self, Rect2(x + 8, y - 31, total - 16, 25), Color(0.055, 0.09, 0.13, 0.9), 5)
		center(Rect2(x, y - 30, total, 22), trr("WASD / ПКМ — камера   ·   Пробел — пауза   ·   Ctrl+D — клон   ·   Ctrl+Z — отмена   ·   Q/E — поворот","WASD / Right drag — cam   ·   Space — pause   ·   Ctrl+D — clone   ·   Ctrl+Z — undo   ·   Q/E — rotate"), 10, LabArt.MUTED)

func _statusbar() -> void:
	panel(Rect2(-8,sh-bottom,sw+16,bottom+8),Color("0c151e"),false)
	draw_line(Vector2(0,sh-bottom),Vector2(sw,sh-bottom),LabArt.LINE)
	var y=sh-bottom/2+4
	draw_circle(Vector2(20,y-4),3,LabArt.TEAL if not game.get_tree().paused else LabArt.AMBER)
	txt(Vector2(31,y),trr("ЛАБОРАТОРИЯ 01","LABORATORY 01"),9,LabArt.MUTED)
	var label=trr("Разместить: ","Place: ")+item_label(game.spawn_kind) if game.placing else tool_label(game.tool)
	var tw=_measure_str(font,label,10).x
	if not game.mobile:
		if sw >= 920:
			txt(Vector2(200,y),trr("ТЕЛА  ","BODIES  ")+str(game.get_tree().get_nodes_in_group("bodies").size())+" / "+str(game.MAX_BODIES),9,LabArt.MUTED)
			txt(Vector2(350,y),trr("МАСШТАБ  ","ZOOM  ")+str(int(game.camera.zoom.x*100))+"%",9,LabArt.MUTED)
			txt(Vector2(490,y),trr("ОТКРЫТИЯ  ","DISCOVERIES  ")+str(game.completed.size())+" / 8",9,LabArt.TEAL)
		elif sw >= 740:
			txt(Vector2(180,y),trr("ТЕЛА: ","BODIES: ")+str(game.get_tree().get_nodes_in_group("bodies").size()),9,LabArt.MUTED)
			txt(Vector2(280,y),trr("ОТКРЫТИЯ: ","DISC: ")+str(game.completed.size())+"/8",9,LabArt.TEAL)
	var max_w = clampf(sw - (590.0 if not game.mobile and sw >= 920 else (380.0 if not game.mobile and sw >= 740 else 160.0)), 120.0, 360.0)
	var rx = sw - minf(tw, max_w) - 20.0
	txt(Vector2(maxf(rx, sw * 0.45), y), label, 10, LabArt.TEAL, false, max_w)
	if game.mobile and game.placing:
		var about=item_about(game.spawn_kind)
		if about!="":
			var lines=_wrap(about,sw-260.0,9)
			if lines.size()>0:
				var aw=_measure_str(font,lines[0],9).x
				txt(Vector2(sw-aw-20,y-15),lines[0],9,LabArt.MUTED,false,sw-260.0)

func _inspector() -> void:
	var x=sw-226
	var y=top+22
	panel(Rect2(x,y,204,218),Color("111d28"))
	txt(Vector2(x+16,y+26),trr("СЛЕДУЮЩЕЕ ОТКРЫТИЕ","NEXT DISCOVERY"),10,LabArt.MUTED,true)
	var index=-1
	for i in range(game.GOALS.size()):
		if i not in game.completed: index=i; break
	if index>=0:
		var goal=game.GOALS[index]
		var value=mini(int(game.stats.get(goal[0],0)),goal[1])
		txt(Vector2(x+16,y+54),trr(goal[2],goal[3]),14,LabArt.TEXT,true)
		var verbs={"spawn":trr("Создай объекты","Spawn objects"),"pulse":trr("Примени импульс","Fire pulses"),"freeze":trr("Заморозь объекты","Freeze objects"),"link":trr("Создай соединения","Connect objects"),"crate":trr("Разрушь ящики","Break crates"),"explosion":trr("Устрой взрывы","Trigger explosions"),"launch":trr("Запусти двигатели","Activate thrusters")}
		txt(Vector2(x+16,y+81),verbs.get(goal[0],""),11,LabArt.MUTED)
		txt(Vector2(x+16,y+110),str(value)+" / "+str(goal[1]),13,LabArt.TEAL,true)
		LabArt.box(self,Rect2(x+16,y+124,172,5),Color("293c46"),2)
		if value>0: LabArt.box(self,Rect2(x+16,y+124,172*float(value)/goal[1],5),LabArt.TEAL,2)
	else:
		txt(Vector2(x+16,y+60),trr("Главный инженер","Chief engineer"),16,LabArt.TEAL,true)
		txt(Vector2(x+16,y+88),trr("Все открытия сделаны!","All discoveries complete!"),11,LabArt.MUTED)
	draw_line(Vector2(x+16,y+149),Vector2(x+188,y+149),LabArt.LINE)
	txt(Vector2(x+16,y+173),trr("Твоя лаборатория. Твои правила.","Your laboratory. Your rules."),10,LabArt.MUTED)
	txt(Vector2(x+16,y+195),trr("Прогресс сохраняется автоматически","Progress is saved automatically"),9,LabArt.MUTED)
	if is_instance_valid(game.selected):
		var b=game.selected
		y+=234
		var action_label=trr("Нет активации","No activation")
		var extra=""
		var car=LabVehicle.root(b)
		if car:
			# Машина: вместо одной кнопки — ряд передач и второе действие.
			b=car
			extra="vehicle"
		elif is_instance_valid(b.ragdoll):
			if b.ragdoll.dead: action_label=trr("Починить робота  [F]","Repair robot  [F]")
			elif is_instance_valid(b.ragdoll.held_gun):
				if b.ragdoll.held_gun.kind=="grenade": action_label=trr("Бросить  [F]","Throw  [F]")
				elif b.ragdoll.held_gun.kind=="chainsaw": action_label=trr("Пила  [F]","Saw  [F]")
				elif b.ragdoll.held_gun.kind in game.MELEE: action_label=trr("Удар  [F]","Strike  [F]")
				else: action_label=trr("Выстрел  [F]","Fire  [F]")
				extra="drop_gun"
			elif b.ragdoll.virus!="":
				action_label=(trr("Стоп поведение","Stop behavior") if b.ragdoll.active else trr("Старт поведение","Start behavior"))+"  [F]"
				extra="purge_virus"
			elif game.nearest_virus(b.global_position):
				action_label=trr("Ввести вирус  [F]","Inject virus  [F]")
			elif game.nearest_weapon(b.global_position):
				action_label=trr("Взять оружие  [F]","Equip weapon  [F]")
			else: action_label=(trr("Стоп жизнь","Stop life") if b.ragdoll.active else trr("Старт жизнь","Start life"))+"  [F]"
		elif b.kind in ["turret","drone"]:
			action_label=(trr("Выключить","Deactivate") if b.active else trr("Включить","Activate"))+"  [F]"
		elif b.kind=="grenade":
			action_label=trr("Бросить  [F]","Throw  [F]") if is_instance_valid(b.holder) else trr("Активировать  [F]","Arm  [F]")
			if is_instance_valid(b.holder): extra="drop_gun"
			elif game.nearest_robot(b.global_position): extra="equip"
		elif b.kind=="chainsaw":
			action_label=(trr("Заглушить","Stop") if b.active else trr("Запустить","Rev"))+"  [F]"
			if is_instance_valid(b.holder): extra="drop_gun"
			elif game.nearest_robot(b.global_position): extra="equip"
		elif b.kind in game.MELEE:
			action_label=trr("Удар  [F]","Strike  [F]")
			if is_instance_valid(b.holder): extra="drop_gun"
			elif game.nearest_robot(b.global_position): extra="equip"
		elif b.kind in game.WEAPONS or b.kind in game.EXOTIC:
			action_label=trr("Выстрел  [F]","Fire  [F]")
			if is_instance_valid(b.holder): extra="drop_gun"
			elif game.nearest_robot(b.global_position): extra="equip"
		elif b.kind in ["barrel","mine","sticky"]: action_label=trr("Взорвать  [F]","Detonate  [F]")
		elif b.kind=="balloon": action_label=trr("Лопнуть  [F]","Pop  [F]")
		elif b.kind in game.VIRUSES:
			action_label=trr("Ввести в робота  [F]","Inject into robot  [F]")
		elif b.kind in ["thruster","magnet","fan","coil","wheel"] or (game.TOY_PHYS.has(b.kind) and game.TOY_PHYS[b.kind].has("mode")): action_label=(trr("Выключить","Deactivate") if b.active else trr("Включить","Activate"))+"  [F]"
		var extra_h=36 if extra else 0
		var role_h=24 if is_instance_valid(b.ragdoll) else 0
		panel(Rect2(x,y,204,210+extra_h+role_h),Color("111d28"))
		txt(Vector2(x+16,y+27),trr("ОБЪЕКТ","OBJECT")+"  #"+str(b.serial),10,LabArt.MUTED)
		var title=item_label(b.kind)
		if is_instance_valid(b.ragdoll) and b.ragdoll.virus!="": title=title+" · "+game.virus_label(b.ragdoll.virus)
		var title_size = 18
		if title.length() > 20: title_size = 13
		elif title.length() > 14: title_size = 15
		txt(Vector2(x+16,y+53),title,title_size,LabArt.TEXT,true,172.0)
		var hp=(b.ragdoll.health/b.ragdoll.max_health*100.0) if is_instance_valid(b.ragdoll) else (b.health/b.max_health*100.0)
		var hp_color=LabArt.TEAL
		var condition=""
		if is_instance_valid(b.ragdoll):
			var words=b.ragdoll.damage_label()
			condition="  · "+trr(str(words[0]),str(words[1]))
			hp_color=[LabArt.TEAL,LabArt.TEAL,LabArt.AMBER,LabArt.RED][b.ragdoll.damage_tier()]
		txt(Vector2(x+16,y+79),trr("Прочность  ","Integrity  ")+str(int(hp))+"%"+condition,11,hp_color)
		txt(Vector2(x+16,y+99),trr("Масса  ","Mass  ")+str(b.mass)+trr(" кг"," kg"),11,LabArt.MUTED)
		# Состояние стихий: показываем только то, что сейчас действительно есть.
		var state: Array[String]=[]
		var state_color=LabArt.MUTED
		if b.burning>0.0:
			state.append(trr("ГОРИТ ","BURNING ")+str(int(ceil(b.burning)))+trr(" с"," s"))
			state_color=LabArt.AMBER
		if b.charge>0.1:
			state.append(trr("ТОК ","LIVE ")+str(int(b.charge*100))+"%")
			if b.burning<=0.0: state_color=Color("9fe8ff")
		if b.submerged>0.05: state.append(trr("В ЖИДКОСТИ","SUBMERGED"))
		elif b.wet>0.15: state.append(trr("МОКРОЕ","WET"))
		if not state.is_empty():
			txt(Vector2(x+16,y+113),"  ·  ".join(state),10,state_color,true,172.0)
		if is_instance_valid(b.ragdoll):
			var life_text=trr("РОЛЬ: ","ROLE: ")+b.ragdoll.role_name()+("  · ON" if b.ragdoll.active else "  · OFF")+"  [A]"
			txt(Vector2(x+16,y+120),life_text,9,LabArt.TEAL if b.ragdoll.active else LabArt.MUTED,true,172.0)
		if extra=="vehicle":
			_vehicle_controls(car,x+12,y+114)
		else:
			button("activate",Rect2(x+12,y+114+role_h,180,32),action_label,b.active or (is_instance_valid(b.ragdoll) and b.ragdoll.active) or extra=="drop_gun",true)
		if extra=="drop_gun": button("drop_gun",Rect2(x+12,y+150+role_h,180,28),trr("Выбросить","Drop"),false,true)
		elif extra=="equip": button("equip",Rect2(x+12,y+150+role_h,180,28),trr("Дать в руки","Put in hand"),false,true)
		elif extra=="purge_virus": button("purge_virus",Rect2(x+12,y+150+role_h,180,28),trr("Снять поведение","Clear behavior"),false,true)
		button("freeze",Rect2(x+12,y+154+extra_h+role_h,56,36),trr("Стоп","Freeze"),b.freeze,true)
		button("clone",Rect2(x+72,y+154+extra_h+role_h,58,36),trr("Клон","Clone"),false,true,LabArt.TEAL)
		button("delete",Rect2(x+134,y+154+extra_h+role_h,58,36),trr("Удалить","Delete"),false,true,LabArt.RED)

func _vehicle_controls(car: LabBody, x: float, y: float) -> void:
	if car.wrecked:
		var plate=Rect2(x,y,180,32)
		LabArt.box(self,plate,Color("3a2226"),6,LabArt.RED)
		center(plate,trr("Разбита, не заводится","Wrecked, won't start"),11,LabArt.RED,true)
	else:
		var order=LabVehicle.gear_buttons(car.kind)
		var gap=4.0
		# Ширина по длине подписи: стрелкам хватает узкой кнопки, «Вперёд ▶» — нет.
		var labels: Array[String]=[]
		var weights: Array[float]=[]
		var total=0.0
		for g in order:
			labels.append(LabVehicle.gear_button_label(game,int(g),car.kind))
			weights.append(0.5+labels[-1].length()*0.1)
			total+=weights[-1]
		var room=180.0-gap*(order.size()-1)
		var bx=x
		for i in range(order.size()):
			var bw=room*weights[i]/total
			button("gear:"+str(order[i]),Rect2(bx,y,bw,32),labels[i],car.gear==int(order[i]),true)
			bx+=bw+gap
	var id=LabVehicle.ability(car.kind)
	var rect=Rect2(x,y+36,180,28)
	button("vehicle_ability",rect,LabVehicle.ability_label(game,car)+"  [V]",id in ["tow","winch"] and LabVehicle.hooked(game,car),true)
	# Полоска перезарядки прямо под подписью.
	var wait=LabVehicle.ability_wait(car)
	if wait>0.0: draw_rect(Rect2(rect.position.x+8,rect.end.y-5,(rect.size.x-16)*wait,2),LabArt.AMBER)

func _menu() -> void:
	draw_rect(Rect2(0,0,sw,sh),Color(0.025,0.04,0.065,0.91))
	hits.clear()
	var mw=minf(720,sw-50)
	var mh=404.0 if game.mobile else 570.0
	var x=(sw-mw)/2
	var y=(sh-mh)/2
	LabArt.box(self,Rect2(x,y,mw,mh),Color("111d29"),16,Color("314953"))
	var header_y=y+30 if game.mobile else y+45
	txt(Vector2(x+30,header_y),trr("ФИЗИКА. СВОБОДА. ЭКСПЕРИМЕНТЫ.","PHYSICS. FREEDOM. EXPERIMENTS."),10,LabArt.TEAL,true)
	txt(Vector2(x+27,header_y+(43 if game.mobile else 68)),"KINETIC LAB",36 if game.mobile else 56,LabArt.TEXT,true)
	LabArt.icon(self,"robot",Vector2(x+mw-76,header_y+35),1.15 if game.mobile else 1.6)
	var sub_y=header_y+(68 if game.mobile else 103)
	txt(Vector2(x+30,sub_y),trr("Создай свой полигон и проверь, на что способна физика.","Build your own testing ground and see what physics can do."),12 if game.mobile else 15,LabArt.MUTED)
	var play_y=sub_y+18
	button("play",Rect2(x+30,play_y,mw-60,48),trr("Открыть лабораторию  →","Enter the laboratory  →") if game.cached_scene.is_empty() else trr("Продолжить эксперимент  →","Continue experiment  →"),true)
	var cards_y=play_y+70
	txt(Vector2(x+30,cards_y-8),trr("НОВЫЙ ЭКСПЕРИМЕНТ","NEW EXPERIMENT"),10,LabArt.MUTED,true)
	var card_w=(mw-70)/2
	var card_h=48.0 if game.mobile else 56.0
	var per_page=4 if game.mobile else 6
	var page_count=maxi(1,(game.SCENES.size()+per_page-1)/per_page)
	game.menu_scene_page=clampi(game.menu_scene_page,0,page_count-1)
	var first=game.menu_scene_page*per_page
	var visible=mini(per_page,game.SCENES.size()-first)
	for i in range(visible):
		var scene=game.SCENES[first+i]
		var rect=Rect2(x+30+(i%2)*(card_w+10),cards_y+(i/2)*(card_h+8),card_w,card_h)
		LabArt.box(self,rect,Color("23333f") if rect.has_point(get_viewport().get_mouse_position()) else Color("192936"),7,LabArt.LINE)
		LabArt.icon(self,str(scene[5]),rect.position+Vector2(28,card_h/2),0.48 if game.mobile else 0.55)
		var num=str(first+i+1).pad_zeros(2)
		var max_card_txt_w = card_w - 64.0
		txt(rect.position+Vector2(56,20 if game.mobile else 22),num+"  "+trr(str(scene[1]),str(scene[2])),12 if game.mobile else 13,LabArt.TEXT,true,max_card_txt_w)
		txt(rect.position+Vector2(56,38 if game.mobile else 42),trr(str(scene[3]),str(scene[4])),9,LabArt.MUTED,false,max_card_txt_w)
		hits.append({"id":"scene:"+str(scene[0]),"rect":rect})
	var nav_y=cards_y+((visible+1)/2)*(card_h+8)+4
	if page_count>1:
		button("scene_page_prev",Rect2(x+30,nav_y,36,28),"‹",game.menu_scene_page>0,true)
		center(Rect2(x+70,nav_y,120,28),str(game.menu_scene_page+1)+" / "+str(page_count),11,LabArt.MUTED,true)
		button("scene_page_next",Rect2(x+196,nav_y,36,28),"›",game.menu_scene_page<page_count-1,true)
	var footer_y=y+mh-37
	if not game.mobile:
		txt(Vector2(x+30,footer_y-66),trr("ТВОИ ОТКРЫТИЯ","YOUR DISCOVERIES"),10,LabArt.MUTED,true)
		for i in range(8):
			var r=Rect2(x+30+i*40,footer_y-48,30,28)
			LabArt.box(self,r,Color("24453f") if i in game.completed else Color("1c2e3a"),5)
			center(r,str(i+1),11,LabArt.TEAL if i in game.completed else Color("637c8c"))
	txt(Vector2(x+30,footer_y+4),trr("8 открытий  ·  бесконечные возможности","8 discoveries  ·  endless possibilities"),10,LabArt.MUTED)
	# Магазинной сборке нужен явный выход; во вкладке браузера кнопки быть не должно.
	if game.platform.can_quit():
		button("exit",Rect2(x+mw-266,footer_y-15,80,33),trr("Выход","Exit"),false,true,LabArt.RED)
	button("help",Rect2(x+mw-178,footer_y-15,100,33),trr("Как играть","How to play"),false,true)
	button("lang",Rect2(x+mw-72,footer_y-15,42,33),"RU" if game.lang=="ru" else "EN",false,true)
	if not game.mobile:
		center(Rect2(0,y+mh+15,sw,24),trr("Мышь и клавиатура или касания. Всё необходимое уже внутри.","Mouse and keyboard or touch. Everything you need is already here."),11,LabArt.MUTED)

func _help() -> void:
	draw_rect(Rect2(0,0,sw,sh),Color(0.025,0.04,0.065,0.95))
	hits.clear()
	var w=minf(740,sw-40)
	var h=minf(650,sh-30)
	var x=(sw-w)/2
	var y=(sh-h)/2
	LabArt.box(self,Rect2(x,y,w,h),LabArt.PANEL,12,LabArt.LINE)
	txt(Vector2(x+28,y+38),trr("Твой первый эксперимент","Your first experiment"),23,LabArt.TEXT,true)
	txt(Vector2(x+28,y+64),trr("Здесь нет неправильных решений. Просто попробуй.","There are no wrong answers here. Give it a try."),12,LabArt.MUTED)
	var rows=[
		["robot",trr("Создай","Build"),trr("Выбери объект в каталоге и нажми в лаборатории.","Choose an object from the catalog, then tap the laboratory.")],
		["grab",trr("Перемещай","Move"),trr("Захвати предмет и тяни. Отпусти, чтобы бросить.","Grab and drag an object. Release to throw it.")],
		["pulse",trr("Проверяй","Test"),trr("Импульс толкает и повреждает. Бочки взрываются.","Pulses push and damage objects. Barrels explode.")],
		["link",trr("Соединяй","Connect"),trr("Инструмент «Связь»: нажми на два разных предмета.","Select Link, then tap two different objects.")],
		["thruster",trr("Запускай","Launch"),trr("Выбери двигатель и нажми «Пуск» или F. Роботов можно чинить.","Select a thruster and press Activate or F. Robots can be repaired.")]
	]
	var rowh=45.0 if game.mobile else 67.0
	for i in range(rows.size()):
		var yy=y+99+i*rowh
		LabArt.icon(self,rows[i][0],Vector2(x+48,yy+8),0.4 if game.mobile else 0.6)
		txt(Vector2(x+80,yy),rows[i][1],13,LabArt.TEAL,true)
		txt(Vector2(x+80,yy+19),rows[i][2],10 if game.mobile else 12,LabArt.MUTED)
	if not game.mobile:
		txt(Vector2(x+28,y+h-144),trr("1–7 — инструменты   ·   Пробел — пауза   ·   Q / E — поворот","1–7 — tools   ·   Space — pause   ·   Q / E — rotate"),12,LabArt.TEXT)
		txt(Vector2(x+28,y+h-119),trr("ПКМ — камера   ·   Колесо — масштаб   ·   R — вернуть камеру","Right drag — camera   ·   Scroll — zoom   ·   R — reset camera"),12,LabArt.MUTED)
		txt(Vector2(x+28,y+h-94),trr("Кнопка G отключает гравитацию. 1× включает замедление.","G toggles gravity. 1× enables slow motion."),12,LabArt.MUTED)
	button("help",Rect2(x+28,y+h-63,w-56,43),trr("Всё понятно — к экспериментам!","Got it — let's experiment!"),true)
