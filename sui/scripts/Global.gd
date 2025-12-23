extends Node

# --- DATA PEMAIN ---
var lives = 3 
var max_lives = 5

var has_laser_ability = false
var has_ice_ability = false

# --- DATA SKOR ---
var score = 0 


# --- FUNGSI MANAGEMEN NYAWA ---
func decrease_life():
	lives -= 1
	print("Nyawa berkurang! Sisa: ", lives)
	return lives

func reset_lives():
	lives = max_lives
