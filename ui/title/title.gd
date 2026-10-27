class_name TitleScreen
extends Node2D
## The title screen: the Ronin on a rooftop edge with the burning katana, the city drifting
## behind in the rain, the game's name and the menu (start a run, controls, quit).

const RONIN := "res://art/sprites/ronin.png"
## The world is drawn at 2x (camera zoom), so these are in half-screen pixels.
const ZOOM := 2.0
const LEDGE_Y := 62.0
const HERO_X := -96.0
## Camera-equivalent pixels per second the city drifts (each layer moves by its factor).
const DRIFT_SPEED := 300.0
const VERSION := "DEMO 0.1"

var _city: ParallaxBackdrop
var _hero: AnimatedSprite2D
var _fire: FireBlade
var _controls: PanelContainer
var _menu: VBoxContainer


func _ready() -> void:
	var camera := Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS # Physics interpolation is on.
	camera.zoom = Vector2(ZOOM, ZOOM)
	add_child(camera)
	camera.make_current()
	_city = Menu.backdrop(self)
	Audio.play_music("res://audio/music/neon_rain.wav")
	Audio.play_ambience("res://audio/sfx/rain_loop.wav")
	_build_rooftop()
	_build_hero()
	_build_ui()


func _process(delta: float) -> void:
	_city.drift += DRIFT_SPEED * delta
	var origin := SpriteSheet.origin(RONIN)
	var bases := SpriteSheet.track(RONIN, _hero.animation, &"blade_base")
	var tips := SpriteSheet.track(RONIN, _hero.animation, &"blade_tip")
	if not tips.is_empty():
		var frame := clampi(_hero.frame, 0, tips.size() - 1)
		_fire.intensity = 0.25
		_fire.set_blade(_hero.global_position + bases[frame] - origin, _hero.global_position + tips[frame] - origin)
	if Input.is_action_just_pressed(&"help"):
		_toggle_controls()


func _build_rooftop() -> void:
	var roof := Polygon2D.new()
	roof.color = Color("0b1620")
	roof.polygon = PackedVector2Array([
		Vector2(-400, LEDGE_Y), Vector2(-50, LEDGE_Y), Vector2(-44, LEDGE_Y + 5), Vector2(-44, 400), Vector2(-400, 400),
	])
	add_child(roof)
	var lip := Line2D.new()
	lip.points = PackedVector2Array([Vector2(-400, LEDGE_Y + 0.5), Vector2(-50, LEDGE_Y + 0.5)])
	lip.width = 1.0
	lip.default_color = Color("3f7a80")
	add_child(lip)
	var sign_light := LevelLight.new()
	sign_light.kind = LevelLight.Kind.NEON
	sign_light.position = Vector2(-70, LEDGE_Y + 22)
	add_child(sign_light)


func _build_hero() -> void:
	_hero = AnimatedSprite2D.new()
	_hero.sprite_frames = SpriteSheet.frames(RONIN)
	_hero.centered = false
	_hero.offset = -SpriteSheet.origin(RONIN)
	_hero.material = SpriteSheet.material(RONIN)
	_hero.position = Vector2(HERO_X, LEDGE_Y - Player.HALF_HEIGHT)
	add_child(_hero)
	_hero.play(&"idle")
	_fire = FireBlade.new()
	add_child(_fire)


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	var title := Hud.make_label(40, Color(1.0, 0.5, 0.16) * 1.25, HORIZONTAL_ALIGNMENT_CENTER)
	title.text = "LAST EDGE"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -200.0
	title.offset_right = 200.0
	title.offset_top = 46.0
	ui.add_child(title)
	var tagline := Hud.make_label(8, Color("b8c7cf"), HORIZONTAL_ALIGNMENT_CENTER)
	tagline.text = "THE MACHINES ARE NOT EVIL. THEY ARE CERTAIN."
	tagline.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tagline.offset_left = -200.0
	tagline.offset_right = 200.0
	tagline.offset_top = 92.0
	ui.add_child(tagline)
	ui.add_child(_title_embers())

	_menu = VBoxContainer.new()
	_menu.set_anchors_preset(Control.PRESET_CENTER)
	_menu.offset_left = 20.0
	_menu.offset_right = 220.0
	_menu.offset_top = 0.0
	_menu.add_theme_constant_override("separation", 2)
	ui.add_child(_menu)
	var start := Menu.button("START RUN", _start_run)
	_menu.add_child(start)
	_menu.add_child(Menu.button("CONTROLS", _toggle_controls))
	if not OS.has_feature("web"):
		_menu.add_child(Menu.button("QUIT", func() -> void: get_tree().quit()))
	start.grab_focus.call_deferred()

	_controls = Hud.make_controls_panel()
	_controls.offset_top = -78.0
	_controls.offset_bottom = -46.0
	_controls.visible = false
	ui.add_child(_controls)

	var footer := Hud.make_label(8, Color("5c6f7a"), HORIZONTAL_ALIGNMENT_RIGHT)
	footer.text = VERSION
	footer.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	footer.offset_left = -200.0
	footer.offset_top = -16.0
	footer.offset_right = -8.0
	ui.add_child(footer)


## Sparks rising past the title, as if it were forged.
func _title_embers() -> CPUParticles2D:
	var embers := CPUParticles2D.new()
	embers.position = Vector2(320, 90)
	embers.amount = 40
	embers.lifetime = 2.2
	embers.preprocess = 2.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(110, 6)
	embers.direction = Vector2.UP
	embers.spread = 25.0
	embers.gravity = Vector2(0, -12)
	embers.initial_velocity_min = 8.0
	embers.initial_velocity_max = 26.0
	embers.scale_amount_max = 1.5
	var ramp := Gradient.new()
	ramp.set_color(0, Feel.WHITE_HOT * Feel.GLOW)
	ramp.set_color(1, Color(Feel.HOT, 0.0))
	ramp.add_point(0.4, Feel.AMBER * 1.3)
	embers.color_ramp = ramp
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	embers.material = additive
	return embers


func _toggle_controls() -> void:
	_controls.visible = not _controls.visible


func _start_run() -> void:
	RunState.start_run()
	Game.goto(&"run", Game.Mode.IN_RUN)
