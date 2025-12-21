extends Area2D

func _ready():
	# (Opsional) Bikin itemnya naik turun biar keren
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5, 1.0).as_relative()
	tween.tween_property($Sprite2D, "position:y", 5, 1.0).as_relative()

func _on_body_entered(body):
	# Cek apakah yang ambil adalah Player
	if body.name == "Player" or body.is_in_group("player"):
		print("ITEM DIAMBIL! LASER UNLOCKED!")
		
		# 1. Buka Kunci Skill
		Global.has_laser_ability = true
		
		# 2. (Opsional) Efek Suara/Partikel disini
		# AudioPlayer.play_sfx("item_get")
		
		# 3. Hapus Item
		queue_free()
