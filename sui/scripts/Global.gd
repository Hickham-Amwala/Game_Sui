extends Node

# --- DATA PEMAIN ---
var lives = 3 
var max_lives = 3

var has_laser_ability = true
var has_ice_ability = false

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
