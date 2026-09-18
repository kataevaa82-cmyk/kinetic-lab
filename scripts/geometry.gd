class_name LabGeometry
extends RefCounted

# Authoring bounds, excluding glow, arrows, antennae and exhaust. Artwork is
# fitted per axis to the existing physical dimensions (long beams must not
# grow thicker, and a conveyor's invisible collision must not extend past it).
const FRAMES = {
	"crate":Rect2(-22,-22,44,44), "barrel":Rect2(-18,-27,36,54),
	"plank":Rect2(-30,-8,60,16), "metal":Rect2(-25,-19,50,38),
	"thruster":Rect2(-14,-25,28,48), "mine":Rect2(-25,-8,50,22),
	"magnet":Rect2(-24,-24,48,42), "fan":Rect2(-24,-25,48,50),
	"coil":Rect2(-20,-31,40,59), "sticky":Rect2(-14,-9,28,18),
	"glass":Rect2(-34,-7,68,14), "trampoline":Rect2(-36,-8,72,24),
	"weight":Rect2(-24,-32,48,53), "balloon":Rect2(-18,-25,36,42),
	"wheel":Rect2(-26,-26,52,52), "bumper":Rect2(-25,-25,50,50),
	"c4":Rect2(-16,-10,32,20), "laser_cutter":Rect2(-22,-12,44,24),
	"singularity":Rect2(-18,-18,36,36), "drone":Rect2(-26,-16,52,32),
	"rubber":Rect2(-18,-18,36,36), "ice":Rect2(-22,-12,44,24),
	"soap":Rect2(-18,-10,36,20), "sponge":Rect2(-20,-16,40,32),
	"anvil":Rect2(-24,-14,52,32), "feather":Rect2(-21,-12,40,25),
	"spring_block":Rect2(-22,-9,44,18), "pillow":Rect2(-22,-14,44,28),
	"slime":Rect2(-22,-12,45,26), "cork":Rect2(-16,-16,32,32),
	"brick":Rect2(-22,-12,44,24), "crystal":Rect2(-12,-20,24,38),
	"tire":Rect2(-18,-18,36,36), "gyro":Rect2(-18,-18,36,36),
	"dice":Rect2(-14,-14,28,28), "sandbag":Rect2(-20,-21,40,36),
	"gel":Rect2(-16,-16,32,32), "lead":Rect2(-16,-16,32,32),
	"paper":Rect2(-22,-8,44,16), "honeycomb":Rect2(-20,-20,40,35),
	"conveyor":Rect2(-28,-8,56,16), "spinner_pad":Rect2(-18,-18,36,36),
	"updraft":Rect2(-16,-16,32,32), "chiller":Rect2(-20,-14,40,28),
	"vacuum_box":Rect2(-20,-16,40,32), "shaker":Rect2(-16,-14,32,35),
	"pulsar":Rect2(-18,-18,36,36), "lift":Rect2(-26,-9,52,19),
	"speaker":Rect2(-14,-16,28,32), "grav_well":Rect2(-18,-18,36,36),
	"hover_pad":Rect2(-26,-7,52,14), "zapper":Rect2(-17,-17,34,34),
	"metronome":Rect2(-13,-19,26,36), "pump":Rect2(-15,-21,30,37),
	"scatter_pad":Rect2(-24,-8,48,16), "slow_field":Rect2(-18,-18,36,36),
	"boost_pad":Rect2(-26,-8,52,16), "rotator":Rect2(-18,-18,36,36),
	"magnet_pad":Rect2(-24,-8,48,16), "thump":Rect2(-22,-12,44,22),
	"gas_can":Rect2(-17,-23,34,46), "battery":Rect2(-26,-15,52,30),
	"cable":Rect2(-27,-5,54,10), "firework":Rect2(-9,-31,18,45),
	"extinguisher":Rect2(-13,-28,26,50)
}

const SHAPED = ["head","torso","pelvis","arm","leg","anvil","feather","slime","crystal","magnet","metronome","soap","pillow","ice","rubber","mine","balloon"]
const ROUND = ["wheel","bumper","singularity"]

static func frame(kind: String) -> Rect2:
	return FRAMES.get(kind,Rect2(-22,-22,44,44))

