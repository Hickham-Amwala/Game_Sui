extends Node

# --- DATA PEMAIN ---
var lives = 3 
var max_lives = 3

# [PENTING] 
# Saya set 'true' dulu supaya kamu bisa tes tembak laser SEKARANG.
# Nanti kalau Boss Battle dan item drop-nya sudah jadi, 
# UBAH KEMBALI ini menjadi 'false' ya!
var has_laser_ability = true 

# --- DATA SKOR ---
# Kamu tadi bilang mau pindahkan skor ke sini biar aman, jadi saya tambahkan sekalian.
var score = 0 


# --- FUNGSI MANAGEMEN NYAWA ---
func decrease_life():
	lives -= 1
	print("Nyawa berkurang! Sisa: ", lives)
	return lives

func reset_lives():
	lives = max_lives
