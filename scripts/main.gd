extends Node2D
## Runs the arena: waves, scoring, game over.

const EnemyScene := preload("res://scenes/enemy.tscn")
const BomberScene := preload("res://scenes/bomber.tscn")

@export var wave_break: float = 1.7
@export var spawn_margin: float = 70.0

@onready var player: CharacterBody2D = $Player
@onready var enemies_root: Node2D = $Enemies
@onready var bullets_root: Node2D = $Bullets
@onready var hud: CanvasLayer = $HUD
@onready var crt: CanvasLayer = $CRT
@onready var loadout: CanvasLayer = $Loadout

var score := 0
var wave := 0
var enemies_alive := 0

var _game_over := false
var _arena := Rect2(0, 0, 1280, 720)


func _ready() -> void:
	_arena = Rect2(Vector2.ZERO, get_viewport_rect().size)
	randomize()

	player.bullets_root = bullets_root
	player.health_changed.connect(hud.set_health)
	player.died.connect(_on_player_died)
	player.weapon_changed.connect(hud.set_weapon)
	hud.restart_requested.connect(_restart)
	hud.quit_requested.connect(_quit)
	loadout.weapon_chosen.connect(_on_loadout_chosen)

	hud.set_health(player.max_health, player.max_health)
	hud.set_score(0)

	# Nothing moves until the player has picked a gun.
	hud.visible = false
	player.set_physics_process(false)


func _on_loadout_chosen(weapon: Weapon) -> void:
	player.set_weapon(weapon)
	player.set_physics_process(true)
	hud.visible = true
	_start_wave()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _arena.size), Color(0.055, 0.063, 0.09), true)

	var step := 64.0
	var line := Color(1.0, 1.0, 1.0, 0.035)
	var x := step
	while x < _arena.size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, _arena.size.y), line, 1.0)
		x += step
	var y := step
	while y < _arena.size.y:
		draw_line(Vector2(0.0, y), Vector2(_arena.size.x, y), line, 1.0)
		y += step

	draw_rect(_arena.grow(-1.0), Color(0.3, 0.85, 1.0, 0.18), false, 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_restart()


func _restart() -> void:
	get_tree().reload_current_scene()


func _quit() -> void:
	get_tree().quit()


func _start_wave() -> void:
	wave += 1
	hud.set_wave(wave)
	hud.banner("WAVE %d" % wave)

	var count := 2 + wave
	var bombers := 0
	if wave >= 2:
		bombers = 1 + int(wave / 3.0)

	for i in count - bombers:
		_spawn_chaser()
	for i in bombers:
		_spawn_bomber()


func _spawn_chaser() -> void:
	var enemy := EnemyScene.instantiate()
	enemy.speed = minf(95.0 + wave * 9.0, 240.0)
	enemy.max_health = 1 + int((wave - 1) / 4)
	enemy.score_value = 10 + wave
	_add_enemy(enemy)


func _spawn_bomber() -> void:
	var bomber := BomberScene.instantiate()
	bomber.speed = minf(185.0 + wave * 8.0, 300.0)
	bomber.score_value = 18 + wave
	_add_enemy(bomber)


func _add_enemy(enemy: Node2D) -> void:
	enemy.position = _spawn_point()
	enemy.died.connect(_on_enemy_died)
	enemies_root.add_child(enemy)
	enemies_alive += 1


func _spawn_point() -> Vector2:
	var center := _arena.get_center()
	var radius := 420.0
	for attempt in 12:
		var angle := randf() * TAU
		var point := center + Vector2(cos(angle), sin(angle)) * randf_range(radius, radius + 120.0)
		point.x = clampf(point.x, _arena.position.x + spawn_margin, _arena.end.x - spawn_margin)
		point.y = clampf(point.y, _arena.position.y + spawn_margin, _arena.end.y - spawn_margin)
		if point.distance_to(player.global_position) > 280.0:
			return point
	return Vector2(_arena.position.x + spawn_margin, _arena.position.y + spawn_margin)


func _on_enemy_died(enemy: Node) -> void:
	enemies_alive -= 1
	score += enemy.score_value
	hud.set_score(score)

	if enemies_alive <= 0 and not _game_over:
		_break_then_next_wave()


func _break_then_next_wave() -> void:
	score += 25 * wave
	hud.set_score(score)
	await get_tree().create_timer(wave_break).timeout
	if _game_over or not is_inside_tree():
		return
	_start_wave()


func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)

	# Let the last hit land, then kill the tube. Menu comes up over the dark screen.
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree():
		return
	crt.play()
	await crt.finished
	if not is_inside_tree():
		return
	hud.show_game_over(score, wave)
