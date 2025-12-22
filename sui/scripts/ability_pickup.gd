extends Area2D

@onready var opened: AudioStreamPlayer2D = $Opened
# Pastikan kamu punya referensi ke sprite & collision
@onready var sprite_2d = $Sprite2D 
@onready var collision_shape = $CollisionShape2D

func _ready():
	# Animasi naik turun (Floating effect)
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5, 1.0).as_relative()
	tween.tween_property($Sprite2D, "position:y", 5, 1.0).as_relative()

func _on_body_entered(body):
	# Cek apakah yang ambil adalah Player
	if body.name == "Player" or body.is_in_group("player"):
		print("ITEM DIAMBIL! LASER UNLOCKED!")
		
		# 1. Buka Kunci Skill LANGSUNG
		Global.has_laser_ability = true
		
		# 2. MATIKAN VISUAL & FISIK DULU (Supaya terlihat sudah diambil)
		if sprite_2d:
			sprite_2d.visible = false # Hilangkan gambar
		
		if collision_shape:
			collision_shape.set_deferred("disabled", true) # Matikan tabrakan biar gak keambil 2x
		
		# 3. MAINKAN SUARA & TUNGGU
		if opened:
			opened.play()
			await opened.finished # <--- INI KUNCINYA (Tunggu sampai suara beres)
		
		# 4. BARU HAPUS ITEM
		queue_free()
