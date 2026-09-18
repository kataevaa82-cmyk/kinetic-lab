class_name LabArena
extends Node2D

# Backdrops are drawn once per theme change into a retained command list, so
# they can afford real depth: three or more planes per theme, each pushed
# toward the sky colour to fake atmospheric perspective. Nothing here animates
# per frame — that keeps the GL-compatibility web build cheap.
const L := -2500
const R := 4900
const FY := 620

var font: Font = ThemeDB.fallback_font
var theme = "lab"
var floor_body: StaticBody2D
var sky_top := Color("0a131d")
var sky_bottom := Color("142735")

func _ready() -> void:
	floor_body=_wall(Rect2(-2400,620,7200,200))
	_wall(Rect2(-2450,-2000,50,2800))
	_wall(Rect2(4800,-2000,50,2800))

func _wall(rect: Rect2) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.position=rect.get_center()
	var collision=CollisionShape2D.new()
	var shape=RectangleShape2D.new()
	shape.size=rect.size
	collision.shape=shape
	body.add_child(collision)
	add_child(body)
	return body

func set_theme(id: String) -> void:
	theme=id
	var mat=PhysicsMaterial.new()
	match theme:
		"ice":
			mat.friction=0.03; mat.bounce=0.04
		"bounce":
			mat.friction=0.35; mat.bounce=0.62
		"park":
			mat.friction=0.9; mat.bounce=0.12
		"quarry":
			mat.friction=0.95; mat.bounce=0.05
		"dojo":
			mat.friction=0.88; mat.bounce=0.04
		"foundry":
			mat.friction=0.82; mat.bounce=0.02
		"arcade":
			mat.friction=0.18; mat.bounce=0.58
		"void":
			mat.friction=0.35; mat.bounce=0.12
		"canyon":
			mat.friction=0.8; mat.bounce=0.06
		"brass":
			mat.friction=0.55; mat.bounce=0.1
		"bath":
			mat.friction=0.03; mat.bounce=0.1
		"reef":
			mat.friction=0.28; mat.bounce=0.22
		"rust":
			mat.friction=0.92; mat.bounce=0.12
		"track":
			mat.friction=0.45; mat.bounce=0.08
		_:
			mat.friction=0.7; mat.bounce=0.08
	if is_instance_valid(floor_body): floor_body.physics_material_override=mat
	queue_redraw()

# --- Shared drawing helpers ------------------------------------------------

static func _r(i: int) -> float:
	# Deterministic pseudo-noise: the backdrop must look identical on every
	# redraw, so randf() is deliberately avoided here.
	var v=sin(float(i)*12.9898+float(i%17)*78.233)*43758.5453
	return v-floorf(v)

func _far(c: Color, depth: float) -> Color:
	# Atmospheric perspective. Distant planes lose contrast and drift toward
	# the sky, which reads as depth without a second camera layer.
	return c.lerp(sky_bottom,clampf(depth,0.0,1.0)*0.82)

func _band(y0: float, y1: float, color: Color, a0: float, a1: float, steps: int = 8) -> void:
	var h=(y1-y0)/float(steps)
	for i in range(steps):
		var t=float(i)/float(maxi(steps-1,1))
		draw_rect(Rect2(float(L),y0+float(i)*h,float(R-L),h+1.0),Color(color.r,color.g,color.b,lerpf(a0,a1,t)))

func _poly(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points,color)

func _shafts(origin_y: float, color: Color, step: int, spread: float, alpha: float) -> void:
	# Cheap volumetric light: wedges that widen toward the floor.
	for x in range(L+180,R,step):
		_poly(PackedVector2Array([
			Vector2(x-34,origin_y),Vector2(x+34,origin_y),
			Vector2(float(x)+spread,FY),Vector2(float(x)-spread,FY)]),
			Color(color.r,color.g,color.b,alpha))

func _ridge(base_y: float, height: float, step: int, color: Color, seed_offset: int, roughness: float = 1.0) -> void:
	# One continuous silhouette — hills, dunes, scrap heaps and far shores.
	var pts=PackedVector2Array()
	pts.append(Vector2(L,base_y))
	var i=0
	for x in range(L,R+step,step):
		var n=_r(seed_offset+i*3)*0.6+_r(seed_offset+i*7)*0.4
		pts.append(Vector2(x,base_y-height*(0.35+n*roughness)))
		i+=1
	pts.append(Vector2(R,base_y))
	_poly(pts,color)

func _speck(count: int, y0: float, y1: float, color: Color, size: float, seed_offset: int) -> void:
	for i in range(count):
		var x=float(L)+_r(seed_offset+i*5)*float(R-L)
		var y=lerpf(y0,y1,_r(seed_offset+i*9))
		draw_circle(Vector2(x,y),size*(0.5+_r(seed_offset+i*13)),color)

