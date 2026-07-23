extends CharacterBody2D
## Combattant ninja — duel souls-like (timing / chakra / techniques).

enum State { IDLE, RUN, JUMP, ATTACK, DODGE, SUBSTITUTE, HURT, DEAD, WALL_SLIDE }

@export var player_id: int = 1
@export var facing: int = 1
@export var tint: Color = Color(1, 1, 1, 1)

@export_group("Movement")
@export var move_speed: float = 140.0
@export var jump_velocity: float = -320.0
@export var gravity: float = 900.0
@export var max_falls_speed: float = 420.0

@export_group("Combat")
@export var max_health: float = 100.0
@export var max_chakra: float = 100.0
@export var chakra_regen: float = 8.0
@export var light_damage: float = 10.0
@export var heavy_damage: float = 22.0
@export var special_damage: float = 36.0
@export var kunai_chakra_cost: float = 12.0
@export var substitute_chakra_cost: float = 22.0
@export var special_chakra_cost: float = 40.0
@export var dodge_chakra_cost: float = 8.0
@export var substitute_distance: float = 56.0

const LIGHT_STARTUP := 0.08
const LIGHT_ACTIVE := 0.10
const LIGHT_RECOVERY := 0.18
const HEAVY_STARTUP := 0.22
const HEAVY_ACTIVE := 0.12
const HEAVY_RECOVERY := 0.42
const SPECIAL_STARTUP := 0.18
const SPECIAL_ACTIVE := 0.16
const SPECIAL_RECOVERY := 0.35
const DODGE_DURATION := 0.32
const DODGE_IFRAMES := 0.22
const SUBSTITUTE_DURATION := 0.18
const HURT_DURATION := 0.28
const HITSTOP := 0.05

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var spawn_point: Marker2D = $ProjectileSpawn

var health: float
var chakra: float
var state: State = State.IDLE
var invulnerable: bool = false
var attack_locked: bool = false

var _prefix: String = "p1"
var _mudra := MudraBuffer.new()
var _state_time: float = 0.0
var _attack_kind: String = ""
var _attack_damage: float = 0.0
var _hit_connected: bool = false
var _spawn_pos: Vector2
var _kunai_scene: PackedScene
var _fireball_scene: PackedScene
var _log_scene: PackedScene
var _was_on_floor: bool = true
var _dir_pressed: Dictionary = {"left": false, "right": false, "up": false, "down": false}
var _special_projectile_spawned: bool = false
const SPRITE_Y_48 := -15.0
const SPRITE_Y_64 := -15.0


func _ready() -> void:
	health = max_health
	chakra = max_chakra
	_prefix = "p1" if player_id == 1 else "p2"
	_spawn_pos = global_position
	_kunai_scene = preload("res://scenes/kunai.tscn")
	_fireball_scene = preload("res://scenes/fireball.tscn")
	_log_scene = preload("res://scenes/substitution_log.tscn")
	sprite.sprite_frames = SpriteSheets.build()
	sprite.modulate = tint
	sprite.position.y = SPRITE_Y_48
	sprite.play("idle")
	hitbox.add_to_group("fighter_hitbox")
	hurtbox.add_to_group("fighter_hurtbox")
	hitbox_shape.disabled = true
	hitbox.monitoring = true
	hitbox.monitorable = true
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	_mudra.sequence_changed.connect(_on_mudra_sequence)
	_mudra.special_armed.connect(_on_mudra_armed)
	_apply_facing()
	_emit_stats()


func _physics_process(delta: float) -> void:
	if not GameBus.match_active and state != State.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_state_time += delta
	if state != State.DEAD:
		chakra = minf(max_chakra, chakra + chakra_regen * delta)

	_poll_mudra_directions()
	_handle_action_inputs()

	match state:
		State.IDLE, State.RUN:
			_process_grounded(delta)
		State.JUMP:
			_process_air(delta)
		State.ATTACK:
			_process_attack(delta)
		State.DODGE:
			_process_dodge(delta)
		State.SUBSTITUTE:
			_process_substitute(delta)
		State.HURT:
			_process_hurt(delta)
		State.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			velocity.y = minf(velocity.y + gravity * delta, max_falls_speed)
			move_and_slide()
		State.WALL_SLIDE:
			_process_wall_slide(delta)

	_was_on_floor = is_on_floor()
	_emit_stats()


