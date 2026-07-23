extends CharacterBody2D
## Combattant ninja — contrôles Helldivers-like + munitions.

enum State { IDLE, RUN, JUMP, ATTACK, DODGE, SUBSTITUTE, HURT, DEAD, WALL_SLIDE, STRATAGEM }

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
@export var heavy_chakra_cost: float = 16.0
@export var substitute_chakra_cost: float = 22.0
@export var special_chakra_cost: float = 35.0
@export var defense_chakra_cost: float = 25.0
@export var dodge_chakra_cost: float = 8.0
@export var substitute_distance: float = 56.0
@export var wall_jump_velocity: float = -300.0
@export var wall_jump_push: float = 210.0
@export var max_ammo: int = 6

const LIGHT_STARTUP := 0.06
const LIGHT_ACTIVE := 0.14
const LIGHT_RECOVERY := 0.16
const HEAVY_STARTUP := 0.18
const HEAVY_ACTIVE := 0.18
const HEAVY_RECOVERY := 0.38
const SPECIAL_STARTUP := 0.18
const SPECIAL_ACTIVE := 0.16
const SPECIAL_RECOVERY := 0.35
const DODGE_DURATION := 0.32
const DODGE_IFRAMES := 0.22
const SUBSTITUTE_DURATION := 0.18
const HURT_DURATION := 0.28
const WALL_COYOTE := 0.12
const SPRITE_Y_48 := -15.0
const SPRITE_Y_64 := -15.0
const AIM_STICK_DEADZONE := 0.28

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var spawn_point: Marker2D = $ProjectileSpawn
@onready var aim_reticle: Node2D = $AimReticle
@onready var stratagem_label: Label = $StratagemLabel

var health: float
var chakra: float
var ammo: int = 6
var ammo_kind: int = 0 # 0 kunai, 1 shuriken
var state: State = State.IDLE
var invulnerable: bool = false
var aim_dir: Vector2 = Vector2.RIGHT
var controllable: bool = true

var _prefix: String = "p1"
var _pad_device: int = -1
var _mudra := MudraBuffer.new()
var _state_time: float = 0.0
var _attack_kind: String = ""
var _attack_damage: float = 0.0
var _hit_connected: bool = false
var _kunai_scene: PackedScene
var _shuriken_scene: PackedScene
var _fireball_scene: PackedScene
var _log_scene: PackedScene
var _wall_scene: PackedScene
var _dir_pressed: Dictionary = {"left": false, "right": false, "up": false, "down": false}
var _special_projectile_spawned: bool = false
var _pending_technique: String = ""
var _wall_dir: int = 0
var _wall_coyote: float = 0.0
var _in_stance: bool = false
var _blocked_melee_confirm: bool = false


func _ready() -> void:
	health = max_health
	chakra = max_chakra
	ammo = max_ammo
	_prefix = "p1" if player_id == 1 else "p2"
	_pad_device = InputSetup.get_device_for_player(player_id)
	controllable = InputSetup.is_player_active(player_id)
	_kunai_scene = preload("res://scenes/kunai.tscn")
	_shuriken_scene = preload("res://scenes/shuriken.tscn")
	_fireball_scene = preload("res://scenes/fireball.tscn")
	_log_scene = preload("res://scenes/substitution_log.tscn")
	_wall_scene = preload("res://scenes/chakra_wall.tscn")
	sprite.sprite_frames = SpriteSheets.build()
	sprite.modulate = tint
	sprite.position.y = SPRITE_Y_48
	sprite.play("idle")
	hitbox.add_to_group("fighter_hitbox")
	hurtbox.add_to_group("fighter_hurtbox")
	hitbox_shape.disabled = true
	hitbox.monitoring = true
	hitbox.monitorable = true
	hitbox.collision_mask = 8 | 1 # hurtbox + murs
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	_mudra.sequence_changed.connect(_on_mudra_sequence)
	_mudra.technique_armed.connect(_on_technique_armed)
	InputSetup.pads_changed.connect(_on_pads_changed)
	stratagem_label.visible = false
	stratagem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aim_dir = Vector2(facing, 0)
	_apply_facing()
	_resize_hitbox(false)
	_update_aim(0.0)
	_emit_stats()
	_update_stratagem_visual()


