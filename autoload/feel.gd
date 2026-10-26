extends Node
## Local-only game feel: hit freeze, screen shake, slow motion, and one-shot effects
## (impact sparks, cut marks, dust, afterimages) (PLAN.md sections 5 and 16). Never changes
## state other peers can see. Slow motion uses Engine.time_scale, so it is solo-only;
## co-op Focus will slow only nearby enemies (PLAN.md section 28.1).

const HOT := Color(1.0, 0.353, 0.212)
const AMBER := Color(0.949, 0.647, 0.255)
const WHITE_HOT := Color(1.0, 0.97, 0.88)
const DUST := Color(0.541, 0.631, 0.678)
const OIL := Color(0.07, 0.13, 0.16)
## Colors above 1.0 glow through the bloom (rendering/viewport/hdr_2d is on).
const GLOW := 1.5

var _frozen: Dictionary = {}
var _additive: CanvasItemMaterial
var _light_texture: GradientTexture2D


## Pauses physics on the given nodes for a number of physics ticks (real time). Freezing
## the attacker also pauses its attack timeline, which is what makes hits feel heavy.
func hit_freeze(nodes: Array, frames: int) -> void:
	if frames <= 0:
		return
	for node: Variant in nodes:
		if node is Node and is_instance_valid(node):
			_frozen[node] = maxi(int(_frozen.get(node, 0)), frames)
			(node as Node).set_physics_process(false)


func shake(trauma: float) -> void:
	Events.screen_shake.emit(trauma)


func flash(strength: float) -> void:
	Events.screen_flash.emit(strength)


## A blade hit: a burst of sparks flying along `direction` and a bright cut mark across
## the target. strength 0..1 (light hit → execution).
func impact(at: Vector2, direction: Vector2, strength: float, color: Color = HOT) -> void:
	var sparks := _particles(at, 8 + int(22 * strength), 0.28, direction, 55.0, 140.0, 360.0 + 200.0 * strength)
	sparks.gravity = Vector2(0.0, 500.0)
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.0 + strength
	sparks.color_ramp = _ramp([WHITE_HOT * GLOW, color * 1.5, Color(color, 0.0)])
	var cut := Line2D.new()
	var half := direction.normalized().rotated(deg_to_rad(randf_range(-25.0, 25.0))) * (14.0 + 18.0 * strength)
	cut.points = PackedVector2Array([at - half, at + half])
	cut.width = 2.0 + 3.0 * strength
	cut.default_color = WHITE_HOT * GLOW
	cut.material = _additive_material()
	cut.z_index = 6
	_spawn(cut, 0.0)
	var tween := cut.create_tween().set_parallel()
	tween.tween_property(cut, ^"width", 0.0, 0.14)
	tween.tween_property(cut, ^"modulate", Color(color, 0.0), 0.14)
	tween.chain().tween_callback(cut.queue_free)
	light_flash(at, color, 30.0 + 30.0 * strength, 0.25 + 0.45 * strength)


## A brief point of light that brightens everything around a hit or explosion.
func light_flash(at: Vector2, color: Color, radius: float, energy: float, duration: float = 0.14) -> void:
	var light := PointLight2D.new()
	light.texture = _light()
	light.texture_scale = radius / 64.0
	light.color = color
	light.energy = energy
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.height = 16.0
	light.global_position = at
	_spawn(light, 0.0)
	var tween := light.create_tween()
	tween.tween_property(light, ^"energy", 0.0, duration)
	tween.tween_callback(light.queue_free)


## A number popping out of a hit target. Crits and executions are bigger and amber.
func damage_number(at: Vector2, amount: float, crit: bool) -> void:
	if amount <= 0.0:
		return
	var label := Label.new()
	label.text = str(roundi(amount))
	label.add_theme_font_size_override("font_size", 16 if crit else 8) # Pixel font: multiples of 8.
	label.add_theme_color_override("font_color", AMBER * (GLOW if crit else 1.2) if crit else WHITE_HOT)
	label.z_index = 10
	label.position = at + Vector2(randf_range(-6.0, 6.0) - 10.0, 0.0)
	var scene := get_tree().current_scene
	if scene == null:
		return
	scene.add_child(label)
	label.pivot_offset = Vector2(10.0, 8.0)
	label.scale = Vector2(1.6, 1.6)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, ^"scale", Vector2.ONE, 0.1)
	tween.tween_property(label, ^"position:y", label.position.y - 22.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, ^"modulate:a", 0.0, 0.25).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


