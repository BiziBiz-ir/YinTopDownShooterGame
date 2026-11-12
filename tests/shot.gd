extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 30:
		await process_frame

	var player: CharacterBody2D = main.get_node("Player")
	var enemies: Node2D = main.get_node("Enemies")

	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/opencode/loadout.png")
	print("saved loadout")

	# Start with the rifle so the shot reads well.
	main.loadout.cards.get_child(3).pressed.emit()
	await process_frame
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await process_frame

	for i in 5:
		var e = load("res://scenes/enemy.tscn").instantiate()
		var a: float = i * TAU / 5.0 + 0.4
		e.position = player.global_position + Vector2(cos(a), sin(a)) * (200.0 + i * 16.0)
		enemies.add_child(e)
		main.enemies_alive += 1

	for i in 2:
		var b = load("res://scenes/bomber.tscn").instantiate()
		var a: float = i * PI + 2.2
		b.position = player.global_position + Vector2(cos(a), sin(a)) * 330.0
		enemies.add_child(b)
		main.enemies_alive += 1

	# One bomber already lit up, close in.
	var hot = load("res://scenes/bomber.tscn").instantiate()
	hot.position = player.global_position + Vector2(-100, -60)
	enemies.add_child(hot)
	main.enemies_alive += 1

	# A blast caught early, while it's still hot.
	var blast = load("res://scenes/explosion.tscn").instantiate()
	blast.blast_radius = 78.0
	enemies.add_child(blast)
	blast.global_position = player.global_position + Vector2(120, 90)

	main.score = 1470
	main.hud.set_score(main.score)
	main.hud.set_wave(5)
	main.hud.set_health(3, 5)

	player.rotation = -0.25
	player._shoot()
	player._shoot()
	for i in 6:
		await process_frame
	player._shoot()

	blast._time = 0.07
	blast.queue_redraw()

	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/opencode/action.png")
	print("saved action")

	var crt: CanvasLayer = main.get_node("CRT")
	crt.visible = true
	for p in [0.32, 0.7, 0.98]:
		crt._set_progress(p)
		await RenderingServer.frame_post_draw
		var path := "/tmp/opencode/crt_%02d.png" % int(p * 100)
		root.get_texture().get_image().save_png(path)
		print("saved ", path)

	crt.visible = false
	main.hud.show_game_over(main.score, main.wave)
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/opencode/crt_menu.png")
	print("saved menu")
	quit()
