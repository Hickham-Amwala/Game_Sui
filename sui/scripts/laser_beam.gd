extends Area2D

# Variable agar laser tahu dia milik siapa
var is_from_player = false

func _ready():
	set_deferred("monitoring", false)
	visible = false
	
	# Hubungkan sinyal jika animasi selesai
	# Agar setelah "DUAR", lasernya hilang sendiri
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta):
	if visible:
		# Logika "Jeda" kamehameha (Sama persis seperti Boss)
		# Frame 0-8: Charging (Belum sakit)
		# Frame > 8: Blasting (Sakit)
		if $AnimatedSprite2D.frame > 8:
			if monitoring == false:
				set_deferred("monitoring", true)
				# print("Duar! Laser sakit sekarang!")
		else:
			if monitoring == true:
				set_deferred("monitoring", false)

func fire():
	if visible: return # Jangan restart kalau sedang nyala
	
	visible = true
	$AnimatedSprite2D.frame = 0
	$AnimatedSprite2D.play("default")
	set_deferred("monitoring", false)

func stop_firing():
	visible = false
	set_deferred("monitoring", false)
	$AnimatedSprite2D.stop()

# --- LOGIKA OTOMATIS MATI (Khusus Player) ---
func _on_animation_finished():
	# Kalau ini punya Player, laser otomatis mati setelah animasi selesai
	# Kalau punya Boss, biasanya Boss yang atur kapan mati (via stop_firing)
	if is_from_player:
		stop_firing()

# --- LOGIKA TABRAKAN (PINTAR) ---
func _on_body_entered(body):
	if is_from_player:
		# Jika Punya Player -> Serang MUSUH
		if body.is_in_group("enemies") or body.name == "Boss":
			if body.has_method("die"): body.die()
			elif body.has_method("take_damage"): body.take_damage(1)
	else:
		# Jika Punya Boss -> Serang PLAYER
		if body.name == "Player":
			if body.has_method("die"): body.die()
			# elif body.has_method("hurt"): body.hurt()