## An expanding glowing ring on the ground (slam shockwave).
func ring(at: Vector2, radius: float, color: Color = AMBER) -> void:
	var line := Line2D.new()
	var points := PackedVector2Array()
	for i in 25:
		var angle := TAU * i / 24.0
		points.append(Vector2(cos(angle), sin(angle) * 0.3)) # Flattened: seen from the side.
	line.points = points
	line.width = 0.12
	line.default_color = color * GLOW
	line.material = _additive_material()
	line.global_position = at
	line.scale = Vector2(4.0, 4.0)
	line.z_index = 6
	_spawn(line, 0.0)
	var tween := line.create_tween().set_parallel()
	tween.tween_property(line, ^"scale", Vector2(radius, radius), 0.22).set_ease(Tween.EASE_OUT)
	tween.tween_property(line, ^"modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(line.queue_free)
	light_flash(at, color, radius, 0.6, 0.2)


## An enemy breaking apart: glowing scrap flying out, a light flash, and dark oil
## splattered on the ground below that stays for a while.
func death_burst(at: Vector2, color: Color, size: float = 1.0) -> void:
	var scrap := _particles(at, int(24 * size), 0.7, Vector2.UP, 160.0, 120.0, 320.0 * size)
	scrap.gravity = Vector2(0.0, 700.0)
	scrap.scale_amount_min = 1.5
	scrap.scale_amount_max = 3.5
	scrap.angular_velocity_min = -720.0
	scrap.angular_velocity_max = 720.0
	scrap.color_ramp = _ramp([WHITE_HOT * GLOW, color * 1.4, Color(color, 0.0)])
	var oil := _particles(at, int(14 * size), 0.5, Vector2.UP, 120.0, 60.0, 180.0)
	oil.gravity = Vector2(0.0, 600.0)
	oil.scale_amount_min = 2.0
	oil.scale_amount_max = 4.0
	oil.material = null
	oil.color_ramp = _ramp([OIL, OIL, Color(OIL, 0.0)])
	light_flash(at, color, 60.0 * size, 0.8, 0.3)
	_splatter(at, size)


func _splatter(at: Vector2, size: float) -> void:
	var scene := get_tree().current_scene as CanvasItem
	if scene == null:
		return
	var space: PhysicsDirectSpaceState2D = scene.get_world_2d().direct_space_state
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters2D.create(at, at + Vector2(0.0, 120.0), Layers.WORLD | Layers.ONE_WAY))
	if hit.is_empty():
		return
	var ground: Vector2 = hit["position"]
	for i in int(5 * size):
		var blob := Polygon2D.new()
		var w := randf_range(3.0, 9.0) * size
		blob.polygon = PackedVector2Array([Vector2(-w, 0), Vector2(w, 0), Vector2(w * 0.6, -2), Vector2(-w * 0.7, -2)])
		blob.color = OIL
		blob.global_position = ground + Vector2(randf_range(-22.0, 22.0) * size, 0.5)
		blob.z_index = 1
		_spawn(blob, 0.0)
		var tween := blob.create_tween()
		tween.tween_interval(12.0)
		tween.tween_property(blob, ^"modulate:a", 0.0, 3.0)
		tween.tween_callback(blob.queue_free)


## A burst of flame (fire-blade hits; bigger for finishers and executions).
func fire_burst(at: Vector2, strength: float) -> void:
	var fire := _particles(at, 10 + int(30 * strength), 0.4 + 0.2 * strength, Vector2.UP, 180.0,
		40.0, 120.0 + 160.0 * strength)
	fire.texture = LevelLight.radial_texture()
	fire.gravity = Vector2(0.0, -220.0)
	fire.damping_min = 60.0
	fire.damping_max = 120.0
	fire.scale_amount_min = 0.07
	fire.scale_amount_max = 0.12 + 0.1 * strength
	var size := Curve.new()
	size.add_point(Vector2(0.0, 0.5))
	size.add_point(Vector2(0.2, 1.0))
	size.add_point(Vector2(1.0, 0.1))
	fire.scale_amount_curve = size
	fire.color_ramp = _ramp([Color(1.0, 0.9, 0.6) * GLOW, Color(1.0, 0.6, 0.15) * 1.3, Color(0.9, 0.25, 0.05, 0.7), Color(0.3, 0.03, 0.0, 0.0)])
	light_flash(at, Color(1.0, 0.55, 0.15), 50.0 + 60.0 * strength, 0.6 + 0.8 * strength, 0.25)