func reset_round(pos: Vector2) -> void:
	global_position = pos
	_spawn_pos = pos
	health = max_health
	chakra = max_chakra
	velocity = Vector2.ZERO
	invulnerable = false
	attack_locked = false
	hitbox_shape.disabled = true
	_mudra.reset()
	visible = true
	_enter_state(State.IDLE)
	_emit_stats()


func take_hit(amount: float, knockback: Vector2, from_facing: int) -> void:
	if state == State.DEAD or invulnerable:
		return
	health = maxf(0.0, health - amount)
	velocity = knockback
	facing = -from_facing
	_apply_facing()
	hitbox_shape.disabled = true
	if health <= 0.0:
		_enter_state(State.DEAD)
		GameBus.fighter_defeated.emit(self)
	else:
		_enter_state(State.HURT)
	_emit_stats()


func _handle_action_inputs() -> void:
	if state in [State.DEAD, State.HURT, State.SUBSTITUTE]:
		return
	if state == State.ATTACK or state == State.DODGE:
		return

	if Input.is_action_just_pressed("%s_special" % _prefix):
		_try_special()
		return
	if Input.is_action_just_pressed("%s_substitute" % _prefix):
		_try_substitute()
		return
	if Input.is_action_just_pressed("%s_dodge" % _prefix):
		_try_dodge()
		return
	if Input.is_action_just_pressed("%s_throw" % _prefix):
		_try_throw()
		return
	if Input.is_action_just_pressed("%s_attack_heavy" % _prefix):
		_start_attack("heavy")
		return
	if Input.is_action_just_pressed("%s_attack_light" % _prefix):
		_start_attack("light")
		return
	if Input.is_action_just_pressed("%s_jump" % _prefix) and is_on_floor():
		velocity.y = jump_velocity
		_enter_state(State.JUMP)


func _poll_mudra_directions() -> void:
	if state in [State.DEAD, State.HURT]:
		return
	var now := Time.get_ticks_msec() / 1000.0
	for dir in ["left", "right", "up", "down"]:
		var action := "%s_%s" % [_prefix, dir]
		var pressed := Input.is_action_pressed(action)
		if pressed and not _dir_pressed[dir]:
			# Mudras only count when not just used as pure locomotion spam:
			# up/down always count; left/right count if also holding special intent via double-tap window
			# Simpler: always record direction taps (just_pressed equivalent via edge detect).
			_mudra.push_direction(dir, now)
		_dir_pressed[dir] = pressed


func _process_grounded(delta: float) -> void:
	var axis := _move_axis()
	velocity.x = axis * move_speed
	velocity.y += gravity * delta
	if axis != 0:
		facing = 1 if axis > 0 else -1
		_apply_facing()
	move_and_slide()

	if not is_on_floor():
		_enter_state(State.JUMP)
		return

	if absf(axis) > 0.1:
		if state != State.RUN:
			_enter_state(State.RUN)
	else:
		if state != State.IDLE:
			_enter_state(State.IDLE)


func _process_air(delta: float) -> void:
	var axis := _move_axis()
	velocity.x = axis * move_speed
	velocity.y = minf(velocity.y + gravity * delta, max_falls_speed)
	if axis != 0:
		facing = 1 if axis > 0 else -1
		_apply_facing()
	move_and_slide()
	if is_on_floor():
		_enter_state(State.IDLE)
		return
	# Wall slide uniquement en descente — évite le "super jump" collé au mur.
	if velocity.y >= 0.0 and is_on_wall() and axis == facing:
		_enter_state(State.WALL_SLIDE)


