extends CharacterBody2D

signal player_died

# --- Variabel dari script BARU (Pergerakan) ---
const SPEED = 70
const JUMP_VELOCITY = -300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump: AudioStreamPlayer2D = $Jump # Node suara untuk lompat
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

# --- Variabel dari script LAMA (Kematian) ---
@onready var death_sound: AudioStreamPlayer2D = $DeathSound # Node suara untuk mati
var is_dead: bool = false


# --- Fungsi _physics_process dari script BARU ---
func _physics_process(delta: float) -> void:
	# 1. Terapkan Gravitasi
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Tangkap INPUT Lompat
	# Jika kita menekan lompat (kapanpun), mulai timer buffer.
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()

	# 3. EKSEKUSI Lompat (Logika Baru)
	# Cek apakah buffer sedang berjalan DAN kita di lantai
	var can_jump: bool = jump_buffer_timer.is_stopped() == false and is_on_floor()

	if can_jump:
		velocity.y = JUMP_VELOCITY
		jump.play()
		jump_buffer_timer.stop() # Hentikan buffer agar tidak lompat dua kali

	# --- Sisa kode Anda (horizontal, animasi) tidak berubah ---

	# Get the input direction: -1, 0, 1
	var direction := Input.get_axis("move left", "move right")

	#flip the sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	#play animation
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("walk")
	else:
		animated_sprite.play("jump")

	#Speed calculation
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

# -----------------------------------------------------------------
# FUNGSI-FUNGSI DARI SCRIPT LAMA (UNTUK KEMATIAN)
# -----------------------------------------------------------------

# Fungsi ini akan dipanggil oleh killzone
func die():
	# Jika kita sudah mati, jangan jalankan ini lagi
	if is_dead:
		return
		
	is_dead = true
	player_died.emit()
	
	# 1. Hentikan semua logika di _physics_process di atas
	set_physics_process(false) 
	
	# 2. Mainkan suara kematian
	death_sound.play()
	
	# 3. Mainkan animasi mati
	# Ganti "mati" dengan nama animasi Anda jika berbeda
	animated_sprite.play("dies") 
	
	# 4. Matikan collision
	# BARIS BARU YANG SUDAH DIPERBAIKI
	$CollisionShape2D.set_deferred("disabled", true)
	
	# 5. Ambil alih logika timer dari killzone
	Engine.time_scale = 0.5


# Fungsi ini akan dipanggil saat animasi APAPUN selesai
func _on_animated_sprite_animation_finished():
	# Kita hanya peduli jika animasi yang selesai adalah "mati"
	if animated_sprite.animation == "dies":
		# Kembalikan waktu ke normal
		Engine.time_scale = 1.0
		# Muat ulang scene
		get_tree().reload_current_scene()
