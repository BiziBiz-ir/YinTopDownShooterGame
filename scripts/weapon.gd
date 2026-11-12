class_name Weapon
extends Resource
## Data-only description of a gun. Stats are the whole design; behaviour lives in
## player.gd (firing) and bullet.gd (travel, pierce).

@export var id: StringName = &""
@export var display_name: String = ""
@export var blurb: String = ""
@export var damage: int = 1
@export var pellets: int = 1
@export var cooldown: float = 0.2
@export var bullet_speed: float = 950.0
@export var spread: float = 0.0
@export var pierce: int = 0
@export var range_life: float = 0.9
@export var recoil: float = 1.0
@export var bullet_color: Color = Color(1.0, 0.93, 0.5)
@export var sfx: StringName = &"handgun"


func stats_line() -> String:
	return "%d dmg · %.1f/s" % [damage * pellets, 1.0 / maxf(cooldown, 0.001)]


static func catalogue() -> Array[Weapon]:
	var out: Array[Weapon] = []
	for def in _DEFS:
		var weapon := Weapon.new()
		for key in def:
			weapon.set(key, def[key])
		out.append(weapon)
	return out


## Handgun is the baseline; pistol trades rate for punch; the rifle is the
## accurate upgrade; SMG wins up close if you can hold the aim; shotgun is all
## burst, no range.
const _DEFS: Array[Dictionary] = [
	{
		"id": &"handgun",
		"display_name": "HANDGUN",
		"blurb": "steady sidearm,\ngood at any range",
		"damage": 1,
		"pellets": 1,
		"cooldown": 0.16,
		"bullet_speed": 950.0,
		"spread": 0.015,
		"pierce": 0,
		"range_life": 0.9,
		"recoil": 1.2,
		"bullet_color": Color(1.0, 0.93, 0.5),
		"sfx": &"handgun",
	},
	{
		"id": &"pistol",
		"display_name": "PISTOL",
		"blurb": "slow hand cannon,\npunches through two",
		"damage": 3,
		"pellets": 1,
		"cooldown": 0.45,
		"bullet_speed": 1150.0,
		"spread": 0.008,
		"pierce": 1,
		"range_life": 1.0,
		"recoil": 4.5,
		"bullet_color": Color(1.0, 0.72, 0.32),
		"sfx": &"pistol",
	},
	{
		"id": &"smg",
		"display_name": "SMG",
		"blurb": "spray and pray,\nwide spread",
		"damage": 1,
		"pellets": 1,
		"cooldown": 0.07,
		"bullet_speed": 880.0,
		"spread": 0.1,
		"pierce": 0,
		"range_life": 0.8,
		"recoil": 0.8,
		"bullet_color": Color(0.72, 1.0, 0.6),
		"sfx": &"smg",
	},
	{
		"id": &"rifle",
		"display_name": "RIFLE",
		"blurb": "fast and precise,\npunches through two",
		"damage": 2,
		"pellets": 1,
		"cooldown": 0.14,
		"bullet_speed": 1300.0,
		"spread": 0.012,
		"pierce": 1,
		"range_life": 1.1,
		"recoil": 2.0,
		"bullet_color": Color(0.6, 0.9, 1.0),
		"sfx": &"rifle",
	},
	{
		"id": &"shotgun",
		"display_name": "SHOTGUN",
		"blurb": "seven pellets,\ndevastating up close",
		"damage": 1,
		"pellets": 7,
		"cooldown": 0.65,
		"bullet_speed": 820.0,
		"spread": 0.26,
		"pierce": 0,
		"range_life": 0.3,
		"recoil": 7.0,
		"bullet_color": Color(1.0, 0.62, 0.5),
		"sfx": &"shotgun",
	},
]