func _process_wall_slide(delta: float) -> void:
	var axis := _move_axis()
	# Pas de wall-jump boost : on glisse seulement, saut = petit écartement.
	velocity.x = axis * move_speed * 0.15
	velocity.y = minf(velocity.y + gravity * 0.55 * delta, 160.0)
	chakra = maxf(0.0, chakra - 10.0 * delta)
	move_and_slide()
	if is_on_floor() or not is_on_wall() or chakra <= 0.0 or velocity.y < 0.0:
		_enter_state(State.JUMP if not is_on_floor() else State.IDLE)
		return
	if Input.is_action_just_pressed("%s_jump" % _prefix) and chakra >= 5.0:
		chakra -= 5.0
		facing = -facing
		_apply_facing()
		# Petit push-off, pas un second saut plein.
		velocity = Vector2(facing * move_speed * 1.1, jump_velocity * 0.45)
		_enter_state(State.JUMP)


func _process_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	velocity.y = minf(velocity.y + gravity * delta, max_falls_speed)
	move_and_slide()

	var startup: float
	var active: float
	var recovery: float
	match _attack_kind:
		"heavy":
			startup = HEAVY_STARTUP
			active = HEAVY_ACTIVE
			recovery = HEAVY_RECOVERY
		"special":
			startup = SPECIAL_STARTUP
			active = SPECIAL_ACTIVE
			recovery = SPECIAL_RECOVERY
		_:
			startup = LIGHT_STARTUP
			active = LIGHT_ACTIVE
			recovery = LIGHT_RECOVERY

	var t := _state_time
	if _attack_kind == "special":
		hitbox_shape.disabled = true
		if t >= startup and not _special_projectile_spawned:
			_special_projectile_spawned = true
			_spawn_fireball()
	elif t < startup:
		hitbox_shape.disabled = true
	elif t < startup + active:
		hitbox_shape.disabled = false
		_position_hitbox()
	else:
		hitbox_shape.disabled = true

	if t >= startup + active + recovery:
		hitbox_shape.disabled = true
		_enter_state(State.IDLE if is_on_floor() else State.JUMP)


func _process_dodge(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, max_falls_speed)
	move_and_slide()
	invulnerable = _state_time <= DODGE_IFRAMES
	if _state_time >= DODGE_DURATION:
		invulnerable = false
		_enter_state(State.IDLE if is_on_floor() else State.JUMP)


