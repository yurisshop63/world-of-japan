extends Node

signal health_changed
signal power_changed
signal xp_changed
signal pvp_xp_changed
signal player_died

var max_health = 100
var health = 100

var max_power = 100
var power = 0

var xp_in_bubble = 0
var xp_per_bubble = 100
var bubbles_filled = 0
var level = 1

var pvp_xp_in_bubble = 0
var pvp_xp_per_bubble = 100
var pvp_bubbles_filled = 0

var bind_position = Vector3(0, 1, 0)

func take_damage(amount):
	if health <= 0:
		return
	health = clamp(health - amount, 0, max_health)
	health_changed.emit()
	if health <= 0:
		player_died.emit()

func heal(amount):
	health = clamp(health + amount, 0, max_health)
	health_changed.emit()

func add_power(amount):
	power = clamp(power + amount, 0, max_power)
	power_changed.emit()

func spend_power(amount):
	power = clamp(power - amount, 0, max_power)
	power_changed.emit()

func add_xp(amount):
	xp_in_bubble += amount
	while xp_in_bubble >= xp_per_bubble:
		xp_in_bubble -= xp_per_bubble
		bubbles_filled += 1
		if bubbles_filled >= 10:
			bubbles_filled = 0
			level += 1
	xp_changed.emit()

func add_pvp_xp(amount):
	pvp_xp_in_bubble += amount
	while pvp_xp_in_bubble >= pvp_xp_per_bubble:
		pvp_xp_in_bubble -= pvp_xp_per_bubble
		pvp_bubbles_filled += 1
		if pvp_bubbles_filled >= 10:
			pvp_bubbles_filled = 0
	pvp_xp_changed.emit()
