extends Area2D

func _ready():
	# Matikan deteksi tabrakan di awal agar tidak melukai player saat sembunyi
	monitoring = false

# Fungsi untuk menyalakan laser (Dipanggil oleh Bos)
func fire():
	visible = true
	monitoring = true
	$AnimatedSprite2D.play("default")

# Fungsi untuk mematikan laser (Dipanggil oleh Bos)
func stop_firing():
	visible = false
	monitoring = false
	$AnimatedSprite2D.stop()

# --- DETEKSI TABRAKAN ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("die"):
			body.die()
