extends CharacterBody2D
## Chaser. Drifts toward the player, hurts on contact, weakly separates from its peers.

signal died(enemy: Node)

@export var speed: float = 110.0
@export var acceleration: float = 900.0
@export var max_health: int = 1
@export var contact_damage: int = 1
@export var attack_cooldown: float = 0.8
@export var score_value: int = 10
@export var touch_range: float = 26.0

var health: int

var _attack_cd := 0.0
var _dead := false

@onready var _shape: Polygon2D = $Shape


func _ready() -> void:
	health = max_health
	rotation = randf() * TAU


func _physics_process(delta: float) -> void:
	if _dead:
		return

	_attack_cd = maxf(0.0, _attack_cd - delta)

	var player := get_tree().get_first_node_in_group("player") as Node2D
	var desired := Vector2.ZERO

	if is_instance_valid(player):
		var to_player := player.global_position - global_position
		var dist := to_player.length()
		if dist > 1.0:
			desired = to_player / dist * speed
		if dist < touch_range and _attack_cd <= 0.0 and player.has_method("take_damage"):
			player.take_damage(contact_damage)
			_attack_cd = attack_cooldown

	desired += _separation() * speed
	velocity = velocity.move_toward(desired.limit_length(speed * 1.4), acceleration * delta)
	move_and_slide()

	# Keep the diamond pointing where it walks, not where it was spawned.
	if velocity.length_squared() > 100.0:
		rotation = lerp_angle(rotation, velocity.angle(), 8.0 * delta)


func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var offset: Vector2 = global_position - (other as Node2D).global_position
		var dist := offset.length()
		if dist > 0.01 and dist < 34.0:
			push += offset / dist * ((34.0 - dist) / 34.0)
	return push * 1.6


func take_damage(amount: int) -> void:
	if _dead:
		return
	health -= amount
	if health > 0:
		_flash()
		return
	_die()


func _flash() -> void:
	_shape.modulate = Color(4.0, 4.0, 4.0)
	var tween := create_tween()
	tween.tween_property(_shape, "modulate", Color.WHITE, 0.12)


func _die() -> void:
	_dead = true
	remove_from_group("enemies")
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	died.emit(self)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.7, 1.7), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.chain().tween_callback(queue_free)
