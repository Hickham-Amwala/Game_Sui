extends Node

@onready var music_player = $AudioStreamPlayer


func play_music():
	# INI KUNCINYA:
	# Cek dulu, apakah musik sudah main?
	if music_player.playing:
		# Kalau sudah main, biarkan saja (jangan restart)
		return
	
	# Kalau belum main (mati), baru nyalakan
	music_player.play()

func stop_music():
	music_player.stop()
