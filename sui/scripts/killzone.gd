extends Area2D

# Kita tidak perlu @onready var timer lagi

func _on_body_entered(body: Node2D) -> void:
	
	# 1. Cek apakah itu player
	if body.is_in_group("player"):
		
		# 2. Cek apakah player punya fungsi "die" (untuk keamanan)
		if body.has_method("die"):
			
			# 3. CUKUP PANGGIL FUNGSI 'die()' PADA PLAYER
			body.die()
			
			# Tidak ada lagi timer atau reload scene di sini.
			# Player akan mengurusnya sendiri.

# Kita tidak perlu fungsi _on_timer_timeout() lagi
