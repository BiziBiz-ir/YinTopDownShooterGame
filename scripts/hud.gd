extends CanvasLayer
## Score, wave, health, banner, and the death menu.

signal restart_requested
signal quit_requested

@onready var score_label: Label = $Root/ScoreLabel
@onready var health_label: Label = $Root/HealthLabel
@onready var weapon_label: Label = $Root/WeaponLabel
@onready var wave_label: Label = $Root/WaveLabel
@onready var banner_label: Label = $Root/Banner
@onready var game_over_box: Control = $Root/GameOver
@onready var final_label: Label = $Root/GameOver/Center/FinalLabel
@onready var center: VBoxContainer = $Root/GameOver/Center
@onready var play_again_button: Button = $Root/GameOver/Center/Buttons/PlayAgain
@onready var quit_button: Button = $Root/GameOver/Center/Buttons/Quit

var _banner_tween: Tween


func _ready() -> void:
	play_again_button.pressed.connect(func() -> void: restart_requested.emit())
	quit_button.pressed.connect(func() -> void: quit_requested.emit())


func set_score(value: int) -> void:
	score_label.text = "SCORE  %d" % value


func set_health(current: int, maximum: int) -> void:
	health_label.text = "HP  %d / %d" % [current, maximum]
	health_label.modulate = Color(1, 0.45, 0.4) if current <= 2 else Color.WHITE


func set_wave(value: int) -> void:
	wave_label.text = "WAVE  %d" % value


func set_weapon(weapon: Weapon) -> void:
	weapon_label.text = weapon.display_name


func banner(text: String) -> void:
	banner_label.text = text
	banner_label.modulate.a = 1.0
	banner_label.scale = Vector2.ONE

	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()

	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(banner_label, "scale", Vector2(1.08, 1.08), 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(banner_label, "modulate:a", 0.0, 1.4) \
		.set_delay(0.5)


func show_game_over(score: int, wave: int) -> void:
	final_label.text = "you died on wave %d\nscore %d" % [wave, score]

	# Black screen appears instantly (the CRT effect ended on black); only the
	# words fade in.
	score_label.visible = false
	health_label.visible = false
	weapon_label.visible = false
	wave_label.visible = false
	banner_label.visible = false
	game_over_box.visible = true
	game_over_box.modulate.a = 1.0
	center.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(center, "modulate:a", 1.0, 0.45)
	tween.tween_callback(play_again_button.grab_focus)