## Burning embers flung from a fire-blade hit, drifting upward as they fade.
func embers(at: Vector2, amount: int) -> void:
	var sparks := _particles(at, amount, 0.7, Vector2.UP, 70.0, 30.0, 110.0)
	sparks.gravity = Vector2(0.0, -60.0)
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.0
	sparks.color_ramp = _ramp([Color(1.0, 0.86, 0.55) * GLOW, Color(1.0, 0.55, 0.15), Color(1.0, 0.42, 0.08, 0.0)])


## A puff of dust at someone's feet (jumps, landings, dodges).
func dust(at: Vector2, amount: int = 8, spread_x: float = 1.0) -> void:
	var puff := _particles(at, amount, 0.35, Vector2.UP, 80.0, 30.0, 70.0)
	puff.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	puff.emission_rect_extents = Vector2(6.0 * spread_x, 1.0)
	puff.gravity = Vector2(0.0, -20.0)
	puff.scale_amount_min = 1.0
	puff.scale_amount_max = 2.5
	puff.material = null # Dust isn't glowing.
	puff.color_ramp = _ramp([Color(DUST, 0.6), Color(DUST, 0.0)])


## A fading copy of a sprite frame (afterimages behind fast moves).
func afterimage(texture: Texture2D, at: Vector2, offset: Vector2, flip_x: bool, color: Color, duration: float = 0.22) -> void:
	var ghost := Sprite2D.new()
	ghost.texture = texture
	ghost.centered = false
	ghost.offset = offset
	ghost.flip_h = flip_x
	if flip_x:
		ghost.offset.x = -offset.x - texture.get_width()
	ghost.global_position = at
	ghost.modulate = Color(color, 0.55)
	ghost.material = _additive_material()
	ghost.z_index = -1
	_spawn(ghost, 0.0)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, ^"modulate:a", 0.0, duration)
	tween.tween_callback(ghost.queue_free)


func _particles(at: Vector2, amount: int, lifetime: float, direction: Vector2, spread: float,
		speed_min: float, speed_max: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.global_position = at
	p.amount = maxi(amount, 1)
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	p.spread = spread
	p.initial_velocity_min = speed_min
	p.initial_velocity_max = speed_max
	p.material = _additive_material()
	p.z_index = 6
	_spawn(p, lifetime + 0.1)
	p.emitting = true
	return p


## Adds an effect to the current scene; frees it after `lifetime` seconds (0 = it frees itself).
func _spawn(node: Node2D, lifetime: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		node.queue_free()
		return
	var position_before := node.global_position
	scene.add_child(node)
	node.global_position = position_before
	if lifetime > 0.0:
		get_tree().create_timer(lifetime, true, false, true).timeout.connect(node.queue_free)


func _ramp(colors: Array[Color]) -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, colors[0])
	gradient.set_color(1, colors[colors.size() - 1])
	for i in range(1, colors.size() - 1):
		gradient.add_point(float(i) / (colors.size() - 1), colors[i])
	return gradient


func _light() -> GradientTexture2D:
	if _light_texture == null:
		_light_texture = GradientTexture2D.new()
		_light_texture.width = 128
		_light_texture.height = 128
		_light_texture.fill = GradientTexture2D.FILL_RADIAL
		_light_texture.fill_from = Vector2(0.5, 0.5)
		_light_texture.fill_to = Vector2(1.0, 0.5)
		_light_texture.gradient = _ramp([Color.WHITE, Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0)])
	return _light_texture


func _additive_material() -> CanvasItemMaterial:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive


func set_slow_motion(enabled: bool, scale: float = 1.0) -> void:
	Engine.time_scale = scale if enabled else 1.0
	Audio.set_slow_motion(enabled)
	Events.focus_changed.emit(enabled)


func _physics_process(_delta: float) -> void:
	for node: Variant in _frozen.keys():
		if not is_instance_valid(node):
			_frozen.erase(node)
			continue
		_frozen[node] = int(_frozen[node]) - 1
		if int(_frozen[node]) <= 0:
			_frozen.erase(node)
			(node as Node).set_physics_process(true)
