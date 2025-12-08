extends Node

# Data Pemain yang harus diingat terus
var lives = 3 # Jumlah nyawa awal
var max_lives = 3

# Kita pindahkan skor ke sini juga biar aman (opsional)
# Tapi untuk tutorial ini, kita fokus ke nyawa saja dulu.

func decrease_life():
	lives -= 1
	print("Nyawa berkurang! Sisa: ", lives)
	return lives

func reset_lives():
	lives = max_lives