func _draw() -> void:
	match theme:
		"ice": _sky(Color("d7eef8"),Color("b7d8ea")); _ice(); _floor(Color("cfe6f4"),Color("7ba4c0"),Color("f2fbff"))
		"factory": _sky(Color("2a211c"),Color("3d322c")); _factory(); _floor(Color("4a3a32"),Color("2c221c"),Color("c4a06a"))
		"park": _sky(Color("b9e4c8"),Color("7ec89a")); _park(); _floor(Color("5a8a4a"),Color("3d6a38"),Color("c5d48a"))
		"range": _sky(Color("1a1e22"),Color("2a3238")); _range(); _floor(Color("3a444c"),Color("1c2428"),Color("8aa0ad"))
		"magnet": _sky(Color("1a1428"),Color("2a1c40")); _magnet(); _floor(Color("2c2440"),Color("181228"),Color("b278e8"))
		"storm": _sky(Color("2c3848"),Color("3c4c5c")); _storm(); _floor(Color("3a4a58"),Color("243038"),Color("8aa0ad"))
		"bounce": _sky(Color("3a2040"),Color("5a3060")); _bounce(); _floor(Color("6a4078"),Color("3a2048"),Color("ff82ad"))
		"neon": _sky(Color("0a0c12"),Color("12161e")); _neon(); _floor(Color("161820"),Color("0c0e14"),Color("4ce0bd"))
		"quarry": _sky(Color("c4a882"),Color("a88862")); _quarry(); _floor(Color("8a6a48"),Color("5a4632"),Color("d4b48a"))
		"sky": _sky(Color("8ec8f0"),Color("c4e4fa")); _skydock(); _floor(Color("b9d8ec"),Color("6a93b0"),Color("f4fbff"))
		"dojo": _sky(Color("3a2418"),Color("5a3824")); _dojo(); _floor(Color("6a4a32"),Color("3a2818"),Color("d4a466"))
		"foundry": _sky(Color("2a1410"),Color("4a2418")); _foundry(); _floor(Color("4a2a20"),Color("2a1810"),Color("ef6f62"))
		"arcade": _sky(Color("120818"),Color("241030")); _arcade(); _floor(Color("2a1838"),Color("140820"),Color("ff82ad"))
		"void": _sky(Color("08060e"),Color("100c18")); _void(); _floor(Color("16121e"),Color("0a0810"),Color("b278e8"))
		"canyon": _sky(Color("e8c48a"),Color("c4a070")); _canyon(); _floor(Color("c4a070"),Color("8a6a48"),Color("f0d8a8"))
		"brass": _sky(Color("2a2218"),Color("3c3224")); _brass(); _floor(Color("5a4a32"),Color("3a2e1c"),Color("d4a466"))
		"bath": _sky(Color("d8eef0"),Color("b0d4d8")); _bath(); _floor(Color("8ec8c8"),Color("6aa8a8"),Color("e8f6f6"))
		"reef": _sky(Color("0c3a48"),Color("1a5a68")); _reef(); _floor(Color("2a6a58"),Color("184838"),Color("4ce0bd"))
		"rust": _sky(Color("3a3028"),Color("4a3c32")); _rust(); _floor(Color("5a4a3a"),Color("32281e"),Color("c4a06a"))
		"track": _sky(Color("1a2830"),Color("243840")); _track(); _floor(Color("3a4a52"),Color("1c2a30"),Color("ffcc55"))
		_:
			_sky(Color("0b1722"),Color("183344"))
			_grid(Color("213746"),Color("2b4859"))
	if theme=="lab" or theme=="":
		_draw_lab()
		_ticks()

func _sky(top: Color, bottom_color: Color) -> void:
	sky_top=top
	sky_bottom=bottom_color
	# Banded vertical gradient is considerably cheaper than a full-screen shader
	# and remains stable on low-end WebGL/mobile devices.
	var sky_rect=Rect2(float(L),-2000.0,float(R-L),2620.0)
	var bands=18
	var band_h=sky_rect.size.y/float(bands)
	for i in range(bands):
		var t=float(i)/float(bands-1)
		var eased=t*t*(3.0-2.0*t)
		draw_rect(Rect2(sky_rect.position+Vector2(0,i*band_h),Vector2(sky_rect.size.x,band_h+1)),top.lerp(bottom_color,eased))
	# Zenith falloff and horizon haze: the two cues that sell open space.
	_band(-2000.0,-500.0,top.darkened(0.55),0.30,0.0,4)
	_band(250.0,620.0,bottom_color.lightened(0.26),0.0,0.19,5)
	# Fine atmospheric bands make the huge wall feel physical instead of flat.
	for y in range(-1400,580,360):
		draw_line(Vector2(L,y),Vector2(R,y),Color(0.65,0.86,0.92,0.018),1)

func _grid(a: Color, b: Color) -> void:
	for x in range(-2400,4801,32):
		draw_line(Vector2(x,-2000),Vector2(x,620),a if x%128 else b,1)
	for y in range(-2000,621,32):
		draw_line(Vector2(-2400,y),Vector2(4800,y),a if y%128 else b,1)

func _floor(fill: Color, under: Color, edge: Color) -> void:
	# The slab is lit from above: a face gradient, a bright lip, a dark seam
	# beneath it and a short sheen give props a surface to sit on.
	var bands=6
	var bh=200.0/float(bands)
	for i in range(bands):
		var t=float(i)/float(bands-1)
		draw_rect(Rect2(float(L),620.0+float(i)*bh,float(R-L),bh+1.0),fill.lerp(under,0.12+t*t*0.88))
	draw_rect(Rect2(float(L),620,float(R-L),7),edge)
	draw_line(Vector2(L,618),Vector2(R,618),edge.lightened(0.35),2)
	draw_rect(Rect2(float(L),627,float(R-L),3),under.darkened(0.3))
	draw_rect(Rect2(float(L),631,float(R-L),10),Color(edge.r,edge.g,edge.b,0.05))
	draw_rect(Rect2(float(L),641,float(R-L),8),Color(edge.r,edge.g,edge.b,0.025))
	# Grain and expansion joints break up 7400px of otherwise flat colour.
	for i in range(170):
		var x=float(L)+_r(i*3+1)*float(R-L)
		var y=636.0+_r(i*7+5)*160.0
		draw_circle(Vector2(x,y),0.7+_r(i*11)*1.5,Color(edge.r,edge.g,edge.b,0.04+_r(i*13)*0.06))
	for x in range(L,R,240):
		draw_line(Vector2(x,630),Vector2(x,820),Color(under.r,under.g,under.b,0.55),1)
		draw_line(Vector2(x+2,630),Vector2(x+2,820),Color(edge.r,edge.g,edge.b,0.05),1)

# --- Themes ----------------------------------------------------------------

func _ice() -> void:
	var far=_far(Color("7ba2c2"),0.45)
	var mid=_far(Color("6b93b6"),0.18)
	_ridge(620,300,320,far,11,0.7)
	# Far bergs, then a nearer shelf with lit faces and shadowed clefts.
	for i in range(16):
		var x=L+120+i*460+int(_r(i*5)*90.0)
		var h=150.0+_r(i*9)*180.0
		_poly(PackedVector2Array([Vector2(x-150,620),Vector2(x-40,620.0-h),Vector2(x+55,620.0-h*0.74),Vector2(x+170,620)]),mid)
		_poly(PackedVector2Array([Vector2(x-40,620.0-h),Vector2(x+55,620.0-h*0.74),Vector2(x+20,620)]),mid.lightened(0.18))
		draw_line(Vector2(x-40,620.0-h),Vector2(x-8,620),Color(1,1,1,0.22),2)
	_band(380.0,620.0,Color("eaf6ff"),0.0,0.10,6)
	_shafts(-200.0,Color(0.92,0.98,1.0),620,150.0,0.030)
	_speck(46,-180.0,560.0,Color(1,1,1,0.5),2.0,71)
	_speck(30,-400.0,300.0,Color(0.85,0.95,1.0,0.28),3.4,133)

