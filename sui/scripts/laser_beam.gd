extends Area2D

func _ready():
	set_deferred("monitoring", false)
	visible = false

func _physics_process(_delta):
	if visible:
		# Debugging: Cek frame laser berjalan atau tidak
		# print("Frame Laser: ", $AnimatedSprite2D.frame)
		
		# Logika Damage (Frame > 12)
		if $AnimatedSprite2D.frame > 8:
			if monitoring == false:
				set_deferred("monitoring", true)
				print("Laser MEMATIKAN sekarang!")
		else:
			if monitoring == true:
				set_deferred("monitoring", false)

# Fungsi ini dipanggil Boss berkali-kali, jadi kita harus memfilternya
func fire():
	# --- [PERBAIKAN UTAMA] ---
	# Jika laser SUDAH terlihat (sedang nembak), JANGAN reset animasinya!
	if visible == true:
		return 
	
	# Jika belum nembak, baru kita mulai
	print("Mulai Laser!")
	visible = true
	$AnimatedSprite2D.frame = 0 
	$AnimatedSprite2D.play("default") # Pastikan nama animasi Anda "default"
	
	set_deferred("monitoring", false) 

func stop_firing():
	# Hanya matikan jika memang sedang nyala
	if visible == true:
		visible = false
		set_deferred("monitoring", false)
		$AnimatedSprite2D.stop()

# --- DETEKSI TABRAKAN ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("die"):
			body.die()
