extends Node

signal level_unlocked

var score = 0
var total_coins = 0
var is_boss_dead = false 

# [BARU] Variabel pengaman agar kunci tidak muncul dobel
var level_finished = false

@onready var score_label: Label = $ScoreLabel

func _ready():
	total_coins = get_tree().get_node_count_in_group("coins")
	is_boss_dead = false 
	level_finished = false # Reset status
	
	if score_label:
		score_label.visible = false

func add_point():
	score += 1
	print("Koin terkumpul: ", score, " / ", total_coins)
	check_level_completion()

func boss_defeated():
	print("Laporan: Boss telah dikalahkan!")
	is_boss_dead = true
	
	if score_label:
		score_label.visible = true 
	
	check_level_completion()

func check_level_completion():
	# Cek syarat: Koin Penuh, Boss Mati, DAN level belum selesai sebelumnya
	if score >= 0 and is_boss_dead and not level_finished:
		
		# 1. Kunci status level biar tidak terpanggil lagi
		level_finished = true
		
		print("Syarat lengkap! Menunggu 2 detik sebelum kunci muncul...")
		
		# 2. [INTI PERUBAHAN] Tunda selama 2 Detik
		await get_tree().create_timer(2.0).timeout
		
		# 3. Baru munculkan kunci/pintu
		print("Waktu habis! Kunci Muncul Sekarang.")
		level_unlocked.emit()
		
	else:
		# Info debug biasa
		if not level_finished:
			print("Belum Selesai. Koin: ", score, "/", total_coins, " | Boss Mati: ", is_boss_dead)
