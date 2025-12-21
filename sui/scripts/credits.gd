extends Control

# Ganti dengan path Main Menu kamu
@export_file("*.tscn") var main_menu_path = "res://scenes/main_menu.tscn"

@onready var vbox = $VBoxContainer
@onready var fade_transition: ColorRect = $FadeTransition

var scroll_speed = 60.0 # Kecepatan normal
var fast_speed = 250.0 # Kecepatan saat tombol ditekan
var current_speed = scroll_speed

var screen_height = 0.0
var is_exiting = false # [BARU] Penanda agar quit_credits tidak terpanggil 2x

func _ready():
	# 1. Ambil tinggi layar
	screen_height = get_viewport_rect().size.y
	
	# 2. Set posisi awal teks
	vbox.position.y = screen_height
	
	# --- [BARU] FADE IN (Layar Hitam -> Bening) ---
	# Pastikan node FadeTransition visible dan warnanya Hitam
	fade_transition.visible = true
	fade_transition.modulate.a = 1.0 # Set transparansi ke Penuh (Gelap)
	
	# Buat animasi pelan-pelan jadi bening (0.0)
	var tween = create_tween()
	tween.tween_property(fade_transition, "modulate:a", 0.0, 1.0)
	# ----------------------------------------------

func _process(delta):
	# Jika sedang proses keluar (Fade Out), matikan input & scroll
	if is_exiting: return
	
	# --- INPUT SPEED UP ---
	if Input.is_action_pressed("ui_accept"):
		current_speed = fast_speed
	else:
		current_speed = scroll_speed
	
	# --- INPUT SKIP (ESCAPE) ---
	if Input.is_action_just_pressed("ui_cancel"):
		quit_credits()

	# --- GERAKKAN TEKS KE ATAS ---
	vbox.position.y -= current_speed * delta
	
	# --- CEK APAKAH SUDAH SELESAI? ---
	if vbox.position.y < -vbox.size.y:
		quit_credits()

func quit_credits():
	# Cek: Jika sudah proses keluar, jangan jalankan lagi (biar gak error)
	if is_exiting: return
	is_exiting = true
	
	print("Credit selesai/skip. Memulai Fade Out...")

	# --- [BARU] FADE OUT (Layar Bening -> Hitam) ---
	var tween = create_tween()
	# Ubah alpha dari 0 (Bening) ke 1 (Hitam Pekat) dalam 1 detik
	tween.tween_property(fade_transition, "modulate:a", 1.0, 1.0)
	
	# Tunggu sampai animasi tween selesai
	await tween.finished
	# -----------------------------------------------
	
	# Baru pindah ke Main Menu setelah layar gelap
	if main_menu_path:
		get_tree().change_scene_to_file(main_menu_path)
	else:
		print("Selesai! (Path Main Menu belum diisi)")
