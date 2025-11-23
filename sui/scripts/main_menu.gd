extends Control

# --- Referensi Node (Lebih Rapi) ---
# Menggunakan @export untuk array, sisanya @onready
@export var menu_buttons: Array[Button]
@onready var musik: AudioStreamPlayer2D = %musik
@onready var fade_transition: Control = $FadeTransition
@onready var animation_player: AnimationPlayer = $FadeTransition/AnimationPlayer

# --- Variabel State ---
var current_index: int = 0
var button_type: String = "" # Tipe tombol yang ditekan


func _ready():
	update_button_visibility()
	
	# PENTING: Kita hubungkan sinyal 'animation_finished' dari AnimationPlayer
	# ke fungsi kita. Ini menggantikan logika Timer Anda yang lama.
	animation_player.animation_finished.connect(_on_animation_finished)

# --- Logika Tampilan Tombol ---
# Fungsi ini sudah bagus, tidak perlu diubah
func update_button_visibility():
	for i in range(menu_buttons.size()):
		if i == current_index:
			menu_buttons[i].show()
		else:
			menu_buttons[i].hide()

# --- Logika Carousel (Dirapikan) ---
# Menggunakan modulo (%) agar lebih ringkas dan elegan
func _on_right_arrow_pressed():
	current_index = (current_index + 1) % menu_buttons.size()
	update_button_visibility()

func _on_left_arrow_pressed():
	# Modulo untuk angka negatif perlu trik kecil ini agar aman
	current_index = (current_index - 1 + menu_buttons.size()) % menu_buttons.size()
	update_button_visibility()


# --- Logika Tombol Aksi (Dirapikan) ---

# Fungsi terpusat untuk memulai transisi
func _start_transition(type: String):
	# Hanya jalankan jika kita tidak sedang dalam transisi
	if not button_type == "":
		return
	
	button_type = type
	
	# 1. Mulai fade out musik DULU (seperti obrolan kita)
	var tween = create_tween()
	tween.tween_property(musik, "volume_db", -80.0, 1.0) # Fade out selama 1 detik
	tween.finished.connect(_on_music_fade_out_finished)

func _on_start_button_pressed():
	_start_transition("start")

func _on_option_button_pressed():
	_start_transition("option")

func _on_credit_button_pressed():
	_start_transition("credit")

func _on_quit_button_pressed():
	# Di sini juga bisa ditambahkan fade out musik/visual jika mau
	get_tree().quit()


# --- Logika Transisi Scene (Dirapikan) ---

# Fungsi ini berjalan SETELAH musik selesai fade out
func _on_music_fade_out_finished():
	# 2. SETELAH musik senyap, BARU mainkan animasi fade visual
	fade_transition.show()
	animation_player.play("Fade_In")

# Fungsi ini berjalan SETELAH animasi visual "Fade_In" selesai
# (Terkoneksi di func _ready())
func _on_animation_finished(anim_name):
	# Pastikan ini adalah animasi yang benar-benar kita tunggu
	if anim_name == "Fade_In":
		
		# 3. SETELAH layar hitam, BARU ganti scene
		if button_type == "start":
			get_tree().change_scene_to_file("res://scenes/stage1.tscn")
		elif button_type == "option":
			prints("option opened")
			# TODO: Mungkin ganti ke scene "options" di sini?
			# get_tree().change_scene_to_file("res://scenes/options_menu.tscn")
			
			# Untuk saat ini, kita sembunyikan lagi fade-nya agar tidak "stuck"
			animation_player.play_backwards("Fade_In")
			button_type = ""
