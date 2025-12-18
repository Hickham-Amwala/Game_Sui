extends Control

signal back_pressed
var is_in_main_menu: bool = true
# Referensi Node Slider
@onready var music_slider = $VBoxContainer/MusicSlider
@onready var sfx_slider = $VBoxContainer/SfxSlider
@onready var animation_player = $FadeTransition/AnimationPlayer
@onready var panel: Panel = $Panel


# Ambil Index (Nomor Urut) dari Audio Bus
# Pastikan nama string "Music" dan "SFX" sama persis dengan di panel Audio bawah!
var music_bus_index
var sfx_bus_index

func _ready():
	animation_player.play_backwards("Fade_In")
	# 1. Cari tahu nomor urut bus-nya
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	# 2. Set posisi slider sesuai volume saat ini (agar tidak reset saat menu dibuka)
	# Kita ubah dari dB kembali ke Linear agar slider mengerti
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))

func enable_ingame_mode():
	is_in_main_menu = false
	if panel :
		panel.visible = false

# --- HUBUNGKAN SINYAL VALUE_CHANGED DARI SLIDER KE SINI ---
func _on_music_slider_value_changed(value):
	# Ubah volume Bus Music
	# linear_to_db mengubah angka 0-1 menjadi -80dB sampai 0dB
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value))

func _on_sfx_slider_value_changed(value):
	# Ubah volume Bus SFX
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))

func _on_back_button_pressed():
	back_pressed.emit()
	
	if is_in_main_menu:
		# --- PERBAIKAN ---
		# Paksa transisi muncul dan taruh di paling depan layar
		if $FadeTransition:
			$FadeTransition.show()
			$FadeTransition.move_to_front() # Trik coding untuk menaruh node di urutan paling bawah/depan
		
		# Mainkan animasi
		animation_player.play("Fade_In")
		await animation_player.animation_finished
		
		# Pindah Scene
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		visible = false