func _factory() -> void:
	# Back wall of machine halls. The mass has to sit darker than the sky or
	# the lit windows read as rectangles floating in mid-air.
	var far=Color("281f1a")
	for x in range(L,R,300):
		var h=180.0+_r(x)*160.0
		draw_rect(Rect2(x+10,620.0-h,270,h),far)
		draw_rect(Rect2(x+10,620.0-h,270,6),Color("3e322a"))
		for wy in range(3):
			for wx in range(4):
				var lit=_r(x+wy*7+wx*31)>0.62
				draw_rect(Rect2(x+38+wx*60,620.0-h+28.0+float(wy)*46.0,24,17),Color(0.72,0.52,0.27,0.55) if lit else Color("1d1713"))
	_band(300.0,620.0,Color("d69b52"),0.0,0.12,6)
	for x in range(L,R,520):
		draw_rect(Rect2(x,60,26,560),Color("5a4a40"))
		draw_rect(Rect2(x+3,60,7,560),Color("7a6a5c"))
		draw_circle(Vector2(x+13,52),18,Color("6a5a48"))
		draw_circle(Vector2(x+13,52),11,Color("4a3c32"))
		draw_rect(Rect2(x-6,250,38,16),Color("6a5a48"))
		draw_rect(Rect2(x-6,470,38,16),Color("6a5a48"))
	# Overhead gantry with hanging chains.
	draw_rect(Rect2(float(L),96,float(R-L),20),Color("3c322a"))
	for x in range(L,R,160):
		draw_line(Vector2(x,116),Vector2(x,150.0+_r(x*3)*70.0),Color("2e261f"),3)
	_shafts(116.0,Color(1.0,0.78,0.45),640,190.0,0.028)
	_speck(40,120.0,600.0,Color(0.9,0.7,0.4,0.16),2.2,57)

func _park() -> void:
	# Three tree planes with decreasing haze plus a wildflower ground line.
	_ridge(620,260,380,_far(Color("6aa878"),0.6),23,0.55)
	_ridge(620,160,260,_far(Color("54935f"),0.4),41,0.7)
	for i in range(26):
		var x=L+80+i*290+int(_r(i*7)*60.0)
		var h=120.0+_r(i*11)*70.0
		var col=_far(Color("2f6b3f"),0.28)
		draw_rect(Rect2(x-7,620.0-h*0.35,14,h*0.35),_far(Color("4a3324"),0.28))
		_poly(PackedVector2Array([Vector2(x,620.0-h),Vector2(x+58,620.0-h*0.3),Vector2(x-58,620.0-h*0.3)]),col)
		_poly(PackedVector2Array([Vector2(x,620.0-h*0.9),Vector2(x+40,620.0-h*0.24),Vector2(x-40,620.0-h*0.24)]),col.lightened(0.1))
	for i in range(18):
		var x=L+140+i*420+int(_r(i*13)*120.0)
		var h=170.0+_r(i*17)*60.0
		draw_rect(Rect2(x-10,620.0-h*0.4,20,h*0.4),Color("5a3d28"))
		_poly(PackedVector2Array([Vector2(x,620.0-h),Vector2(x+76,620.0-h*0.32),Vector2(x-76,620.0-h*0.32)]),Color("3d7a4a"))
		_poly(PackedVector2Array([Vector2(x,620.0-h*0.86),Vector2(x+52,620.0-h*0.26),Vector2(x-52,620.0-h*0.26)]),Color("4a8f56"))
		draw_circle(Vector2(x-30,620.0-h*0.55),4,Color(1,1,1,0.10))
	for i in range(90):
		var x=float(L)+_r(i*19)*float(R-L)
		draw_line(Vector2(x,620),Vector2(x+_r(i*23)*6.0-3.0,606.0-_r(i*29)*12.0),Color("58a05e"),2)
		if i%5==0: draw_circle(Vector2(x,600.0-_r(i*31)*8.0),2.5,Color("ffd86a") if i%2 else Color("ff9fb6"))
	_shafts(-300.0,Color(1.0,0.96,0.72),700,180.0,0.035)

func _range() -> void:
	# Indoor shooting hall: panelled back wall, lane lighting, sandbags.
	draw_rect(Rect2(float(L),200,float(R-L),420),_far(Color("222a30"),0.35))
	for x in range(L,R,220):
		draw_rect(Rect2(x+6,208,206,404),_far(Color("28323a"),0.3))
		draw_line(Vector2(x+6,300),Vector2(x+212,300),Color("39464f"),2)
	draw_rect(Rect2(float(L),186,float(R-L),16),Color("1a2228"))
	for x in range(L,R,300):
		draw_rect(Rect2(x,60,18,140),Color("222c33"))
		LabArt.box(self,Rect2(x-52,44,122,14),Color("38484f"),3)
		LabArt.soft_glow(self,Vector2(x+8,52),70,Color(0.85,0.92,1.0,0.26),0.7)
		_poly(PackedVector2Array([Vector2(x-48,58),Vector2(x+64,58),Vector2(x+150,620),Vector2(x-134,620)]),Color(0.8,0.88,1.0,0.016))
	for x in range(L+180,R,340):
		draw_rect(Rect2(x-4,420,8,200),Color("55606a"))
		draw_rect(Rect2(x-46,560,92,14),Color("3c464e"))
		for r in [70,46,22]:
			draw_arc(Vector2(x,360),r,0,TAU,36,Color("c45c55") if r==22 else Color("d8d0c8"),3,true)
		draw_circle(Vector2(x,360),9,Color("c45c55"))
		draw_circle(Vector2(x+22,336),3,Color(0.1,0.1,0.1,0.6))
	for x in range(L,R,140):
		draw_rect(Rect2(x,596,118,24),Color("4a4237"))
		draw_line(Vector2(x,608),Vector2(x+118,608),Color("3a3429"),2)

func _magnet() -> void:
	# Field rings at two depths plus the coil rigs that generate them.
	var coil=Color("b278e8")
	_band(260.0,620.0,coil,0.0,0.10,6)
	for x in range(L,R,300):
		for k in range(4):
			var rad=60.0+float(k)*38.0
			draw_arc(Vector2(x,380),rad,0,TAU,44,Color(coil.r,coil.g,coil.b,0.06+0.05*float(3-k)),2,true)
	for x in range(L+120,R,600):
		draw_rect(Rect2(x-16,300,32,320),_far(Color("3a2f52"),0.2))
		for k in range(9):
			draw_rect(Rect2(x-30,308.0+float(k)*34.0,60,16),Color("7a5aa8"))
			draw_rect(Rect2(x-30,308.0+float(k)*34.0,60,4),Color("9d7ed0"))
		draw_circle(Vector2(x,292),20,Color("d0a8ff"))
		LabArt.soft_glow(self,Vector2(x,292),82,Color(0.78,0.55,1.0,0.5),0.9)
	for i in range(48):
		var x=float(L)+_r(i*7)*float(R-L)
		var y=120.0+_r(i*11)*440.0
		draw_line(Vector2(x,y),Vector2(x+22,y-9),Color(coil.r,coil.g,coil.b,0.24),1)
	_speck(34,60.0,580.0,Color(0.8,0.6,1.0,0.35),2.2,91)

