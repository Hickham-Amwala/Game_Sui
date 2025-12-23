extends Node2D

# ==============================================================================
# 1. KONFIGURASI & REFERENSI
# ==============================================================================

# --- KONFIGURASI LEVEL ---
# Target scene selanjutnya (Stage 3)
@export_file("*.tscn") var next_level_path = "res://scenes/stage3.tscn"

# --- REFERENSI NODE ---
@onready var player: CharacterBody2D = $Player
@onready var anim_player: AnimationPlayer = $FadeTransition/AnimationPlayer
@onready var music_2: AudioStreamPlayer = $music2

# ==============================================================================
# 2. FUNGSI UTAMA (INIT)
# ==============================================================================

func _ready() -> void:
	# A. ANIMASI TRANSISI (Layar Hitam -> Bening)
	if anim_player and anim_player.has_animation("Fade_Out"):
		anim_player.play("Fade_Out")
	
	# B. SETUP AUDIO
	_setup_music()
	
	# C. KONEKSI SINYAL
	_connect_signals()

# ==============================================================================
# 3. LOGIKA SETUP & SINYAL (INTERNAL)
# ==============================================================================

func _setup_music():
	# 1. Matikan lagu dari Stage 1 (jika masih jalan)
	if is_instance_valid(MusicController):
		MusicController.stop_music()
	
	# 2. Mainkan lagu Stage 2 dengan Smart Fade In
	if music_2:
		# Simpan volume asli dari Inspector
		var target_volume = music_2.volume_db
		
		# Mulai dari hening
		music_2.volume_db = -80.0
		music_2.play()
		
		# Naikkan volume perlahan
		var tween = create_tween()
		tween.tween_property(music_2, "volume_db", target_volume, 2.0)

func _connect_signals():
	# 1. Sinyal Player Mati
	if player:
		player.player_died.connect(_on_player_died)
	
	# 2. Sinyal Kunci (Level Won)
	if has_node("Key"):
		$Key.level_won.connect(_on_level_won)
	else:
		print("WARNING: Node 'Key' tidak ditemukan di Stage 2!")

func _on_player_died():
	# Stop musik saat kalah
	if music_2:
		music_2.stop()

# ==============================================================================
# 4. TRANSISI LEVEL (MENANG)
# ==============================================================================

# Fungsi ini dipanggil otomatis saat Player menyentuh Key
func _on_level_won():
	print("Stage 2 Selesai! OTW ke Stage 3...")
	
	# 1. RESET NYAWA (Reward karena lolos stage)
	Global.lives = 3
	
	# 2. Fade Out Musik Stage 2
	if music_2:
		var tween = create_tween()
		tween.tween_property(music_2, "volume_db", -80.0, 1.0)
	
	# 3. Animasi Keluar (Bening -> Hitam)
	if anim_player and anim_player.has_animation("Fade_In"):
		anim_player.play("Fade_In")
		await anim_player.animation_finished
	else:
		# Fallback jika animasi error/hilang
		await get_tree().create_timer(1.0).timeout
	
	# 4. Pindah Scene
	if next_level_path != "":
		get_tree().change_scene_to_file(next_level_path)
	else:
		print("ERROR: Path 'next_level_path' Stage 2 belum diisi!")
