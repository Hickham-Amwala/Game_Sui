extends CanvasLayer

@onready var menu_container = $CenterContainer
@onready var options_menu = $OptionsMenu

func _ready():
	visible = false
	options_menu.visible = false
	if options_menu:
		options_menu.enable_ingame_mode()
		options_menu.back_pressed.connect(_on_options_back)

# --- FUNGSI BARU UNTUK MENGATUR EFEK ---
func toggle_muffle(is_muffled: bool):
	var music_bus_idx = AudioServer.get_bus_index("Music")
	# Angka 0 adalah index efek LowPassFilter Anda di tab Audio
	AudioServer.set_bus_effect_enabled(music_bus_idx, 0, is_muffled)
# ---------------------------------------

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if options_menu.visible:
			_on_options_back()
		else:
			# Toggle Pause
			toggle_pause_state()

# Fungsi biar rapi, dipanggil oleh ESC dan Tombol Resume
func toggle_pause_state():
	visible = !visible
	get_tree().paused = visible
	
	# Panggil fungsi efek kita
	toggle_muffle(visible)

# --- FUNGSI TOMBOL ---

func _on_resume_button_pressed():
	# Jangan cuma visible = false, tapi panggil fungsi toggle biar efeknya juga mati!
	toggle_pause_state()

func _on_option_button_pressed():
	menu_container.visible = false
	options_menu.visible = true

func _on_quit_button_pressed():
	get_tree().paused = false
	toggle_muffle(false) # Pastikan efek mati sebelum keluar ke menu!
	MusicController.play_music()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_options_back():
	options_menu.visible = false
	menu_container.visible = true
