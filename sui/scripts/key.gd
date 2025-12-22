extends Area2D

# --- [TAMBAHKAN INI] ---
# Kita harus mendaftarkan sinyalnya dulu biar dikenali Stage 1
signal level_won 
# -----------------------

@onready var game_manager = %GameManager

func _ready():
	hide()
	$CollisionShape2D.disabled = true
	if game_manager:
		game_manager.level_unlocked.connect(_on_level_unlocked)

func _on_level_unlocked():
	show()
	$CollisionShape2D.set_deferred("disabled", false)
	# animated_sprite.play("start")

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Kunci diambil! Level Selesai.")
		
		# --- [SOLUSI: RESET NYAWA DISINI] ---
		# Karena ini momen kemenangan, kita reset nyawa di memori Global
		if Global:
			# Opsional: Jika kamu punya fungsi reset di Global script
			if Global.has_method("reset_lives"):
				Global.reset_lives()
			else:
				# Atau set manual ke angka maksimal (misal 3)
				Global.lives = 3 
		# ------------------------------------
		
		# Pancarkan sinyal agar Stage 1 merespons (Ganti Scene dll)
		level_won.emit()
		
		# Matikan kunci
		$CollisionShape2D.set_deferred("disabled", true)
		hide()
