extends Node

# 1. INI VARIABEL GLOBAL YANG KAMU MAKSUD
# (Pastikan path file mp3-nya benar)
var menu_music_stream = preload("res://asset/Music/stage 1.mp3") 

# Referensi ke node speaker (Speaker ini harus ada di dalam scene MusicController.tscn)
@onready var audio_player = $AudioStreamPlayer 

# 2. FUNGSI KHUSUS UNTUK MEMUTAR LAGU DARI VARIABEL DI ATAS
func play_menu_music():
	# Cek dulu: Apakah speaker sedang memutar lagu yang sama?
	if audio_player.stream == menu_music_stream and audio_player.playing:
		return # Kalau iya, biarkan saja (jangan restart)
	
	# Kalau beda atau mati, masukkan "kaset" (variabel) ke speaker
	audio_player.stream = menu_music_stream
	audio_player.volume_db = 0.0 # Reset volume takutnya habis di-fade out
	audio_player.play()

func stop_music():
	audio_player.stop()