static func outline(kind: String, size: Vector2) -> PackedVector2Array:
	var half=size*0.5
	var points=PackedVector2Array()
	match kind:
		"head": return LabSurface.contour(Rect2(-half,size),size.x*0.27,true)
		"torso":
			points=PackedVector2Array([Vector2(-0.36,-0.5),Vector2(0.36,-0.5),Vector2(0.5,-0.35),Vector2(0.43,0.2),Vector2(0.32,0.5),Vector2(-0.32,0.5),Vector2(-0.43,0.2),Vector2(-0.5,-0.35)])
		"pelvis":
			points=PackedVector2Array([Vector2(-0.38,-0.5),Vector2(0.38,-0.5),Vector2(0.5,-0.25),Vector2(0.38,0.5),Vector2(-0.38,0.5),Vector2(-0.5,-0.25)])
		"arm","leg":
			points=PackedVector2Array([Vector2(-0.28,-0.5),Vector2(0.28,-0.5),Vector2(0.5,-0.36),Vector2(0.38,0.31),Vector2(0.32,0.5),Vector2(-0.32,0.5),Vector2(-0.38,0.31),Vector2(-0.5,-0.36)])
		"crystal": points=PackedVector2Array([Vector2(0,-0.5),Vector2(0.5,0.132),Vector2(0,0.5),Vector2(-0.5,0.132)])
		"metronome": points=PackedVector2Array([Vector2(0,-0.5),Vector2(0.5,0.5),Vector2(-0.5,0.5)])
		"anvil","feather","slime","magnet":
			match kind:
				"anvil": points=PackedVector2Array([Vector2(-24,-14),Vector2(16,-14),Vector2(28,-8),Vector2(18,-3),Vector2(10,-3),Vector2(6,4),Vector2(12,11),Vector2(14,18),Vector2(-22,18),Vector2(-20,11),Vector2(-12,6),Vector2(-11,-3),Vector2(-24,-3)])
				"feather": points=PackedVector2Array([Vector2(-21,13),Vector2(-14,0),Vector2(-6,-8),Vector2(5,-12),Vector2(19,-12),Vector2(15,-3),Vector2(9,6),Vector2(-3,11)])
				"slime": points=PackedVector2Array([Vector2(-22,10),Vector2(-19,1),Vector2(-14,-7),Vector2(-6,-12),Vector2(6,-11),Vector2(14,-6),Vector2(18,2),Vector2(23,10),Vector2(14,14),Vector2(5,12),Vector2(-3,14),Vector2(-12,12)])
				"magnet": points=PackedVector2Array([Vector2(-24,18),Vector2(-24,-8),Vector2(-19,-19),Vector2(-9,-24),Vector2(9,-24),Vector2(19,-19),Vector2(24,-8),Vector2(24,18),Vector2(13,18),Vector2(13,-7),Vector2(9,-13),Vector2(-9,-13),Vector2(-13,-7),Vector2(-13,18)])
			var f=frame(kind)
			for i in range(points.size()): points[i]=(points[i]-f.get_center())*size/f.size
			return points
		"soap","pillow","rubber": return LabSurface.contour(Rect2(-half,size),minf(size.x,size.y)*0.30,true)
		"ice": return LabSurface.contour(Rect2(-half,size),3.0)
		"mine": points=PackedVector2Array([Vector2(-0.5,0.12),Vector2(-0.36,-0.32),Vector2(-0.18,-0.5),Vector2(0.18,-0.5),Vector2(0.36,-0.32),Vector2(0.5,0.12),Vector2(0.4,0.5),Vector2(-0.4,0.5)])
		"balloon":
			for i in range(32): points.append(Vector2.from_angle(float(i)*TAU/32.0)*Vector2(0.5,0.48))
		_: return PackedVector2Array([-half,Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)])
	for i in range(points.size()): points[i]*=size
	return points

static func add_shapes(body: RigidBody2D, kind: String, size: Vector2) -> bool:
	if kind in ROUND:
		var cs=CollisionShape2D.new()
		var circle=CircleShape2D.new()
		circle.radius=size.x*0.5
		cs.shape=circle
		body.add_child(cs)
		return true
	if kind not in SHAPED: return false
	var pieces=Geometry2D.decompose_polygon_in_convex(outline(kind,size))
	for points in pieces:
		var cs=CollisionShape2D.new()
		var polygon=ConvexPolygonShape2D.new()
		polygon.points=points
		cs.shape=polygon
		body.add_child(cs)
	return not pieces.is_empty()
