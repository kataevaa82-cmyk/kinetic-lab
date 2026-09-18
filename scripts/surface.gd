class_name LabSurface
extends RefCounted

# Shared material geometry for every catalog family. No screen textures or
# renderer-specific post effects: the same vertices work in native and WebGL.
static var _rounds: Dictionary = {}
static var _spheres: Dictionary = {}
const KEY_LIGHT = Vector2(-0.55, -0.83)

static func contour(rect: Rect2, radius: float = 3.0, rounded: bool = false) -> PackedVector2Array:
	var r = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var key = Vector3(rect.size.x, rect.size.y, r if rounded else -r)
	var points: PackedVector2Array
	if _rounds.has(key):
		points = _rounds[key]
	else:
		points = PackedVector2Array()
		var corners = [Vector2(r,r), Vector2(rect.size.x-r,r), rect.size-Vector2(r,r), Vector2(r,rect.size.y-r)]
		for i in range(4):
			for j in range(6 if rounded else 2):
				var angle = PI + float(i) * PI * 0.5 + float(j) / (5.0 if rounded else 1.0) * PI * 0.5
				var p: Vector2 = corners[i] + Vector2.from_angle(angle) * r
				if points.is_empty() or not p.is_equal_approx(points[points.size()-1]): points.append(p)
		if points.size()>1 and points[0].is_equal_approx(points[points.size()-1]): points.remove_at(points.size()-1)
		if _rounds.size() < 512: _rounds[key] = points
	var result = PackedVector2Array()
	for p in points: result.append(p + rect.position)
	return result

static func polygon(c: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3: return
	var lo = points[0]
	var hi = points[0]
	for p in points:
		lo = lo.min(p)
		hi = hi.max(p)
	var size = (hi-lo).max(Vector2.ONE)
	var colors = PackedColorArray()
	for p in points:
		var uv = (p-lo)/size
		var shade = uv.y * 0.75 + uv.x * 0.25
		colors.append(color.lightened(0.19).lerp(color.darkened(0.28), shade))
	c.draw_polygon(points, colors)
	# Thin translucent marks, glass and flame retain their translucent edges.
	if color.a < 0.8 or minf(size.x,size.y) < 3.0: return
	var closed = points.duplicate()
	closed.append(points[0])
	c.draw_polyline(closed, color.darkened(0.55), 1.15, true)
	var clockwise = Geometry2D.is_polygon_clockwise(points)
	for i in range(points.size()):
		var a = points[i]
		var b = points[(i+1)%points.size()]
		if a.distance_squared_to(b) < 7.0: continue
		var normal = (b-a).normalized().orthogonal() * (-1.0 if clockwise else 1.0)
		var light = maxf(0.0, normal.dot(KEY_LIGHT))
		if light > 0.18:
			c.draw_line(a-normal*0.75, b-normal*0.75, Color(0.88,0.97,1.0,light*0.42*color.a), 1.0, true)

static func plate(c: CanvasItem, rect: Rect2, color: Color, radius: float = 3.0, border: Color = Color.TRANSPARENT, rounded: bool = false) -> void:
	var points = contour(rect, radius, rounded)
	polygon(c, points, color)
	if border.a > 0.0:
		points.append(points[0])
		c.draw_polyline(points, border, 1.0, true)

static func rect(c: CanvasItem, area: Rect2, color: Color, filled: bool = true, width: float = -1.0, antialiased: bool = true) -> void:
	if not filled or color.a < 0.8 or minf(area.size.x,area.size.y)<5.0:
		c.draw_rect(area,color,filled,width,antialiased)
	else:
		plate(c,area,color,minf(2.0,minf(area.size.x,area.size.y)*0.12))

static func line(c: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float = -1.0, _antialiased: bool = true) -> void:
	c.draw_line(from,to,color,width,true)
	if width < 3.5 or color.a < 0.8 or from.distance_squared_to(to) < 25.0: return
	var edge = (to-from).normalized().orthogonal()
	if edge.dot(KEY_LIGHT)<0: edge=-edge
	c.draw_line(from+edge*width*0.24,to+edge*width*0.24,color.lightened(0.24),maxf(0.8,width*0.22),true)

static func circle(c: CanvasItem, at: Vector2, radius: float, color: Color, filled: bool = true, width: float = -1.0, _antialiased: bool = true) -> void:
	if not filled or radius < 3.0 or color.a < 0.8:
		c.draw_circle(at,radius,color,filled,width,true)
		return
	var r = maxf(0.25,snappedf(radius,0.25))
	var key = str(color.to_rgba32())+":"+str(r)
	if not _spheres.has(key):
		if _spheres.size() >= 768:
			for old in _spheres.keys().slice(0,96): _spheres.erase(old)
		_spheres[key] = _sphere_mesh(r,color)
	c.draw_mesh(_spheres[key],null,Transform2D(0.0,at))

static func ellipse(c: CanvasItem, at: Vector2, radii: Vector2, color: Color) -> void:
	var r = maxf(radii.x,radii.y)
	var key = str(color.to_rgba32())+":"+str(snappedf(r,0.25))
	if not _spheres.has(key): _spheres[key]=_sphere_mesh(r,color)
	c.draw_mesh(_spheres[key],null,Transform2D(Vector2(radii.x/r,0),Vector2(0,radii.y/r),at))

static func recess(c: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	c.draw_circle(at,radius,color.darkened(0.62),true,-1,true)
	c.draw_arc(at,radius,0.0,PI,24,color.lightened(0.32),0.9,true)
	c.draw_arc(at,radius*0.75,PI,TAU,24,color.darkened(0.30),1.0,true)

static func _sphere_mesh(radius: float, color: Color) -> ArrayMesh:
	var verts = PackedVector2Array([Vector2.ZERO])
	var colors = PackedColorArray([color.lightened(0.10)])
	var indices = PackedInt32Array()
	var segments = 48
	var rings = [0.22,0.42,0.60,0.76,0.88,0.96,1.0,1.0+0.65/radius]
	var light = Vector3(-0.38,-0.52,0.76).normalized()
	for ring in range(rings.size()):
		var distance: float = rings[ring]
		for i in range(segments):
			var p = Vector2.from_angle(float(i)*TAU/float(segments))*distance
			verts.append(p*radius)
			var n = Vector3(p.x,p.y,sqrt(maxf(0.0,1.0-minf(1.0,distance)*minf(1.0,distance))))
			var diffuse = clampf(n.dot(light),0.0,1.0)
			var lit = color.darkened(0.48).lerp(color.lightened(0.22),diffuse)
			var specular = pow(maxf(0.0,n.dot(Vector3(-0.22,-0.30,0.93).normalized())),34.0)*0.38
			lit = lit.lightened(specular)
			lit.a = 0.0 if ring==rings.size()-1 else color.a
			colors.append(lit)
			var current = 1+ring*segments+i
			var next = 1+ring*segments+(i+1)%segments
			if ring==0:
				indices.append_array(PackedInt32Array([0,current,next]))
			else:
				indices.append_array(PackedInt32Array([current-segments,current,next,next,current-segments,next-segments]))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	return mesh
