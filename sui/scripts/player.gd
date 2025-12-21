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

# --- REFERENSI UI (PLAN B) ---
@onready var coin_label: Label = $CanvasLayer/CoinLabel
@onready var life_label: Label = $CanvasLayer/LifeLabel
# Ambil referensi GameManager (Pastikan GameManager punya Unique Name %GameManager)
@onready var game_manager = %GameManager


func _physics_process(delta: float) -> void:
	# --- [BARU] UPDATE UI SETIAP FRAME ---
	update_ui()

	# 1. Terapkan Gravitasi
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- LOGIKA SERANGAN ---
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

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

	# --- ANIMASI ---
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


# --- [BARU] FUNGSI UPDATE UI ---
func update_ui():
	# Update Text Nyawa (Ambil dari Script Global)
	if life_label:
		life_label.text = "Lives: " + str(Global.lives)
	
	# Update Text Koin (Ambil dari GameManager)
	if coin_label and game_manager:
		coin_label.text = "Coins: " + str(game_manager.score) + " / " + str(game_manager.total_coins)


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
	# --- LOGIKA KEMATIAN DENGAN NYAWA ---
	if animated_sprite.animation == "dies":
		
		# 1. Kurangi nyawa di Global script
		var sisa_nyawa = Global.decrease_life()
		
		# 2. Cek sisa nyawa
		if sisa_nyawa > 0:
			# Jika masih punya nyawa -> Ulangi Level
			print("Mati! Sisa nyawa: ", sisa_nyawa)
			Engine.time_scale = 1.0
			get_tree().reload_current_scene()
			
		else:
			# Jika nyawa habis -> GAME OVER (Kembali ke Main Menu)
			print("GAME OVER! Tidak ada nyawa tersisa.")
			Engine.time_scale = 1.0
			
			# Reset nyawa jadi penuh lagi untuk permainan berikutnya
			Global.reset_lives()
			
			# Ganti scene ke Main Menu
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		
	# --- LOGIKA SERANGAN (TETAP SAMA) ---
	elif animated_sprite.animation == "attack":
		is_attacking = false
		hitbox_collision.set_deferred("disabled", true)


# --- SINYAL SERANGAN KENA MUSUH ---
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(1)


func _on_boss_trigger_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
