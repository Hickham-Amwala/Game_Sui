extends Control # Root node kamu tipe Control kan?

# Ambil referensi container teks
@onready var scrolling_text = $VBoxContainer 

func _ready():
	# 1. AUDIO: Mainkan Lagu Menu
	if MusicController:
		MusicController.play_menu_music()
	
	# 2. SETUP POSISI AWAL TEKS
	# Kita taruh teks di bawah layar (di luar pandangan)
	var start_y = get_viewport_rect().size.y 
	scrolling_text.position.y = start_y
	
	# 3. ANIMASI SCROLLING (TWEEN)
	# Target Y = minus tinggi teksnya (supaya naik terus sampai habis ke atas)
	var target_y = -scrolling_text.size.y 
	var durasi = 15.0 # Berapa detik sampai teks habis (makin besar makin pelan)
	
	var tween = create_tween()
	tween.tween_property(scrolling_text, "position:y", target_y, durasi)
	
	# 4. KETIKA SELESAI SCROLL
	tween.finished.connect(_on_credits_finished)

func _on_credits_finished():
	# Pindah ke Main Menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
