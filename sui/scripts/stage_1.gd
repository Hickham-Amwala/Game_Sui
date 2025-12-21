extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var music_1: AudioStreamPlayer2D = $music1 # Atau AudioStreamPlayer
@onready var anim_player = $FadeTransition/AnimationPlayer

# Masukkan path Stage 2 disini atau lewat Inspector
@export_file("*.tscn") var next_level_path = "res://scenes/stage2.tscn"

func _ready() -> void:
	# 1. Animasi Masuk (Layar Hitam -> Bening)
	anim_player.play("Fade_Out")
	
	if MusicController:
		MusicController.stop_music()
	
	player.player_died.connect(_on_player_died)
	
	# Sambungkan sinyal dari Kunci ke fungsi pindah level
	# Pastikan node 'Key' ada di Scene Tree Stage 1 kamu
	if has_node("Key"):
		$Key.level_won.connect(_on_level_won) # Asumsi Key punya sinyal custom
		# ATAU jika Key menggunakan logika body_entered biasa, lihat langkah 3 di bawah.

	# Audio Fade In
	var tween = create_tween()
	tween.tween_property(music_1, "volume_db", 0.0, 2.0)

func _on_player_died():
	music_1.stop()

# --- FUNGSI BARU UNTUK PINDAH LEVEL ---
func _on_level_won():
	print("Level Selesai! Memulai transisi...")
	
	# 1. Mainkan Animasi Keluar (Bening -> Hitam)
	# Pastikan nama animasinya benar ada di AnimationPlayer
	anim_player.play("Fade_In") 
	
	# 2. Fade Out Musik (Biar halus)
	var tween = create_tween()
	tween.tween_property(music_1, "volume_db", -80.0, 1.0)
	
	# 3. TUNGGU ANIMASI SELESAI (Kuncinya disini!)
	await anim_player.animation_finished
	
	# 4. Baru Pindah Scene
	get_tree().change_scene_to_file(next_level_path)
