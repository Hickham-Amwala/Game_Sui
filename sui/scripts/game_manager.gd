extends Node

signal level_unlocked

var score = 0
var total_coins = 0
var is_boss_dead = false 

@onready var score_label: Label = $ScoreLabel

func _ready():
	# 1. Hitung total koin yang ada di level ini
	total_coins = get_tree().get_node_count_in_group("coins")
	
	# Reset status boss
	is_boss_dead = false 
	
	# 2. Pastikan Label Pesan SEMBUNYI di awal game
	if score_label:
		score_label.visible = false
		# Kita TIDAK mengubah .text disini, jadi teksnya
		# akan tetap sesuai dengan yang Anda ketik di Editor.

func add_point():
	score += 1
	print("Koin terkumpul: ", score, " / ", total_coins)
	
	# Setiap ambil koin, cek apakah syarat menang sudah terpenuhi?
	check_level_completion()

func boss_defeated():
	print("Laporan: Boss telah dikalahkan!")
	is_boss_dead = true
	
	# 1. Munculkan Pesan Kemenangan (Label)
	if score_label:
		score_label.visible = true # Cukup bikin visible, teksnya sudah ada
	
	# 2. Cek apakah syarat menang sudah terpenuhi?
	check_level_completion()

func check_level_completion():
	# --- SYARAT KETAT ---
	# Level Unlocked HANYA JIKA:
	# 1. Skor koin sama dengan Total Koin (Semua koin diambil)
	# 2. DAN Boss sudah mati
	
	if score >= total_coins and is_boss_dead:
		print("SYARAT LENGKAP! (Semua Koin + Boss Mati). Level Selesai!")
		level_unlocked.emit()
	else:
		# Info Debugging (Cek di Output bawah kalau penasaran kenapa belum menang)
		print("Belum Selesai. Koin: ", score, "/", total_coins, " | Boss Mati: ", is_boss_dead)
