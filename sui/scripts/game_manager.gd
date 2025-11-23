extends Node

# 1. Tambahkan Sinyal ini
# Ini adalah "teriakan" yang akan didengar oleh Pintu nanti
signal level_unlocked

var score = 0
var total_coins = 0 # Variabel untuk menyimpan jumlah total koin di level

@onready var score_label: Label = $ScoreLabel

func _ready():
	# 2. Hitung jumlah koin yang ada di level secara otomatis
	# Pastikan Anda sudah memasukkan Coin ke grup "coins"
	total_coins = get_tree().get_node_count_in_group("coins")
	
	# Opsional: Update label awal
	# score_label.text = "You get " + str(score) + " / " + str(total_coins) + " coins"
	print("Total Koin di Level ini: ", total_coins)

func add_point():
	score += 1
	
	# Update text UI Anda (Saya pertahankan format Anda)
	# Opsional: Anda bisa ubah jadi str(score) + "/" + str(total_coins) agar pemain tahu targetnya
	score_label.text = "You get " + str(score) + " coins"
	
	# 3. CEK APAKAH SEMUA KOIN SUDAH DIAMBIL?
	if score == total_coins:
		print("SELAMAT! KUNCI TERBUKA!")
		# Kirim sinyal agar Pintu terbuka
		level_unlocked.emit()
