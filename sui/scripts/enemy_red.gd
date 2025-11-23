extends CharacterBody2D # PASTIKAN ANDA SUDAH MENGUBAH TIPE NODE MENJADI CharacterBody2D

const SPEED = 40
const MAX_CHASE_DISTANCE = 120 # Saya ganti nama & besarkan nilainya, 60 terlalu dekat
const GRAVITY = 980 # Musuh butuh gravitasi agar jatuh ke lantai

# Variabel untuk arah patroli (1 = kanan, -1 = kiri)
var patrol_direction = -1
var player_ref = null

# Kita butuh referensi ke sprite untuk membaliknya (flip)
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft

# Fungsi _ready tidak perlu diubah
func _ready() -> void:
	pass # Kita tidak pakai start_position_x lagi, diganti RayCast

# Fungsi deteksi masuk tidak perlu diubah
func _on_detection_area_body_entered(body: Node2D) -> void:
	player_ref = body

# Fungsi deteksi keluar tidak perlu diubah
func _on_detection_area_body_exited(_body: Node2D) -> void:
	player_ref = null


# --- INI BAGIAN UTAMA YANG BERUBAH ---
func _physics_process(delta):
	
	# 1. Terapkan Gravitasi
	# Selalu tambahkan gravitasi agar musuh tidak melayang
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	else:
		# --- LOGIKA PATROLI ---
		# Player tidak ada (atau terlalu jauh), jadi kita patroli
		
		velocity.x = patrol_direction * SPEED
		
		# Balik sprite sesuai arah patroli
		if patrol_direction > 0:
			animated_sprite.flip_h = false # Menghadap kanan
		else:
			animated_sprite.flip_h = true # Menghadap kiri
		
		# --- LOGIKA BALIK ARAH ASIMETRIS ---
		# Cek dua kondisi berbeda untuk berbalik arah
		
		# Kondisi 1: Bergerak ke KANAN (dir=1) DAN menabrak DINDING
		var turn_at_wall = (patrol_direction == 1 and not ray_cast_right.is_colliding())
		
		# Kondisi 2: Bergerak ke KIRI (dir=-1) DAN mendeteksi JURANG
		var turn_at_ledge = (patrol_direction == -1 and not ray_cast_left.is_colliding())
		
		# Jika SALAH SATU kondisi terpenuhi, balik arah
		if turn_at_wall or turn_at_ledge:
			patrol_direction *= -1 # Balik arah (1 * -1 = -1, -1 * -1 = 1)

	# 3. Terapkan semua gerakan!
	move_and_slide()