func _storm() -> void:
	# Layered cloud mass, a far shore, three rain planes and splash rings.
	for i in range(14):
		var x=L+i*540+int(_r(i*5)*200.0)
		var y=40.0+_r(i*9)*120.0
		var col=_far(Color("35475a"),0.25)
		draw_circle(Vector2(x,y),120,col)
		draw_circle(Vector2(x+110,y+26),92,col)
		draw_circle(Vector2(x-96,y+34),80,col)
		draw_circle(Vector2(x+20,y-40),84,col.lightened(0.08))
	_ridge(620,200,420,_far(Color("2c3a47"),0.5),13,0.6)
	_band(320.0,620.0,Color("9fb6c8"),0.0,0.20,6)
	for i in range(150):
		var x=float(L)+_r(i*3)*float(R-L)
		var y=-200.0+_r(i*13)*820.0
		var length=18.0+_r(i*17)*26.0
		draw_line(Vector2(x,y),Vector2(x+length*0.28,y+length),Color(0.75,0.85,0.95,0.10+_r(i*19)*0.18),1)
	for i in range(40):
		var x=float(L)+_r(i*23)*float(R-L)
		draw_arc(Vector2(x,618),5.0+_r(i*29)*9.0,PI,TAU,10,Color(0.8,0.9,1.0,0.18),1,true)

func _bounce() -> void:
	_band(240.0,620.0,Color("ff82ad"),0.0,0.12,6)
	for x in range(L,R,240):
		draw_rect(Rect2(x,120,120,500),Color(1,0.5,0.7,0.035))
	# Pads with rims and glow, plus drifting balloons for vertical interest.
	for x in range(L,R,380):
		LabArt.soft_glow(self,Vector2(x,540),90,Color(1.0,0.45,0.68,0.45),0.9)
		draw_circle(Vector2(x,540),46,Color(1,0.5,0.7,0.16))
		draw_arc(Vector2(x,540),46,0,TAU,48,Color("ff82ad"),3,true)
		draw_arc(Vector2(x,540),30,0,TAU,36,Color("ffd0e2"),2,true)
		draw_rect(Rect2(x-52,568,104,12),Color("8a4a92"))
	for i in range(18):
		var x=L+100+i*420+int(_r(i*7)*140.0)
		var y=120.0+_r(i*11)*280.0
		var col=Color("ffb3d0") if i%2 else Color("9fd8ff")
		draw_circle(Vector2(x,y),16.0+_r(i*13)*10.0,Color(col.r,col.g,col.b,0.5))
		draw_line(Vector2(x,y+18),Vector2(x+4,y+60),Color(1,1,1,0.16),1)
	_speck(36,80.0,560.0,Color(1,0.8,0.9,0.3),2.4,151)

func _neon() -> void:
	# Skyline in three hazed planes, then vertical neon and sign boxes.
	for depth in [0.62,0.4,0.18]:
		var col=Color("273554").lerp(Color("101827"),1.0-depth)
		var step=int(160.0+depth*220.0)
		var win=Color(0.3,0.88,0.74,0.20+0.16*depth)
		for x in range(L,R,step):
			var h=140.0+_r(int(x)+int(depth*1000.0))*300.0*(1.1-depth)
			var w=step-14
			draw_rect(Rect2(x,640.0-h,w,h),col)
			draw_rect(Rect2(x,640.0-h,w,3),col.lightened(0.12))
			var cols=maxi(int(float(w)/34.0),2)
			for wy in range(int(h/40.0)):
				for wx in range(cols):
					if _r(x+wy*13+wx*57+int(depth*77.0))>0.76:
						draw_rect(Rect2(x+11.0+float(wx)*float(w-18)/float(cols),640.0-h+16.0+float(wy)*40.0,6,8),win if (wx+wy)%3 else Color(1.0,0.51,0.68,win.a*0.9))
	for x in range(L,R,280):
		var col=Color("4ce0bd") if (x/280)%2==0 else Color("ff82ad")
		LabArt.glow_line(self,Vector2(x,40),Vector2(x,620),col,3)
	for x in range(L+140,R,560):
		var col=Color("54d9ff") if (x/560)%2==0 else Color("ffcc55")
		draw_rect(Rect2(x-46,180,92,58),Color("0d1118"))
		draw_rect(Rect2(x-46,180,92,58),col,false,2)
		LabArt.soft_glow(self,Vector2(x,209),74,Color(col.r,col.g,col.b,0.5),0.8)
	_band(300.0,620.0,Color("2b6f8a"),0.0,0.16,6)
	_band(500.0,620.0,Color("4ce0bd"),0.0,0.05,4)

func _quarry() -> void:
	# Terraced pit walls, scree and a dust haze that eats the far benches.
	_ridge(620,300,400,_far(Color("a07a52"),0.6),17,0.6)
	for level in range(3):
		var y=620.0-float(level)*90.0
		var col=_far(Color("8a6a4a"),0.42-float(level)*0.14)
		for x in range(L,R,340):
			var off=int(_r(x+level*31)*90.0)
			_poly(PackedVector2Array([Vector2(x-120+off,y),Vector2(x-50+off,y-118),Vector2(x+90+off,y-104),Vector2(x+170+off,y)]),col)
			draw_line(Vector2(x-50+off,y-118),Vector2(x+90+off,y-104),col.lightened(0.2),2)
	for i in range(50):
		var x=float(L)+_r(i*5)*float(R-L)
		var s=5.0+_r(i*9)*14.0
		_poly(PackedVector2Array([Vector2(x,620),Vector2(x+s,620.0-s*0.8),Vector2(x+s*2.0,620)]),Color("6e5238"))
	_band(300.0,620.0,Color("e2c69a"),0.0,0.34,7)
	_shafts(-200.0,Color(1.0,0.92,0.72),720,200.0,0.04)

