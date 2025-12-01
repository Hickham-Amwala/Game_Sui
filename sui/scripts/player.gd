extends CharacterBody2D

signal player_died

# --- KONSTANTA ---
const SPEED = 70
const JUMP_VELOCITY = -300.0

# --- VARIABEL STATE ---
var is_attacking: bool = false
var is_dead: bool = false

# --- REFERENSI NODE ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sfx: AudioStreamPlayer2D = $Jump
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D 


func _physics_process(delta: float) -> void:
	# 1. Terapkan Gravitasi
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- [UBAHAN 1] LOGIKA SERANGAN ---
	# Kita HAPUS 'is_on_floor()' agar bisa nyerang sambil loncat
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	# --- [UBAHAN 2] KITA HAPUS BLOKIR GERAKAN ---
	# Dulu di sini ada 'if is_attacking: return'. 
	# Sekarang kita HAPUS supaya player tetap bisa jalan/loncat saat duri keluar.

	# 2. Tangkap INPUT Lompat (Buffer)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()

	# 3. EKSEKUSI Lompat
	var can_jump: bool = jump_buffer_timer.is_stopped() == false and is_on_floor()

	if can_jump:
		velocity.y = JUMP_VELOCITY
		jump_sfx.play()
		jump_buffer_timer.stop()

	# 4. Input Gerakan Kiri/Kanan
	var direction := Input.get_axis("move left", "move right")

	# 5. Flip Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# --- [UBAHAN 3] ANIMASI ---
	# Kita hanya boleh ganti animasi jalan/idle JIKA TIDAK SEDANG MENYERANG.
	# Kalau sedang menyerang, biarkan animasi 'attack' yang main.
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("walk")
		else:
			animated_sprite.play("jump")

	# 7. Hitung Kecepatan
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


# --- FUNGSI SERANGAN ---
func attack():
	is_attacking = true
	animated_sprite.play("attack")
	hitbox_collision.set_deferred("disabled", false)


# --- FUNGSI KEMATIAN ---
func die():
	if is_dead:
		return
	is_dead = true
	player_died.emit()
	set_physics_process(false) 
	death_sound.play()
	animated_sprite.play("dies") 
	$CollisionShape2D.set_deferred("disabled", true)
	Engine.time_scale = 0.5


# --- PENGENDALI ANIMASI SELESAI ---
func _on_animated_sprite_animation_finished():
	if animated_sprite.animation == "dies":
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
		
	# Saat animasi attack selesai, matikan mode attack
	elif animated_sprite.animation == "attack":
		is_attacking = false 
		hitbox_collision.set_deferred("disabled", true)
		# Tidak perlu panggil .play("idle") disini, karena _physics_process akan menanganinya


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(1)
