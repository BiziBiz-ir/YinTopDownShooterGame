extends CanvasLayer
## Start screen: pick a gun. Cards are built from Weapon.catalogue().

signal weapon_chosen(weapon: Weapon)

@onready var cards: HBoxContainer = $Root/Panel/Cards

var _weapons: Array[Weapon] = []
var _chosen := false


func _ready() -> void:
	_weapons = Weapon.catalogue()
	for i in _weapons.size():
		cards.add_child(_make_card(i, _weapons[i]))

	await get_tree().process_frame
	if cards.get_child_count() > 0:
		(cards.get_child(0) as Button).grab_focus()


func _make_card(index: int, weapon: Weapon) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(208, 152)
	button.text = "%d · %s\n%s\n%s" % [
		index + 1,
		weapon.display_name,
		weapon.stats_line(),
		weapon.blurb,
	]
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(func() -> void: _choose(weapon))
	return button


func _unhandled_input(event: InputEvent) -> void:
	if _chosen or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var index := int(event.keycode) - int(KEY_1)
		if index >= 0 and index < _weapons.size():
			_choose(_weapons[index])
			get_viewport().set_input_as_handled()


func _choose(weapon: Weapon) -> void:
	if _chosen:
		return
	_chosen = true
	Sfx.play(&"select", -9.0, 0.02)
	weapon_chosen.emit(weapon)
	hide()
