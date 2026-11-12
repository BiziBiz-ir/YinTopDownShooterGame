extends Area2D
## Straight-line projectile. Damages enemies, can pierce, dies on walls.

@export var speed: float = 950.0
@export var damage: int = 1
@export var pierce: int = 0
@export var lifetime: float = 1.2
@export var color: Color = Color(1.0, 0.93, 0.5)

var direction := Vector2.RIGHT

var _hit: Array[Node] = []

@onready var _visual: Polygon2D = $Visual


func _ready() -> void:
	_visual.color = color
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies") or not body.has_method("take_damage"):
		# Walls and anything else stop the bullet dead.
		queue_free()
		return

	if body in _hit:
		return

	_hit.append(body)
	body.take_damage(damage)

	if _hit.size() > pierce:
		queue_free()