func _on_pads_changed(_p1: int, _p2: int) -> void:
	_pad_device = InputSetup.get_device_for_player(player_id)
	controllable = InputSetup.is_player_active(player_id)


func _physics_process(delta: float) -> void:
	if not GameBus.match_active and state != State.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_state_time += delta
	if state != State.DEAD:
		chakra = minf(max_chakra, chakra + chakra_regen * delta)

	if controllable:
		_blocked_melee_confirm = false
		_update_aim(delta)
		_update_stance(delta)
		_handle_action_inputs()
	else:
		_in_stance = false
		aim_reticle.visible = false
		stratagem_label.visible = false

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
		State.STRATAGEM:
			_process_stratagem(delta)

	_emit_stats()


func reset_round(pos: Vector2) -> void:
	global_position = pos
	health = max_health
	chakra = max_chakra
	ammo = max_ammo
	velocity = Vector2.ZERO
	invulnerable = false
	hitbox_shape.disabled = true
	_mudra.reset()
	_in_stance = false
	_pending_technique = ""
	visible = true
	controllable = InputSetup.is_player_active(player_id)
	_enter_state(State.IDLE)
	_update_stratagem_visual()
	_emit_stats()


func pickup_ammo(_kind: int) -> bool:
	if ammo >= max_ammo:
		return false
	ammo += 1
	_emit_stats()
	return true


func take_hit(amount: float, knockback: Vector2, from_facing: int) -> void:
	if state == State.DEAD or invulnerable:
		return
	if _in_stance:
		_exit_stance(false)
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


func _update_stance(_delta: float) -> void:
	var want := Input.is_action_pressed("%s_stance" % _prefix)
	if want and not _in_stance and state in [State.IDLE, State.RUN, State.STRATAGEM]:
		_enter_stance()
	elif not want and _in_stance:
		_exit_stance(false)


func _enter_stance() -> void:
	_in_stance = true
	_mudra.reset()
	_dir_pressed = {"left": false, "right": false, "up": false, "down": false}
	velocity = Vector2.ZERO
	_enter_state(State.STRATAGEM)
	_update_stratagem_visual()


func _exit_stance(keep_armed_ui: bool) -> void:
	_in_stance = false
	if not keep_armed_ui:
		_mudra.reset()
	if state == State.STRATAGEM:
		_enter_state(State.IDLE if is_on_floor() else State.JUMP)
	_update_stratagem_visual()


func _process_stratagem(delta: float) -> void:
	velocity = Vector2.ZERO
	velocity.y = minf(velocity.y + gravity * delta, max_falls_speed)
	move_and_slide()
	_poll_mudra_directions()
	# Confirm technique
	if _mudra.is_armed() and Input.is_action_just_pressed("%s_special_confirm" % _prefix):
		_try_cast_armed()


func _handle_action_inputs() -> void:
	if state in [State.DEAD, State.HURT, State.SUBSTITUTE]:
		return
	if state == State.ATTACK or state == State.DODGE:
		return
	if _in_stance or state == State.STRATAGEM:
		# Pendant la stance : seulement mudras + confirm (géré ailleurs)
		if _mudra.is_armed() and Input.is_action_just_pressed("%s_special_confirm" % _prefix):
			_try_cast_armed()
		return

	if Input.is_action_just_pressed("%s_cycle_ammo" % _prefix):
		ammo_kind = 1 - ammo_kind
		_emit_stats()
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
	# LMB = melee, sauf si vient de confirmer une technique
	if Input.is_action_just_pressed("%s_attack_melee" % _prefix) and not _blocked_melee_confirm:
		_start_attack("light")
		return
	if Input.is_action_just_pressed("%s_jump" % _prefix) and is_on_floor():
		velocity.y = jump_velocity
		_enter_state(State.JUMP)


func _poll_mudra_directions() -> void:
	if not _in_stance:
		return
	var now := Time.get_ticks_msec() / 1000.0
	for dir in ["left", "right", "up", "down"]:
		var action := "%s_%s" % [_prefix, dir]
		var pressed := Input.is_action_pressed(action)
		if pressed and not _dir_pressed[dir]:
			_mudra.push_direction(dir, now)
		_dir_pressed[dir] = pressed