func _skydock() -> void:
	# Cloud decks at three depths and distant docking platforms.
	for depth in [0.68,0.42,0.16]:
		var col=Color(1,1,1,0.16+0.22*(1.0-depth))
		var y=140.0+depth*260.0
		for i in range(12):
			var x=L+i*640+int(_r(i*7+int(depth*90.0))*260.0)
			var s=46.0+_r(i*11)*46.0
			draw_circle(Vector2(x,y),s,col)
			draw_circle(Vector2(x+s*0.8,y+s*0.28),s*0.78,col)
			draw_circle(Vector2(x-s*0.85,y+s*0.34),s*0.66,col)
			draw_circle(Vector2(x+s*0.1,y-s*0.4),s*0.72,col)
	for i in range(7):
		var x=L+220+i*940
		var y=300.0+_r(i*13)*90.0
		var col=_far(Color("8ab0c8"),0.3)
		_poly(PackedVector2Array([Vector2(x-110,y),Vector2(x+110,y),Vector2(x+72,y+34),Vector2(x-72,y+34)]),col)
		draw_rect(Rect2(x-110,y-7,220,8),col.lightened(0.3))
		draw_line(Vector2(x-70,y-7),Vector2(x-70,y-48),col.lightened(0.15),3)
		draw_circle(Vector2(x-70,y-52),6,Color("ffcc55"))
	for i in range(10):
		var x=float(L)+_r(i*17)*float(R-L)
		var y=180.0+_r(i*19)*160.0
		draw_line(Vector2(x-9,y),Vector2(x,y-5),Color(0.3,0.38,0.45,0.35),2)
		draw_line(Vector2(x,y-5),Vector2(x+9,y),Color(0.3,0.38,0.45,0.35),2)
	_band(380.0,620.0,Color("ffffff"),0.0,0.20,7)

func _dojo() -> void:
	# Shoji wall, timber frame, hanging lanterns and a warm floor wash.
	draw_rect(Rect2(float(L),150,float(R-L),470),_far(Color("6b4a2e"),0.25))
	for x in range(L,R,150):
		draw_rect(Rect2(x+8,196,132,268),Color("c0a47b"))
		draw_rect(Rect2(x+8,196,132,30),Color("a98c66"))
		for k in range(3):
			draw_line(Vector2(x+8,236.0+float(k)*68.0),Vector2(x+140,236.0+float(k)*68.0),Color("7d5f41"),3)
		draw_line(Vector2(x+74,196),Vector2(x+74,464),Color("7d5f41"),3)
		draw_rect(Rect2(x,150,8,470),Color("4a3320"))
	_band(196.0,268.0,Color("2a1a0e"),0.30,0.0,4)
	draw_rect(Rect2(float(L),464,float(R-L),22),Color("4a3320"))
	draw_rect(Rect2(float(L),128,float(R-L),26),Color("3a2818"))
	_poly(PackedVector2Array([Vector2(L,128),Vector2(R,128),Vector2(R,96),Vector2(L,96)]),Color("52351f"))
	for x in range(L,R,380):
		draw_line(Vector2(x,128),Vector2(x,176),Color("d4a466"),2)
		_poly(PackedVector2Array([Vector2(x-18,176),Vector2(x+18,176),Vector2(x+14,232),Vector2(x-14,232)]),Color("ef6f62"))
		draw_line(Vector2(x-16,196),Vector2(x+16,196),Color("b8453c"),2)
		draw_circle(Vector2(x,206),7,Color("ffcc55"))
		LabArt.soft_glow(self,Vector2(x,206),90,Color(1.0,0.72,0.36,0.55),0.9)
	_band(420.0,620.0,Color("ffbc70"),0.0,0.14,5)
	_speck(26,200.0,560.0,Color(1.0,0.82,0.5,0.22),2.0,193)

func _foundry() -> void:
	# Furnace mouths behind a girder cage, a molten trough and rising embers.
	draw_rect(Rect2(float(L),180,float(R-L),440),_far(Color("3a1c14"),0.25))
	for x in range(L,R,560):
		draw_rect(Rect2(x,240,180,380),Color("30160f"))
		_poly(PackedVector2Array([Vector2(x+24,620),Vector2(x+40,300),Vector2(x+140,300),Vector2(x+156,620)]),Color("6d2010"))
		_poly(PackedVector2Array([Vector2(x+48,620),Vector2(x+60,330),Vector2(x+120,330),Vector2(x+132,620)]),Color("c2561f"))
		_poly(PackedVector2Array([Vector2(x+66,620),Vector2(x+74,360),Vector2(x+106,360),Vector2(x+114,620)]),Color("e8823a"))
		LabArt.soft_glow(self,Vector2(x+90,450),150,Color(1.0,0.45,0.15,0.3),0.7)
	for x in range(L,R,220):
		draw_rect(Rect2(x,150,22,470),Color("2a1610"))
		draw_rect(Rect2(x+2,150,5,470),Color("46261a"))
	draw_rect(Rect2(float(L),120,float(R-L),30),Color("24120c"))
	for x in range(L,R,110):
		_poly(PackedVector2Array([Vector2(x,150),Vector2(x+55,150),Vector2(x+28,186)]),Color("2e1811"))
	draw_rect(Rect2(float(L),598,float(R-L),22),Color("58200f"))
	draw_rect(Rect2(float(L),604,float(R-L),10),Color("d97a2c"))
	for i in range(64):
		var x=float(L)+_r(i*7)*float(R-L)
		var y=140.0+_r(i*11)*460.0
		draw_circle(Vector2(x,y),1.6+_r(i*13)*2.6,Color(1.0,0.45+_r(i*17)*0.3,0.18,0.28+_r(i*19)*0.34))
	_band(300.0,620.0,Color("ff6a2a"),0.0,0.16,6)

func _arcade() -> void:
	# Cabinet row with lit marquees, CRT rings and bunting.
	draw_rect(Rect2(float(L),220,float(R-L),400),_far(Color("1c0e28"),0.25))
	for x in range(L,R,240):
		var col=Color("ff82ad") if (x/240)%2==0 else Color("54d9ff")
		draw_rect(Rect2(x+18,300,190,320),Color("20102e"))
		draw_rect(Rect2(x+18,300,190,14),Color(col.r,col.g,col.b,0.6))
		draw_rect(Rect2(x+18,314,190,8),Color(col.r,col.g,col.b,0.22))
		draw_rect(Rect2(x+34,344,158,110),Color("07060c"))
		draw_arc(Vector2(x+113,399),44,0,TAU,32,Color(col.r,col.g,col.b,0.7),2,true)
		draw_arc(Vector2(x+113,399),24,0,TAU,24,Color("ffcc55"),2,true)
		draw_rect(Rect2(x+34,472,158,26),Color("2c1840"))
		draw_circle(Vector2(x+70,485),7,Color("ffcc55"))
		draw_circle(Vector2(x+100,485),7,Color("ff5f7a"))
		LabArt.soft_glow(self,Vector2(x+113,307),78,Color(col.r,col.g,col.b,0.3),0.6)
		LabArt.soft_glow(self,Vector2(x+113,399),80,Color(col.r,col.g,col.b,0.35),0.7)
	for x in range(L,R,64):
		draw_rect(Rect2(x,200,22,7),Color(1.0,0.51,0.68,0.5) if (x/64)%3 else Color(0.33,0.85,1.0,0.5))
	_band(420.0,620.0,Color("ff82ad"),0.0,0.10,5)
	_speck(40,240.0,600.0,Color(1.0,0.6,0.85,0.24),2.0,211)