func _process_substitute(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	invulnerable = true
	if _state_time >= SUBSTITUTE_DURATION:
		invulnerable = false
		visible = true
		_enter_state(State.IDLE if is_on_floor() else State.JUMP)


func _process_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	velocity.y = minf(velocity.y + gravity * delta, max_falls_speed)
	move_and_slide()
	if _state_time >= HURT_DURATION:
		_enter_state(State.IDLE if is_on_floor() else State.JUMP)


func _start_attack(kind: String) -> void:
	_attack_kind = kind
	_hit_connected = false
	_special_projectile_spawned = false
	match kind:
		"heavy":
			_attack_damage = heavy_damage
			sprite.position.y = SPRITE_Y_64
			sprite.play("attack_heavy")
		"special":
			_attack_damage = special_damage
			sprite.position.y = SPRITE_Y_64
			sprite.play("attack_special")
		_:
			_attack_damage = light_damage
			sprite.position.y = SPRITE_Y_48
			sprite.play("attack_light")
	_enter_state(State.ATTACK)


func _spawn_fireball() -> void:
	var ball := _fireball_scene.instantiate()
	ball.setup(self, facing)
	ball.global_position = spawn_point.global_position
	get_parent().add_child(ball)


func _try_dodge() -> void:
	if chakra < dodge_chakra_cost:
		return
	chakra -= dodge_chakra_cost
	var axis := _move_axis()
	var dir := facing if axis == 0 else (1 if axis > 0 else -1)
	facing = dir
	_apply_facing()
	velocity = Vector2(dir * move_speed * 1.8, velocity.y * 0.2)
	sprite.play("roll")
	_enter_state(State.DODGE)


func _try_substitute() -> void:
	if chakra < substitute_chakra_cost:
		return
	chakra -= substitute_chakra_cost
	var log := _log_scene.instantiate()
	log.global_position = global_position
	get_parent().add_child(log)

	var axis := _move_axis()
	var dir := facing if axis == 0 else (1 if axis > 0 else -1)
	facing = dir
	_apply_facing()
	global_position.x += dir * substitute_distance
	visible = false
	sprite.play("dash")
	_enter_state(State.SUBSTITUTE)


func _try_throw() -> void:
	if chakra < kunai_chakra_cost:
		return
	chakra -= kunai_chakra_cost
	var kunai := _kunai_scene.instantiate()
	kunai.setup(self, facing)
	kunai.global_position = spawn_point.global_position
	get_parent().add_child(kunai)


func _try_special() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if not _mudra.try_consume_special(now):
		return
	if chakra < special_chakra_cost:
		return
	chakra -= special_chakra_cost
	_start_attack("special")


func _enter_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0
	match new_state:
		State.IDLE:
			sprite.position.y = SPRITE_Y_48
			sprite.play("idle")
		State.RUN:
			sprite.position.y = SPRITE_Y_48
			sprite.play("run")
		State.JUMP:
			sprite.position.y = SPRITE_Y_48
			sprite.play("jump")
		State.WALL_SLIDE:
			sprite.position.y = SPRITE_Y_48
			sprite.play("wall_slide")
		State.HURT:
			sprite.position.y = SPRITE_Y_48
			sprite.play("hurt")
		State.DEAD:
			sprite.position.y = SPRITE_Y_48
			sprite.play("death")
			invulnerable = true
			hitbox_shape.disabled = true
		_:
			pass


func _move_axis() -> float:
	var left := Input.is_action_pressed("%s_left" % _prefix)
	var right := Input.is_action_pressed("%s_right" % _prefix)
	return float(right) - float(left)


func _apply_facing() -> void:
	sprite.flip_h = facing < 0
	spawn_point.position.x = absf(spawn_point.position.x) * facing
	_position_hitbox()


func _position_hitbox() -> void:
	var reach := 24.0
	match _attack_kind:
		"heavy":
			reach = 36.0
		_:
			reach = 24.0
	hitbox.position = Vector2(reach * facing, -12.0)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area == hitbox:
		return
	if area.is_in_group("kunai_hit") or area.is_in_group("fireball_hit"):
		return
	if not area.is_in_group("fighter_hitbox"):
		return
	var attacker := area.get_parent()
	if attacker == null or attacker == self:
		return
	if not attacker.has_method("consume_hit"):
		return
	var payload: Variant = attacker.call("consume_hit")
	if payload == null:
		return
	take_hit(payload.damage, payload.knockback, payload.facing)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if hitbox_shape.disabled or state != State.ATTACK:
		return
	if _attack_kind == "special":
		return
	if not area.is_in_group("fighter_hurtbox"):
		return
	var victim := area.get_parent()
	if victim == null or victim == self:
		return
	var payload: Variant = consume_hit()
	if payload == null:
		return
	if victim.has_method("take_hit"):
		victim.take_hit(payload.damage, payload.knockback, payload.facing)


func consume_hit() -> Variant:
	if state != State.ATTACK or _hit_connected:
		return null
	if hitbox_shape.disabled:
		return null
	_hit_connected = true
	var kb_x := 130.0 if _attack_kind == "light" else 190.0
	return {
		"damage": _attack_damage,
		"facing": facing,
		"knockback": Vector2(facing * kb_x, -55.0),
	}


func _on_mudra_sequence(seq: Array) -> void:
	GameBus.mudra_updated.emit(player_id, seq)


func _on_mudra_armed(armed: bool) -> void:
	GameBus.special_ready.emit(player_id, armed)


func _emit_stats() -> void:
	GameBus.fighter_stats_changed.emit(self)