func _try_cast_armed() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var tech := _mudra.try_consume(now)
	if tech.is_empty():
		return
	var cost := special_chakra_cost if tech == "offense" else defense_chakra_cost
	if chakra < cost:
		_exit_stance(false)
		return
	chakra -= cost
	_pending_technique = tech
	_blocked_melee_confirm = true
	_exit_stance(true)
	if tech == "offense":
		_start_attack("special")
	else:
		_cast_defense_wall()


func _cast_defense_wall() -> void:
	var wall := _wall_scene.instantiate()
	wall.setup(self, facing)
	wall.global_position = global_position + Vector2(facing * 28.0, -8.0)
	get_parent().add_child(wall)
	_pending_technique = ""


func _process_grounded(delta: float) -> void:
	if _in_stance:
		velocity = Vector2.ZERO
		move_and_slide()
		return
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
	_update_wall_memory()
	if is_on_floor():
		_wall_coyote = 0.0
		_enter_state(State.IDLE)
		return
	if Input.is_action_just_pressed("%s_jump" % _prefix) and _wall_coyote > 0.0 and chakra >= 5.0:
		_do_wall_jump()
		return
	if is_on_wall() and axis != 0 and velocity.y > -90.0:
		var wall := _detect_wall_dir()
		if wall != 0 and axis == wall:
			_wall_dir = wall
			_enter_state(State.WALL_SLIDE)


func _process_wall_slide(delta: float) -> void:
	var axis := _move_axis()
	_wall_dir = _detect_wall_dir()
	if _wall_dir == 0:
		_wall_dir = facing
	velocity.x = _wall_dir * 20.0
	velocity.y = minf(velocity.y + gravity * 0.5 * delta, 180.0)
	chakra = maxf(0.0, chakra - 8.0 * delta)
	move_and_slide()
	_update_wall_memory()
	if is_on_floor():
		_enter_state(State.IDLE)
		return
	if not is_on_wall() or chakra <= 0.0:
		_enter_state(State.JUMP)
		return
	if axis != 0 and axis != _wall_dir:
		_enter_state(State.JUMP)
		return
	if Input.is_action_just_pressed("%s_jump" % _prefix) and chakra >= 5.0:
		_do_wall_jump()


func _do_wall_jump() -> void:
	chakra -= 5.0
	var away := -_wall_dir if _wall_dir != 0 else -facing
	facing = away
	_apply_facing()
	velocity = Vector2(away * wall_jump_push, wall_jump_velocity)
	_wall_coyote = 0.0
	_wall_dir = 0
	_enter_state(State.JUMP)


func _detect_wall_dir() -> int:
	if not is_on_wall():
		return 0
	for i in get_slide_collision_count():
		var n: Vector2 = get_slide_collision(i).get_normal()
		if absf(n.x) > 0.7:
			return -int(signf(n.x))
	return facing


func _update_wall_memory() -> void:
	if is_on_wall():
		_wall_dir = _detect_wall_dir()
		_wall_coyote = WALL_COYOTE
	else:
		_wall_coyote = maxf(0.0, _wall_coyote - get_physics_process_delta_time())


func _process_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	velocity.y = minf(velocity.y + gravity * delta, max_falls_speed)
	move_and_slide()
	var startup: float
	var active: float
	var recovery: float
	match _attack_kind:
		"heavy":
			startup = HEAVY_STARTUP; active = HEAVY_ACTIVE; recovery = HEAVY_RECOVERY
		"special":
			startup = SPECIAL_STARTUP; active = SPECIAL_ACTIVE; recovery = SPECIAL_RECOVERY
		_:
			startup = LIGHT_STARTUP; active = LIGHT_ACTIVE; recovery = LIGHT_RECOVERY
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
		_poll_melee_hits()
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
	if kind == "heavy":
		if chakra < heavy_chakra_cost:
			return
		chakra -= heavy_chakra_cost
	_attack_kind = kind
	_hit_connected = false
	_special_projectile_spawned = false
	_resize_hitbox(kind == "heavy")
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
	var dir := aim_dir if aim_dir.length_squared() > 0.01 else Vector2(facing, 0)
	if ball.has_method("setup_aimed"):
		ball.setup_aimed(self, dir)
	ball.global_position = spawn_point.global_position
	get_parent().add_child(ball)
	_pending_technique = ""


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
	if ammo <= 0:
		return
	ammo -= 1
	var scene := _kunai_scene if ammo_kind == 0 else _shuriken_scene
	var proj := scene.instantiate()
	proj.setup(self, aim_dir, ammo_kind)
	proj.global_position = spawn_point.global_position
	get_parent().add_child(proj)
	_emit_stats()