func _void() -> void:
	# Deep field, nebula wash, a distant world and the well's event rings.
	for i in range(180):
		var x=float(L)+_r(i*3)*float(R-L)
		var y=-1900.0+_r(i*7)*2500.0
		draw_circle(Vector2(x,y),0.8+_r(i*11)*2.0,Color(0.85,0.8,1.0,0.2+_r(i*13)*0.6))
	for i in range(260):
		var x=float(L)+_r(500+i*3)*float(R-L)
		var y=-260.0+_r(500+i*7)*880.0
		var s=0.7+_r(500+i*11)*1.9
		draw_circle(Vector2(x,y),s,Color(0.88,0.84,1.0,0.18+_r(500+i*13)*0.55))
		if i%23==0:
			draw_line(Vector2(x-5,y),Vector2(x+5,y),Color(0.9,0.85,1.0,0.18),1)
			draw_line(Vector2(x,y-5),Vector2(x,y+5),Color(0.9,0.85,1.0,0.18),1)
	for i in range(9):
		var c=Vector2(float(L)+_r(i*17)*float(R-L),-600.0+_r(i*19)*900.0)
		for k in range(4):
			draw_circle(c+Vector2(_r(i*23+k)*160.0-80.0,_r(i*29+k)*90.0-45.0),160.0+_r(i*31+k)*130.0,Color(0.45,0.25,0.7,0.022))
	var planet=Vector2(900,175)
	draw_circle(planet,130,Color("221837"))
	draw_circle(planet+Vector2(-26,-24),114,Color("32224f"))
	draw_arc(planet,158,-0.5,0.5+PI,60,Color(0.7,0.5,1.0,0.18),4,true)
	LabArt.soft_glow(self,planet,200,Color(0.55,0.35,0.9,0.35),0.7)
	for x in range(L,R,700):
		for k in range(3):
			draw_arc(Vector2(x,520),70.0+float(k)*46.0,0,TAU,48,Color(0.7,0.47,0.91,0.10-0.02*float(k)),2,true)
	_band(400.0,620.0,Color("b278e8"),0.0,0.07,5)

func _canyon() -> void:
	# Four mesa planes with strong haze separation and a dusty floor line.
	for depth in [0.72,0.5,0.3,0.12]:
		var col=_far(Color("9c6c42"),depth)
		var step=int(300.0+depth*320.0)
		for x in range(L,R,step):
			var h=(130.0+_r(int(x)+int(depth*700.0))*210.0)*(0.5+depth)
			var w=float(step)*0.62
			_poly(PackedVector2Array([
				Vector2(float(x)-w*0.8,620.0),Vector2(float(x)-w*0.52,620.0-h),
				Vector2(float(x)+w*0.52,620.0-h),Vector2(float(x)+w*0.8,620.0)]),col)
			draw_rect(Rect2(float(x)-w*0.54,620.0-h-8.0,w*1.08,9),col.lightened(0.16))
			for k in range(3):
				draw_line(Vector2(float(x)-w*0.62,620.0-h*float(3-k)/3.4),Vector2(float(x)+w*0.62,620.0-h*float(3-k)/3.4),col.darkened(0.14),2)
		_band(480.0,620.0,Color("e8c48a"),0.0,0.16+0.12*depth,4)
	for i in range(16):
		var x=float(L)+_r(i*23)*float(R-L)
		var col=Color("4a7040")
		var h=46.0+_r(i*29)*34.0
		draw_line(Vector2(x,620),Vector2(x,620.0-h),col,13)
		draw_circle(Vector2(x,620.0-h),6.5,col)
		draw_line(Vector2(x-14,620.0-h*0.45),Vector2(x-14,620.0-h*0.75),col,8)
		draw_arc(Vector2(x-14,620.0-h*0.45),14,PI,PI*1.5,10,col,8)
		draw_line(Vector2(x+13,620.0-h*0.3),Vector2(x+13,620.0-h*0.6),col,8)
		draw_arc(Vector2(x+13,620.0-h*0.3),13,PI*1.5,TAU,10,col,8)
		draw_line(Vector2(x-3,620),Vector2(x-3,620.0-h),col.lightened(0.12),3)
	_shafts(-260.0,Color(1.0,0.92,0.7),760,220.0,0.035)

func _brass() -> void:
	# A gear train at three depths, driven by shafts and pressure vessels.
	for depth in [0.6,0.3]:
		var col=_far(Color("a8834a"),depth)
		var step=int(420.0+depth*360.0)
		for x in range(L,R,step):
			var c=Vector2(x,200.0+_r(int(x)+int(depth*99.0))*180.0)
			var rad=44.0+_r(int(x)*3)*40.0
			draw_arc(c,rad,0,TAU,30,col,3,true)
			draw_circle(c,rad*0.3,col.darkened(0.25))
			for k in range(10):
				var a=float(k)*TAU/10.0
				draw_line(c+Vector2.from_angle(a)*(rad+1.0),c+Vector2.from_angle(a)*(rad+13.0),col,4)
				draw_line(c+Vector2.from_angle(a)*rad*0.3,c+Vector2.from_angle(a)*(rad-2.0),col,2)
	for i in range(9):
		var c=Vector2(L+180+i*800,280)
		draw_arc(c,62,0,TAU,34,Color("d4a466"),4,true)
		draw_arc(c,44,0,TAU,26,Color("b8874a"),2,true)
		draw_circle(c,16,Color("8a6a3c"))
		for k in range(12):
			var a=float(k)*TAU/12.0
			draw_line(c+Vector2.from_angle(a)*63.0,c+Vector2.from_angle(a)*79.0,Color("c4a06a"),6)
			draw_line(c+Vector2.from_angle(a)*18.0,c+Vector2.from_angle(a)*42.0,Color("a8834a"),3)
		LabArt.bolt(self,c,5,Color("e8c891"))
	draw_rect(Rect2(float(L),430,float(R-L),18),Color("4a3c26"))
	for x in range(L,R,320):
		draw_rect(Rect2(x,448,58,172),Color("564427"))
		draw_circle(Vector2(x+29,478),19,Color("d4a466"))
		draw_circle(Vector2(x+29,478),13,Color("f0e0c0"))
		draw_line(Vector2(x+29,478),Vector2(x+38,470),Color("8a2a1a"),2)
	_band(360.0,620.0,Color("d4a466"),0.0,0.12,5)

