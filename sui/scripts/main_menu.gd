extends Control

# --- Referensi Node ---
# Pastikan di Inspector kamu sudah memasukkan tombol-tombol ke dalam Array ini
@export var menu_buttons: Array[Button]

# Pastikan jalur ini benar sesuai Scene Tree kamu
@onready var fade_transition: Control = $FadeTransition
@onready var animation_player: AnimationPlayer = $FadeTransition/AnimationPlayer

# --- Variabel State ---
var current_index: int = 0
var button_type: String = "" # Menyimpan tombol apa yang ditekan

func _ready():
	# 1. Setup Awal
	update_button_visibility()
	MusicController.play_music() # Pastikan musik nyala
	
	# 2. Hubungkan Sinyal Animasi (Cukup sekali saja)
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
		
	# 3. Mainkan Transisi Masuk (Layar Hitam -> Bening)
	fade_transition.show()
	animation_player.play_backwards("Fade_In")


# --- Logika Tampilan Tombol (Carousel) ---
func update_button_visibility():
	for i in range(menu_buttons.size()):
		if i == current_index:
			menu_buttons[i].show()
		else:
			menu_buttons[i].hide()

func _on_right_arrow_pressed():
	current_index = (current_index + 1) % menu_buttons.size()
	update_button_visibility()

func _on_left_arrow_pressed():
	# Rumus modulo untuk mundur (handling angka negatif)
	current_index = (current_index - 1 + menu_buttons.size()) % menu_buttons.size()
	update_button_visibility()


# --- Logika Tombol Aksi ---

# Fungsi pusat untuk memulai transisi keluar
func _start_transition(type: String):
	# Cegah tombol ditekan dua kali saat transisi sedang berjalan
	if button_type != "":
		return
	
	button_type = type
	
	# Mulai animasi menghitam (Fade Out Visual)
	fade_transition.show()
	animation_player.play("Fade_In")

func _on_start_button_pressed():
	_start_transition("start")

func _on_option_button_pressed():
	# HAPUS baris change_scene di sini agar animasi sempat jalan!
	_start_transition("option")

func _on_credit_button_pressed():
	# Jika belum ada scene credit, biarkan kosong atau print dulu
	print("Credit ditekan")
	# _start_transition("credit") 

func _on_quit_button_pressed():
	get_tree().quit()


# --- Logika Setelah Animasi Selesai ---
# Fungsi ini otomatis dipanggil saat AnimationPlayer selesai main
func _on_animation_finished(anim_name):
	if anim_name == "Fade_In":
		# Cek tombol apa yang tadi ditekan, lalu pindah scene
		if button_type == "start":
			get_tree().change_scene_to_file("res://scenes/prologue.tscn")
			
		elif button_type == "option":
			get_tree().change_scene_to_file("res://scenes/options_menu.tscn")
		
		# Reset button_type (opsional, untuk keamanan)
		# button_type = ""
