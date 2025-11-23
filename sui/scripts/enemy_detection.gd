extends CharacterBody2D

const SPEED = 40
# const MAX_CHASE_DISTANCE = 120 # <-- KITA HAPUS
const GRAVITY = 980

var player_ref = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
# @onready var ray_cast_right: RayCast2D = $RayCastRight # <-- TIDAK PERLU LAGI
# @onready var ray_cast_left: RayCast2D = $RayCastLeft   # <-- TIDAK PERLU LAGI

func _ready() -> void:
	pass

# Fungsi ini sudah sempurna. Saat player masuk, kita 'simpan' referensinya.
func _on_detection_area_body_entered(body: Node2D) -> void:
	player_ref = body

# Fungsi ini sudah sempurna. Saat player keluar, kita 'lupakan' referensinya.
func _on_detection_area_body_exited(_body: Node2D) -> void:
	player_ref = null


# --- INI BAGIAN UTAMA YANG BERUBAH ---
func _physics_process(delta):
	
	# 1. Terapkan Gravitasi (Tetap sama)
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 2. Cek apakah kita punya target (player_ref)
	if player_ref != null:
		# --- LOGIKA MENGEJAR ---
		# Player ada di dalam zona, jadi kita kejar dia.
		
		# Dapatkan arah ke player
		var direction_to_player = (player_ref.global_position - global_position).normalized()
		
		# Atur kecepatan horizontal untuk mengejar player
		velocity.x = direction_to_player.x * SPEED
		
		# Balik sprite agar menghadap player
		if direction_to_player.x > 0:
			animated_sprite.flip_h = false # Menghadap kanan
		else:
			animated_sprite.flip_h = true # Menghadap kiri
		
	else:
		# --- LOGIKA DIAM / IDLE ---
		# Player ada di luar zona (player_ref adalah null)
		
		# Berhenti bergerak
		velocity.x = 0 
		
		# Mainkan animasi diam
		animated_sprite.play("idle")

	# 3. Terapkan semua gerakan!
	move_and_slide()
