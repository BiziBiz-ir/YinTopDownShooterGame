extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	# --- Weapon catalogue ---
	var guns := Weapon.catalogue()
	assert(guns.size() == 5, "expected five weapons")
	var ids := {}
	for gun in guns:
		ids[gun.id] = true
		assert(gun.cooldown > 0.0 and gun.pellets >= 1 and gun.bullet_speed > 0.0)
		assert(not gun.display_name.is_empty())
	assert(ids.size() == 5, "weapon ids must be unique")

	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	main.wave_break = 999.0

	# --- Loadout gate: nothing runs before a gun is picked ---
	var player: CharacterBody2D = main.get_node("Player")
	assert(main.wave == 0, "a wave started before the loadout")
	assert(main.loadout.visible, "loadout menu should be up")
	assert(not main.hud.visible, "hud should be hidden during the loadout")
	assert(not player.is_physics_processing(), "player should be frozen in the loadout")

	# Click the first card, the same way a mouse would.
	var first_card: Button = main.loadout.cards.get_child(0)
	first_card.pressed.emit()
	await process_frame
	print("chosen=", player.weapon.id, " wave=", main.wave)
	assert(not main.loadout.visible, "loadout did not close")
	assert(main.hud.visible, "hud never appeared")
	assert(player.is_physics_processing(), "player still frozen after choosing")
	assert(player.weapon.id == &"handgun", "first card should be the handgun")
	assert(main.wave == 1, "wave 1 should start on selection")
	assert(main.enemies_alive > 0, "no enemies spawned")

	# Clear the wave so we test one controlled enemy.
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await process_frame
	main.enemies_alive = 0

	# --- Bullet kills a chaser ---
	var enemy = load("res://scenes/enemy.tscn").instantiate()
	enemy.position = player.global_position + Vector2(160, 0)
	main.get_node("Enemies").add_child(enemy)
	main.enemies_alive = 1
	enemy.died.connect(main._on_enemy_died)
	enemy.max_health = 1

	player.rotation = 0.0
	player._shoot()
	await process_frame
	print("bullets=", main.get_node("Bullets").get_child_count())

	for i in 30:
		await physics_frame
	print("after shot: score=", main.score, " alive=", main.enemies_alive)
	assert(main.score > 0, "bullet never killed the enemy")

	# --- Shotgun fires a spread ---
	player.set_weapon(guns[4])
	player._shoot()
	await process_frame
	var pellets := main.get_node("Bullets").get_child_count()
	print("shotgun pellets=", pellets)
	assert(pellets == guns[4].pellets, "shotgun should fire its full pellet count")
	for b in main.get_node("Bullets").get_children():
		b.queue_free()
	await process_frame

	# --- Rifle pierces two enemies ---
	player.set_weapon(guns[3])
	for i in 2:
		var lined = load("res://scenes/enemy.tscn").instantiate()
		lined.position = player.global_position + Vector2(120 + i * 120, 0)
		main.get_node("Enemies").add_child(lined)
		lined.max_health = 1
		lined.died.connect(main._on_enemy_died)
		main.enemies_alive += 1
	player.rotation = 0.0
	player._shoot()
	for i in 30:
		await physics_frame
	print("rifle pierce: alive=", main.enemies_alive)
	assert(main.enemies_alive == 0, "rifle should pierce two enemies")

	# --- Bomber suicided into the player ---
	player.set_weapon(guns[0])
	player._invulnerable = 0.0
	var hp_before: int = player.health
	var bomber = load("res://scenes/bomber.tscn").instantiate()
	var blast_damage: int = bomber.blast_damage
	bomber.position = player.global_position + Vector2(70, 0)
	main.get_node("Enemies").add_child(bomber)
	main.enemies_alive = 1
	bomber.died.connect(main._on_enemy_died)

	await create_timer(1.3).timeout
	print("bomber blast: hp ", hp_before, " -> ", player.health, " alive=", main.enemies_alive)
	assert(player.health == hp_before - blast_damage, "bomber blast did not damage player")
	assert(main.enemies_alive == 0, "bomber death was not counted")

	# --- Shooting a bomber sets it off harmlessly ---
	player._invulnerable = 0.0
	var hp_peek: int = player.health
	var bomber2 = load("res://scenes/bomber.tscn").instantiate()
	bomber2.position = player.global_position + Vector2(300, 0)
	main.get_node("Enemies").add_child(bomber2)
	main.enemies_alive = 1
	bomber2.died.connect(main._on_enemy_died)

	player.rotation = 0.0
	player._shoot()
	await create_timer(0.8).timeout
	print("shot bomber: hp ", hp_peek, " -> ", player.health, " alive=", main.enemies_alive)
	assert(main.enemies_alive == 0, "shot bomber did not die")
	assert(player.health == hp_peek, "blowing up a bomber with bullets should be harmless")

	# --- Damage and i-frames ---
	player._invulnerable = 0.0
	var hp_start: int = player.health
	player.take_damage(1)
	print("hp ", hp_start, " -> ", player.health)
	assert(player.health == hp_start - 1)
	player.take_damage(1)
	assert(player.health == hp_start - 1, "i-frames not applied")

	# --- Death: CRT effect, then the menu on black ---
	player._invulnerable = 0.0
	player.take_damage(player.health)

	var crt: CanvasLayer = main.get_node("CRT")
	var hud: CanvasLayer = main.get_node("HUD")
	var game_over: Control = main.get_node("HUD/Root/GameOver")
	var backdrop: ColorRect = main.get_node("HUD/Root/GameOver/Backdrop")

	assert(not game_over.visible, "menu showed before the death effect")
	await create_timer(0.5).timeout
	print("crt playing=", crt.visible, " progress=", (crt.get_node("Rect").material as ShaderMaterial).get_shader_parameter("progress"))
	assert(crt.visible, "CRT effect never played")

	await create_timer(1.6).timeout
	print("game over shown=", game_over.visible)
	assert(game_over.visible, "menu never appeared")
	assert(not crt.visible, "CRT overlay left on top of the menu")
	assert(backdrop.color.a == 1.0 and backdrop.color.v == 0.0, "death screen should be opaque black")

	var play_again: Button = main.get_node("HUD/Root/GameOver/Center/Buttons/PlayAgain")
	assert(play_again != null)
	assert(not hud.restart_requested.get_connections().is_empty(), "play-again button is not wired")

	print("SMOKE TEST PASSED")
	quit()
