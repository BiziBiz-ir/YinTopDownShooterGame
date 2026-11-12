extends CanvasLayer
## Plays the CRT power-off shader over the whole screen, then reports when it's done.

signal finished

const DURATION := 0.9

@onready var _rect: ColorRect = $Rect

var _material: ShaderMaterial


func _ready() -> void:
	visible = false
	_material = _rect.material as ShaderMaterial


func play() -> void:
	if _material == null:
		finished.emit()
		return

	_material.set_shader_parameter("progress", 0.0)
	visible = true

	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

	visible = false
	finished.emit()


func _set_progress(value: float) -> void:
	_material.set_shader_parameter("progress", value)
