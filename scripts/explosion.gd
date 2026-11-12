extends Node2D
## Blast visual: a ring that expands fast and fades. Damage is applied by the
## thing that spawned it; this is only the picture.

@export var blast_radius: float = 78.0
@export var duration: float = 0.38
@export var tint: Color = Color(1.0, 0.72, 0.32)

var _time := 0.0


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := clampf(_time / duration, 0.0, 1.0)
	var fade := 1.0 - k

	# Expanding shockwave. The node uses additive blending, so this glows instead
	# of painting a flat disc over the arena.
	var r := blast_radius * ease(k, 0.35)
	draw_circle(Vector2.ZERO, r, Color(tint.r, tint.g, tint.b, 0.35 * fade * fade))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(1.0, 0.95, 0.85, fade), 5.0, true)
	draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 64, Color(tint.r, tint.g, tint.b, 0.7 * fade * fade), 3.0, true)

	# Hot core that collapses.
	var core := blast_radius * 0.55 * (1.0 - ease(k, 0.45))
	if core > 0.5:
		draw_circle(Vector2.ZERO, core, Color(1.0, 1.0, 0.95, fade))
