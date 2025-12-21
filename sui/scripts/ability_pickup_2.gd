extends Area2D

func _ready():
	# Animasi visual naik turun
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5, 1.0).as_relative()
	tween.tween_property($Sprite2D, "position:y", 5, 1.0).as_relative()

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("SKILL ES UNLOCKED!")
		Global.has_ice_ability = true # <--- Aktifkan Es
		queue_free()