func _enter_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0
	match new_state:
		State.IDLE, State.STRATAGEM:
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
	if _in_stance or not controllable:
		return 0.0
	var left := Input.is_action_pressed("%s_left" % _prefix)
	var right := Input.is_action_pressed("%s_right" % _prefix)
	return float(right) - float(left)


func _apply_facing() -> void:
	sprite.flip_h = facing < 0
	_position_hitbox()


func _position_hitbox() -> void:
	var reach := 28.0 if _attack_kind != "heavy" else 42.0
	hitbox.position = Vector2(reach * facing, -14.0)


func _resize_hitbox(heavy: bool) -> void:
	var shape := hitbox_shape.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		hitbox_shape.shape = shape
	shape.size = Vector2(38, 30) if heavy else Vector2(30, 26)


func _poll_melee_hits() -> void:
	if _hit_connected or hitbox_shape.disabled:
		return
	for area in hitbox.get_overlapping_areas():
		_on_hitbox_area_entered(area)
		if _hit_connected:
			break
	for body in hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(1)
			_hit_connected = true
			break


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


func _update_aim(_delta: float) -> void:
	if state == State.DEAD or not controllable:
		aim_reticle.visible = false
		return
	aim_reticle.visible = not _in_stance
	aim_dir = _compute_aim_dir()
	spawn_point.position = Vector2(aim_dir.x * 16.0, -18.0 + aim_dir.y * 10.0)
	if aim_reticle.has_method("set_aim"):
		aim_reticle.set_aim(aim_dir)


func _compute_aim_dir() -> Vector2:
	_pad_device = InputSetup.get_device_for_player(player_id)
	if _pad_device >= 0:
		var stick := Vector2(
			Input.get_joy_axis(_pad_device, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(_pad_device, JOY_AXIS_RIGHT_Y)
		)
		if stick.length() >= AIM_STICK_DEADZONE:
			return stick.normalized()
		return Vector2(float(facing), 0).normalized()

	# Solo KBM : souris
	if player_id == 1:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() >= 12.0:
			return to_mouse.normalized()
	return Vector2(float(facing), 0).normalized()


func _on_mudra_sequence(seq: Array) -> void:
	_update_stratagem_visual()
	GameBus.mudra_updated.emit(player_id, seq)


func _on_technique_armed(tech: String) -> void:
	_update_stratagem_visual()
	GameBus.special_ready.emit(player_id, not tech.is_empty())


func _update_stratagem_visual() -> void:
	if not _in_stance:
		stratagem_label.visible = false
		return
	stratagem_label.visible = true
	var symbols: PackedStringArray = []
	for d in _mudra.sequence:
		match str(d):
			"up": symbols.append("↑")
			"down": symbols.append("↓")
			"left": symbols.append("←")
			"right": symbols.append("→")
	var text := " ".join(symbols)
	if _mudra.armed_technique == "offense":
		text += "  [OFF] LMB/X"
		stratagem_label.modulate = Color(1.0, 0.55, 0.25)
	elif _mudra.armed_technique == "defense":
		text += "  [DEF] LMB/X"
		stratagem_label.modulate = Color(0.4, 0.85, 1.0)
	else:
		stratagem_label.modulate = Color(1, 1, 1)
		if text.is_empty():
			text = "CTRL/LB…"
	stratagem_label.text = text


func _emit_stats() -> void:
	GameBus.fighter_stats_changed.emit(self)
