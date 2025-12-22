extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var music_3 = $music3
@onready var anim_player = $FadeTransition/AnimationPlayer

# Arahkan ke Credits karena ini stage terakhir
@export_file("*.tscn") var next_level_path = "res://scenes/epilogue.tscn"

func _ready() -> void:
	# --- 1. VISUAL: FADE IN (Masuk Level) ---
	if anim_player:
		anim_player.play("Fade_Out") # Layar Hitam -> Bening
	
	# --- 2. AUDIO: MATIKAN LAGU LAMA & MAIN LAGU BARU ---
	if MusicController:
		MusicController.stop_music()
	
	player.player_died.connect(_on_player_died)
	
	# --- 3. SAMBUNGKAN KUNCI (INI YANG HARUS ADA) ---
	# Pastikan node Key sudah kamu drag ke Scene Tree Stage 3
	# Dan pastikan namanya benar-benar "Key" (huruf besar K)
	if has_node("Key"):
		$Key.level_won.connect(_on_level_won)
	
	# --- 4. SMART FADE IN MUSIK ---
	var target_volume = music_3.volume_db
	music_3.volume_db = -80.0
	music_3.play()
	
	var tween = create_tween()
	tween.tween_property(music_3, "volume_db", target_volume, 2.0)

func _on_player_died():
	music_3.stop()

# --- FUNGSI PINDAH LEVEL ---
# Fungsi ini dipanggil otomatis saat Player menyentuh Key
func _on_level_won():
	print("Stage 3 Selesai! Menuju Credits...")
	
	# 1. Animasi Keluar (Bening -> Hitam)
	if anim_player:
		anim_player.play("Fade_In") 
	
	# 2. Fade Out Musik
	var tween = create_tween()
	tween.tween_property(music_3, "volume_db", -80.0, 1.0)
	
	# 3. Tunggu Animasi Selesai
	if anim_player:
		await anim_player.animation_finished
	
	# 4. Pindah Scene
	if next_level_path:
		get_tree().change_scene_to_file(next_level_path)
