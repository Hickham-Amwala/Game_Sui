extends Camera2D

# Kuat getarannya (Pixel)
var shake_amount = 0
# Seberapa cepat getarannya hilang
var shake_decay = 5.0

func _process(delta):
	if shake_amount > 0:
		# Acak posisi offset kamera
		offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		# Kurangi kekuatan getaran perlahan
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
	else:
		offset = Vector2.ZERO

# Fungsi ini yang akan dipanggil oleh Boss
func apply_shake(amount = 5.0):
	shake_amount = amount
