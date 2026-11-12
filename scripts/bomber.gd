extends CharacterBody2D
## Kamikaze. Rushes in fast, primes itself at close range, then blows up.
## Shooting it before it reaches you sets it off harmlessly.

signal died(enemy: Node)

const ExplosionScene := preload("res://scenes/explosion.tscn")

@export var speed: float = 205.0
@export var acceleration: float = 1500.0
@export var max_health: int = 1
@export var score_value: int = 18
@export var trigger_range: float = 115.0
@export var contact_range: float = 26.0
@export var fuse_time: float = 0.55
@export var blast_radius: float = 78.0
@export var blast_damage: int = 2

var health: int

var _fuse := 0.0
var _priming := false
var _spent := false
var _pulse := 0.0

@onready var _shape: Polygon2D = $Shape
@onready var _core: Polygon2D = $Core


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	if _spent:
		return

	_pulse += delta

	if _priming:
		_fuse -= delta
		_prime_visual()
		velocity = velocity.move_toward(Vector2.ZERO, 220.0 * delta)
		move_and_slide()
		if _fuse <= 0.0:
			_detonate(true)
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var desired := Vector2.ZERO
	if dist > 1.0:
		desired = to_player / dist * speed

	velocity = velocity.move_toward(desired, acceleration * delta)
	move_and_slide()

	if velocity.length_squared() > 100.0:
		rotation = lerp_angle(rotation, velocity.angle(), 10.0 * delta)

	if dist < contact_range:
		_start_fuse(0.12)
	elif dist < trigger_range:
		_start_fuse(fuse_time)


func _start_fuse(time: float) -> void:
	if _priming:
		# Touching the player shortens an already burning fuse.
		_fuse = minf(_fuse, time)
		return
	_priming = true
	_fuse = time


func _prime_visual() -> void:
	var flicker := absf(sin(_pulse * 34.0))
	_shape.scale = Vector2.ONE * (1.0 + 0.28 * flicker)
	_core.scale = Vector2.ONE * (1.0 + 0.6 * flicker)
	_shape.modulate = Color(1.0, 1.0, 1.0).lerp(Color(6.0, 4.0, 2.0), flicker)


func take_damage(amount: int) -> void:
	if _spent:
		return
	health -= amount
	if health > 0:
		_flash()
		return
	# Killed by gunfire: goes off, but the blast is harmless.
	_detonate(false)


func _flash() -> void:
	_shape.modulate = Color(4.0, 4.0, 4.0)
	var tween := create_tween()
	tween.tween_property(_shape, "modulate", Color.WHITE, 0.12)


func _detonate(hurts_player: bool) -> void:
	if _spent:
		return
	_spent = true
	remove_from_group("enemies")
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	Sfx.play(&"explosion", -2.0, 0.05)

	var blast := ExplosionScene.instantiate()
	blast.blast_radius = blast_radius
	get_parent().add_child(blast)
	blast.global_position = global_position

	if hurts_player:
		var player := get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and player.has_method("take_damage"):
			if player.global_position.distance_to(global_position) <= blast_radius:
				player.take_damage(blast_damage)

	died.emit(self)
	queue_free()
