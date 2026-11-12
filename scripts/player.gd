extends CharacterBody2D
## Twin-stick player. WASD/arrows to move, mouse to aim, left click to fire.

signal health_changed(current: int, maximum: int)
signal died
signal weapon_changed(weapon: Weapon)

const BulletScene := preload("res://scenes/bullet.tscn")

@export var speed: float = 330.0
@export var acceleration: float = 2600.0
@export var friction: float = 2200.0
@export var max_health: int = 5
@export var invulnerability_time: float = 0.9

var health: int
var bullets_root: Node2D
var weapon: Weapon

var _cooldown := 0.0
var _invulnerable := 0.0
var _dead := false

@onready var _body: Polygon2D = $Body
@onready var _barrel: Polygon2D = $Barrel
@onready var _muzzle: Marker2D = $Muzzle


func _ready() -> void:
	health = max_health
	if weapon == null:
		weapon = Weapon.catalogue()[0]
	health_changed.emit(health, max_health)


func set_weapon(new_weapon: Weapon) -> void:
	weapon = new_weapon
	_cooldown = 0.0
	weapon_changed.emit(weapon)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)

	if _dead:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target := input * speed
	var rate := acceleration if input != Vector2.ZERO else friction
	velocity = velocity.move_toward(target, rate * delta)
	move_and_slide()

	_aim()
	_update_blink(delta)

	if Input.is_action_pressed("shoot") and _cooldown <= 0.0:
		_shoot()


func _aim() -> void:
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length_squared() > 4.0:
		rotation = to_mouse.angle()


func _update_blink(delta: float) -> void:
	if _invulnerable > 0.0:
		_invulnerable = maxf(0.0, _invulnerable - delta)
		var a := 0.35 + 0.65 * absf(sin(_invulnerable * 24.0))
		_body.modulate.a = a
		_barrel.modulate.a = a
	else:
		_body.modulate.a = 1.0
		_barrel.modulate.a = 1.0


func _shoot() -> void:
	if bullets_root == null or weapon == null:
		return
	_cooldown = weapon.cooldown
	Sfx.play(weapon.sfx, -6.0, 0.06)

	var aim_dir := Vector2.RIGHT.rotated(rotation)
	for i in weapon.pellets:
		var spread := 0.0
		if weapon.spread > 0.0:
			spread = randf_range(-weapon.spread, weapon.spread)
		var dir := aim_dir.rotated(spread)

		var bullet := BulletScene.instantiate()
		bullet.direction = dir
		bullet.speed = weapon.bullet_speed
		bullet.damage = weapon.damage
		bullet.pierce = weapon.pierce
		bullet.lifetime = weapon.range_life
		bullet.color = weapon.bullet_color
		bullet.global_position = _muzzle.global_position
		bullet.rotation = dir.angle()
		bullets_root.add_child(bullet)

	# Recoil, so heavier guns actually shove you.
	global_position -= aim_dir * weapon.recoil


func take_damage(amount: int) -> void:
	if _dead or _invulnerable > 0.0:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	_invulnerable = invulnerability_time
	if health == 0:
		_die()
	else:
		Sfx.play(&"hurt", -7.0, 0.08)


func _die() -> void:
	_dead = true
	set_deferred("collision_layer", 0)
	Sfx.play(&"death", -3.0, 0.0)
	died.emit()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
