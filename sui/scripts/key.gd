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
		print("Kunci diambil!")
		
		# --- [PENTING] ---
		# Pancarkan sinyal ini agar Stage 1 mendengarnya
		level_won.emit()
		# -----------------
		
		# Matikan kunci biar gak keambil 2x
		$CollisionShape2D.set_deferred("disabled", true)
		hide()