func _bath() -> void:
	# Wet tile with specular highlights, steam banks and shower fittings.
	for x in range(L,R,64):
		draw_line(Vector2(x,-260),Vector2(x,620),Color(0.30,0.52,0.56,0.40),3)
	for y in range(-260,621,64):
		draw_line(Vector2(L,y),Vector2(R,y),Color(0.30,0.52,0.56,0.40),3)
	for i in range(120):
		var gx=L+int(_r(i*5)*float(R-L)/64.0)*64
		var gy=-256+int(_r(i*9)*13.0)*64
		draw_rect(Rect2(gx+4,gy+4,56,56),Color(1,1,1,0.05+_r(i*13)*0.05))
		draw_line(Vector2(gx+10,gy+50),Vector2(gx+48,gy+12),Color(1,1,1,0.10),3)
	draw_rect(Rect2(float(L),300,float(R-L),12),Color("7fb3b3"))
	for x in range(L,R,340):
		draw_rect(Rect2(x-5,312,10,44),Color("8fb6b8"))
		draw_circle(Vector2(x,362),16,Color("a8cbcc"))
		draw_circle(Vector2(x,362),10,Color("7ba3a5"))
		for k in range(7):
			draw_line(Vector2(x-12.0+float(k)*4.0,372),Vector2(x-20.0+float(k)*6.0,470),Color(0.8,0.94,0.96,0.20),2)
	for i in range(18):
		var x=L+i*420+int(_r(i*7)*180.0)
		var y=420.0+_r(i*11)*160.0
		var s=70.0+_r(i*13)*70.0
		draw_circle(Vector2(x,y),s*0.8,Color(1,1,1,0.05))
		draw_circle(Vector2(x+s*0.6,y+18),s*0.55,Color(1,1,1,0.04))
	_band(360.0,620.0,Color("ffffff"),0.0,0.12,7)

func _reef() -> void:
	# Caustic light through water, coral banks, kelp planes and bubbles.
	_shafts(-400.0,Color(0.55,1.0,0.92),420,230.0,0.030)
	for i in range(26):
		var x=L+i*290+int(_r(i*5)*120.0)
		var col=_far(Color("1f6a58"),0.45)
		draw_circle(Vector2(x,600),52.0+_r(i*9)*40.0,col)
		draw_circle(Vector2(x+60,612),40.0+_r(i*11)*26.0,col.darkened(0.1))
	for i in range(22):
		var x=L+80+i*330+int(_r(i*13)*100.0)
		var col=Color("ef6f62") if i%3==0 else Color("ffbc70")
		draw_line(Vector2(x,620),Vector2(x,586),Color(col.r,col.g,col.b,0.8),22)
		for k in range(4):
			var a=-PI*0.5+(_r(i*17+k)-0.5)*1.3
			var tip=Vector2(x,586)+Vector2.from_angle(a)*(46.0+_r(i*19+k)*46.0)
			draw_line(Vector2(x,596),tip,Color(col.r,col.g,col.b,0.8),15)
			draw_circle(tip,9,Color(col.r,col.g,col.b,0.92))
			draw_circle(tip+Vector2(-3,-3),4,Color(1,1,1,0.14))
	for x in range(L,R,190):
		var sway=_r(x)*40.0-20.0
		var pts=PackedVector2Array()
		for k in range(7):
			pts.append(Vector2(float(x)+sin(float(k)*0.9)*22.0+sway*float(k)/6.0,620.0-float(k)*46.0))
		for k in range(pts.size()-1):
			draw_line(pts[k],pts[k+1],Color("3e8a52"),7.0-float(k)*0.6)
		draw_circle(pts[pts.size()-1],9,Color("4ce0bd"))
	for i in range(60):
		var x=float(L)+_r(i*23)*float(R-L)
		var y=60.0+_r(i*29)*540.0
		draw_arc(Vector2(x,y),2.0+_r(i*31)*4.0,0,TAU,12,Color(0.8,1.0,0.98,0.28),1,true)
	_band(-200.0,620.0,Color("041e2a"),0.0,0.26,7)

func _rust() -> void:
	# Scrap skyline, gantry cranes, stacked hulks and a chain-link fence.
	_ridge(620,220,360,_far(Color("47382b"),0.55),29,0.9)
	for i in range(11):
		var x=L+140+i*680
		draw_rect(Rect2(x,240,14,380),_far(Color("5c4a34"),0.3))
		draw_rect(Rect2(x-70,226,260,14),_far(Color("6a5539"),0.3))
		draw_line(Vector2(x+160,240),Vector2(x+160,320),Color("3a2e20"),3)
		draw_rect(Rect2(x+140,320,42,30),Color("8a6a44"))
	var hulks=[Color("7a4a38"),Color("4e5f6a"),Color("6a6a42"),Color("8a5a3c")]
	for x in range(L,R,400):
		var hull=hulks[absi(x/400)%hulks.size()]
		draw_rect(Rect2(x,470,120,150),hull)
		draw_rect(Rect2(x+6,478,108,26),hull.darkened(0.28))
		draw_rect(Rect2(x+20,420,62,50),Color("5c6d78"))
		draw_rect(Rect2(x+26,426,50,38),Color("2e3a42"))
		draw_rect(Rect2(x+124,520,70,100),hulks[absi(x/400+1)%hulks.size()])
		draw_circle(Vector2(x+150,600),22,Color("2a2420"))
		draw_circle(Vector2(x+150,600),9,Color("6a5a48"))
		draw_circle(Vector2(x+36,614),20,Color("2a2420"))
		# Rust weeps down each panel seam.
		for k in range(4):
			draw_line(Vector2(x+8.0+float(k)*30.0,470),Vector2(x+8.0+float(k)*30.0,620),Color(0.2,0.15,0.1,0.25),2)
			draw_line(Vector2(x+10.0+float(k)*30.0,478),Vector2(x+10.0+float(k)*30.0,478.0+_r(x+k)*90.0),Color(0.55,0.28,0.12,0.3),3)
	draw_rect(Rect2(float(L),540,float(R-L),6),Color("4a4034"))
	for x in range(L,R,26):
		draw_line(Vector2(x,546),Vector2(x+26,620),Color(0.45,0.4,0.34,0.22),1)
		draw_line(Vector2(x+26,546),Vector2(x,620),Color(0.45,0.4,0.34,0.22),1)
	_speck(46,300.0,600.0,Color(0.75,0.6,0.4,0.14),2.6,233)

