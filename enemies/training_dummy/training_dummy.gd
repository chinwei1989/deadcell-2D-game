class_name TrainingDummy
extends Node2D
## Practice target for tuning combat: flashes on hits, shows posture, staggers when
## posture breaks (a blade hit then executes it), and resets instead of dying.
## Origin is at its feet.

const BASE_COLOR := Color("8aa1ad")
const FLASH_COLOR := Color.WHITE
const STAGGER_COLOR := Color("4fd1c5")
const FLASH_TIME := 0.05
const RESET_DELAY := 0.6
## Extra damage taken while staggered.
const STAGGER_DAMAGE_MULTIPLIER := 1.5

var _flash_left: float = 0.0
var _reset_left: float = 0.0
var _body_kick: Vector2 = Vector2.ZERO

@onready var _health: HealthComponent = $Health
@onready var _posture: PostureComponent = $Posture
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _body: Polygon2D = $Body
@onready var _posture_fill: ColorRect = $PostureBar/Fill
@onready var _posture_bar_width: float = ($PostureBar as ColorRect).size.x


func _ready() -> void:
	add_to_group(&"targets")
	_hurtbox.received.connect(_on_hit)
	_posture.broken.connect(func() -> void: Events.posture_broken.emit(self))
	_health.died.connect(_on_died)


func _process(delta: float) -> void:
	_flash_left = maxf(_flash_left - delta, 0.0)
	if _reset_left > 0.0:
		_reset_left -= delta
		if _reset_left <= 0.0:
			_health.reset()
			visible = true
	if _flash_left > 0.0:
		_body.color = FLASH_COLOR
	elif _posture.is_staggered():
		_body.color = STAGGER_COLOR
	else:
		_body.color = BASE_COLOR
	_body_kick = _body_kick.move_toward(Vector2.ZERO, 40.0 * delta)
	_body.position = _body_kick.round()
	_posture_fill.size.x = _posture_bar_width * _posture.value / _posture.max_posture


func _on_hit(info: DamageInfo) -> void:
	if _health.is_dead():
		return
	if info.can_execute and _posture.is_staggered():
		info.executed = true
		info.killed = true
		Events.enemy_executed.emit(self, info.source)
		_health.damage(_health.current)
		return
	var multiplier := STAGGER_DAMAGE_MULTIPLIER if _posture.is_staggered() else 1.0
	_posture.add(info.posture)
	info.killed = _health.damage(info.amount * multiplier)
	_flash_left = FLASH_TIME
	_body_kick = info.knockback.normalized() * 3.0
	Events.enemy_damaged.emit(self, info)


func _on_died() -> void:
	Events.enemy_killed.emit(self)
	visible = false
	_reset_left = RESET_DELAY
