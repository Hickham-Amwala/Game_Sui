extends Node2D

# ==============================================================================
# 1. KONFIGURASI & REFERENSI
# ==============================================================================

# --- KONFIGURASI LEVEL ---
# Masukkan path Stage 2 disini atau lewat Inspector
@export_file("*.tscn") var next_level_path = "res://scenes/stage2.tscn"

# --- REFERENSI NODE (SCENE COMPONENTS) ---
@onready var player: CharacterBody2D = $Player
@onready var music_1: AudioStreamPlayer2D = $music1
@onready var anim_player: AnimationPlayer = $FadeTransition/AnimationPlayer

# ==============================================================================
# 2. FUNGSI UTAMA (INIT)
# ==============================================================================

func _ready() -> void:
	# A. ANIMASI TRANSISI MASUK (Layar Hitam -> Bening)
	if anim_player.has_animation("Fade_Out"):
		anim_player.play("Fade_Out")
	
	# B. SETUP AUDIO
	# Matikan musik dari scene sebelumnya (jika pakai singleton MusicController)
	if is_instance_valid(MusicController): 
		# Cek apakah MusicController benar-benar ada/valid
		if MusicController.has_method("stop_music"):
			MusicController.stop_music()
	
	# Fade In musik level ini
	if music_1:
		music_1.volume_db = -80.0 # Mulai dari hening
		music_1.play()
		var tween = create_tween()
		tween.tween_property(music_1, "volume_db", 0.0, 2.0) # Naik ke volume normal dalam 2 detik

	# C. KONEKSI SINYAL (SIGNAL CONNECT)
	_connect_signals()

# ==============================================================================
# 3. LOGIKA SINYAL (EVENT HANDLERS)
# ==============================================================================

func _connect_signals():
	# 1. Sinyal Player Mati
	if player:
		player.player_died.connect(_on_player_died)
	
	# 2. Sinyal Kunci/Portal (Level Won)
	# Pastikan node 'Key' ada di Scene Tree
	if has_node("Key"):
		# Hubungkan sinyal 'level_won' dari script Key ke fungsi local '_on_level_won'
		$Key.level_won.connect(_on_level_won)
	else:
		print("WARNING: Node 'Key' tidak ditemukan di Stage ini!")

func _on_player_died():
	# Stop musik saat kalah
	if music_1:
		music_1.stop()

# ==============================================================================
# 4. TRANSISI LEVEL (MENANG)
# ==============================================================================

func _on_level_won():
	print("Level Selesai! Memulai transisi...")
	
	# 1. [PENTING] RESET NYAWA DISINI
	# Ini memastikan saat masuk loading screen, data nyawa sudah full lagi.
	Global.lives = 3 
	
	# 2. Fade Out Musik (Biar halus saat keluar)
	if music_1:
		var tween = create_tween()
		tween.tween_property(music_1, "volume_db", -80.0, 1.0)
	
	# 3. Mainkan Animasi Keluar (Bening -> Hitam)
	if anim_player.has_animation("Fade_In"):
		anim_player.play("Fade_In")
		
		# Tunggu animasi selesai (Layar jadi gelap total)
		await anim_player.animation_finished
	else:
		# Fallback jika animasi tidak ada/salah nama
		await get_tree().create_timer(1.0).timeout
	
	# 4. Pindah Scene
	# Cek apakah path scene valid sebelum pindah
	if next_level_path != "":
		get_tree().change_scene_to_file(next_level_path)
	else:
		print("ERROR: 'next_level_path' belum diisi di Inspector!")