func _track() -> void:
	# Grandstand, floodlights, a banner line and staged lane markings.
	draw_rect(Rect2(float(L),300,float(R-L),320),_far(Color("22323c"),0.35))
	for x in range(L,R,60):
		for k in range(5):
			draw_rect(Rect2(x+6,318.0+float(k)*36.0,48,22),_far(Color("36505e") if (x/60+k)%3 else Color("50707f"),0.3))
	draw_rect(Rect2(float(L),300,float(R-L),14),Color("1a2830"))
	draw_rect(Rect2(float(L),482,float(R-L),20),Color("2a3a44"))
	for x in range(L,R,520):
		draw_rect(Rect2(x-6,120,12,182),Color("2c3c46"))
		draw_rect(Rect2(x-56,86,112,36),Color("3a4c58"))
		for k in range(4):
			draw_circle(Vector2(x-38.0+float(k)*25.0,104),9,Color("fff0c0"))
		LabArt.soft_glow(self,Vector2(x,104),130,Color(1.0,0.96,0.78,0.42),0.9)
		_poly(PackedVector2Array([Vector2(x-56,122),Vector2(x+56,122),Vector2(x+190,620),Vector2(x-190,620)]),Color(1.0,0.95,0.75,0.020))
	draw_line(Vector2(L,250),Vector2(R,250),Color("1c2a32"),3)
	for x in range(L,R,72):
		var flag=Color(1.0,0.8,0.33,0.62) if (x/72)%2 else Color(0.33,0.85,1.0,0.62)
		_poly(PackedVector2Array([Vector2(x,251),Vector2(x+34,251),Vector2(x+17,283)]),flag)
	draw_rect(Rect2(float(L),502,float(R-L),7),Color("9aa8b0"))
	for x in range(L,R,90):
		draw_rect(Rect2(x,560,44,10),Color("ffcc55") if x%180==0 else Color("8aa0ad"))
		draw_rect(Rect2(x,592,58,12),Color("ffcc55") if x%180==0 else Color("8aa0ad"))

func _draw_lab() -> void:
	# Distant service gallery and wall modules establish three depth planes.
	draw_rect(Rect2(-2400,368,7200,252),Color(0.035,0.075,0.10,0.42))
	for x in range(-2200,4800,320):
		draw_rect(Rect2(x,384,220,112),Color("101f2a"))
		draw_rect(Rect2(x+8,392,204,96),Color("0d1a24"),false,2)
		draw_line(Vector2(x+18,472),Vector2(x+202,472),Color("29404b"),2)
		for led in range(3):
			draw_circle(Vector2(x+24+led*14,404),2,Color("4ce0bd") if (x/320+led)%4==0 else Color("3e5964"))
	# Ceiling bus and suspended luminaires.
	draw_rect(Rect2(-2400,72,7200,14),Color("09121a"))
	draw_line(Vector2(-2400,86),Vector2(4800,86),Color("31505a"),2)
	for x in range(-2200,4800,480):
		draw_rect(Rect2(x,110,15,510),Color("14222e"))
		draw_line(Vector2(x+15,110),Vector2(x+15,620),Color("233642"),2)
		LabArt.box(self,Rect2(x-65,94,145,10),Color("2f504e"),3)
		LabArt.glow_line(self,Vector2(x-56,98),Vector2(x+69,98),Color("86ead3"),2)
		var light_alpha=0.018+0.006*sin(x*0.01)
		draw_colored_polygon(PackedVector2Array([Vector2(x-60,109),Vector2(x+72,109),Vector2(x+150,520),Vector2(x-137,520)]),Color(0.3,0.9,0.78,light_alpha))
		LabArt.soft_glow(self,Vector2(x+6,101),72,Color(0.3,1.0,0.82,0.3),0.7)
	draw_string(font,Vector2(270,330),"KINETIC",HORIZONTAL_ALIGNMENT_LEFT,-1,70,Color("294251"))
	draw_string(font,Vector2(274,361),"L A B O R A T O R Y   /   0 1",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("577487"))
	draw_string(font,Vector2(1070,565),"01",HORIZONTAL_ALIGNMENT_LEFT,-1,100,Color("294251"))
	_floor(Color("1b2934"),Color("111c26"),Color("6b858d"))
	draw_line(Vector2(-2400,618),Vector2(4800,618),Color("bdd0cf"),2)
	# Floor seams and inset rails make contacts and movement easier to read.
	for x in range(-2400,4800,160):
		draw_line(Vector2(x,654),Vector2(x+112,654),Color("2b3d47"),1)
		draw_circle(Vector2(x+128,673),2,Color("637983"))
	draw_line(Vector2(-2400,682),Vector2(4800,682),Color("273c46"),3)
	for x in range(-2400,4800,28):
		draw_colored_polygon(PackedVector2Array([Vector2(x,639),Vector2(x+12,639),Vector2(x,651),Vector2(x-12,651)]),Color("927953"))

func _ticks() -> void:
	# Measurement ruler. Instrumentation belongs in the lab, not in a park, so
	# this is drawn for the lab backdrop only.
	for x in range(-2400,4800,128):
		draw_line(Vector2(x,605),Vector2(x,616),Color("809695"),1)
		draw_string(font,Vector2(x+7,603),str(x/128),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("5f7985"))

# --- Theme-driven ambience -------------------------------------------------

func mote_color() -> Color:
	match theme:
		"ice","bath","sky": return Color(0.92,0.98,1.0)
		"park","reef": return Color(0.72,1.0,0.78)
		"factory","quarry","canyon","rust","brass","dojo": return Color(1.0,0.84,0.56)
		"foundry": return Color(1.0,0.56,0.26)
		"magnet","void","arcade": return Color(0.78,0.58,1.0)
		"bounce": return Color(1.0,0.66,0.84)
		"storm","range","track": return Color(0.74,0.86,0.96)
		"neon": return Color(0.42,1.0,0.86)
		_: return Color(0.35,0.95,0.84)

func mote_strength() -> float:
	match theme:
		"void","sky": return 0.5
		"foundry","quarry","canyon","rust": return 1.4
		_: return 1.0

func has_scanner() -> bool:
	return theme=="lab" or theme=="" or theme=="range" or theme=="neon"
