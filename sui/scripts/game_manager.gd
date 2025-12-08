extends Node

signal level_unlocked

var score = 0
var total_coins = 0
# [BARU] Variabel untuk mengecek status bos
var is_boss_dead = false 

@onready var score_label: Label = $ScoreLabel

func _ready():
	# Hitung total koin
	total_coins = get_tree().get_node_count_in_group("coins")
	# Pastikan status bos reset saat game mulai
	is_boss_dead = false 
	
	update_ui()
	print("Target: ", total_coins, " Koin + Kalahkan Bos")

func add_point():
	score += 1
		
	check_level_completion()

# [BARU] Fungsi ini dipanggil oleh BOS saat dia mati
func boss_defeated():
	print("Laporan diterima: Bos telah dikalahkan!")
	is_boss_dead = true
	# Cek apakah syarat menang terpenuhi
	check_level_completion()

# [BARU] Fungsi Pengecekan Utama
func check_level_completion():
	# Syarat: Koin Penuh DAN Bos Mati
	if score == total_coins and is_boss_dead:
		print("SYARAT LENGKAP! KUNCI MUNCUL!")
		level_unlocked.emit()
	else:
		# Opsional: Beri info ke player apa yang kurang
		if score < total_coins:
			print("Belum bisa, koin kurang!")
		if not is_boss_dead:
			print("Belum bisa, bos masih hidup!")

func update_ui():
	if score_label:
		score_label.text = "Coins: " + str(score) + " / " + str(total_coins)
