extends Node2D

# ==============================================================================
# 1. KONFIGURASI & REFERENSI
# ==============================================================================

# --- KONFIGURASI LEVEL ---
# Arahkan ke Credits/Epilogue karena ini stage terakhir
@export_file("*.tscn") var next_level_path = "res://scenes/epilogue.tscn"

# --- REFERENSI NODE ---
@onready var player: CharacterBody2D = $Player
@onready var anim_player: AnimationPlayer = $FadeTransition/AnimationPlayer
@onready var music_3: AudioStreamPlayer = $music3

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
	# 1. Matikan lagu dari Stage sebelumnya
	if is_instance_valid(MusicController):
		MusicController.stop_music()
	
	# 2. Mainkan lagu Stage 3 dengan efek Fade In
	if music_3:
		# Simpan volume asli yang diset di Inspector
		var target_volume = music_3.volume_db
		
		# Set ke hening dulu
		music_3.volume_db = -80.0
		music_3.play()
		
		# Naikkan pelan-pelan ke target volume
		var tween = create_tween()
		tween.tween_property(music_3, "volume_db", target_volume, 2.0)

func _connect_signals():
	# 1. Sinyal Player Mati
	if player:
		player.player_died.connect(_on_player_died)
	
	# 2. Sinyal Kunci Tamat (PENTING)
	if has_node("Key"):
		# Pastikan nama node di Scene Tree adalah "Key" (case sensitive)
		$Key.level_won.connect(_on_level_won)
	else:
		print("WARNING: Node 'Key' tidak ditemukan di Stage 3!")

func _on_player_died():
	# Stop musik saat kalah
	if music_3:
		music_3.stop()

# ==============================================================================
# 4. TRANSISI LEVEL (TAMAT GAME)
# ==============================================================================

# Fungsi ini dipanggil otomatis saat Player menyentuh Key
func _on_level_won():
	print("Stage 3 Selesai! Menuju Credits...")
	
	# 1. RESET NYAWA (Persiapan untuk New Game/Credits)
	Global.lives = 3
	
	# 2. Fade Out Musik Stage 3
	if music_3:
		var tween = create_tween()
		tween.tween_property(music_3, "volume_db", -80.0, 1.0)
	
	# 3. Animasi Keluar (Bening -> Hitam)
	if anim_player and anim_player.has_animation("Fade_In"):
		anim_player.play("Fade_In")
		await anim_player.animation_finished
	else:
		# Fallback delay jika animasi tidak ada
		await get_tree().create_timer(1.0).timeout
	
	# 4. Pindah ke Scene Epilogue
	if next_level_path != "":
		get_tree().change_scene_to_file(next_level_path)
	else:
		print("ERROR: Path 'next_level_path' ke Epilogue belum diisi!")
