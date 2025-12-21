extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var music_2 = $music2
# Pastikan node FadeTransition sudah ada di Scene Tree Stage 2 kamu!
@onready var anim_player = $FadeTransition/AnimationPlayer 

# Karena belum ada Stage 3, mungkin kita arahkan ke Credits dulu?
# Atau ganti path ini di Inspector nanti.
@export_file("*.tscn") var next_level_path = "res://scenes/Credits.tscn"

func _ready() -> void:
	# --- 1. TRANSISI MASUK (Layar Hitam -> Bening) ---
	if anim_player:
		anim_player.play("Fade_Out")
	
	if MusicController:
		MusicController.stop_music()
	
	player.player_died.connect(_on_player_died)
	
	# --- 2. SAMBUNGKAN KUNCI ---
	# Kita dengarkan sinyal 'level_won' dari kunci
	if has_node("Key"):
		$Key.level_won.connect(_on_level_won)
	
	# --- 3. SMART FADE IN MUSIK ---
	var target_volume = music_2.volume_db
	music_2.volume_db = -80.0
	music_2.play()
	
	var tween = create_tween()
	tween.tween_property(music_2, "volume_db", target_volume, 2.0)

func _on_player_died():
	music_2.stop()

# --- FUNGSI PINDAH LEVEL (Sama seperti Stage 1) ---
func _on_level_won():
	print("Stage 2 Selesai! OTW ke scene selanjutnya...")
	
	# 1. Mainkan Animasi Keluar (Bening -> Hitam)
	if anim_player:
		anim_player.play("Fade_In") 
	
	# 2. Fade Out Musik Stage 2
	var tween = create_tween()
	tween.tween_property(music_2, "volume_db", -80.0, 1.0)
	
	# 3. TUNGGU ANIMASI SELESAI
	if anim_player:
		await anim_player.animation_finished
	
	# 4. Pindah Scene
	if next_level_path:
		get_tree().change_scene_to_file(next_level_path)
	else:
		print("Error: Next Level Path belum diisi di Inspector Stage 2!")
