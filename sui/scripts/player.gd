extends CharacterBody2D

signal player_died

# --- KONSTANTA ---
const SPEED = 70
const JUMP_VELOCITY = -300.0

# --- VARIABEL STATE ---
var is_attacking: bool = false
var is_dead: bool = false
# Simpan posisi X awal laser untuk referensi saat membalik arah
var default_laser_x: float = 0.0

# --- REFERENSI NODE ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sfx: AudioStreamPlayer2D = $Jump
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D 

# --- [MODIFIKASI] REFERENSI LASER ---
# Karena tidak ada Muzzle, kita langsung ambil node LaserBeam
@onready var laser_beam: Area2D = $LaserBeam

# --- REFERENSI UI ---
@onready var coin_label: Label = $CanvasLayer/CoinContainer/CoinLabel
@onready var life_label: Label = $CanvasLayer/LifeContainer/LifeLabel
@onready var game_manager = %GameManager

# --- SETUP AWAL ---
func _ready():
	# Beritahu laser kalau dia sekarang milik Player
	if laser_beam:
		laser_beam.is_from_player = true
		# Simpan posisi X yang sudah Anda atur di Editor sebagai posisi standar (Kanan)
		default_laser_x = laser_beam.position.x

func _physics_process(delta: float) -> void:
	update_ui()

	# 1. Terapkan Gravitasi
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- LOGIKA SERANGAN MELEE ---
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	# --- LOGIKA SERANGAN LASER ---
	if Input.is_action_just_pressed("shoot"):
		fire_laser()

	# 2. Tangkap INPUT Lompat
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()

	# 3. EKSEKUSI Lompat
	var can_jump: bool = jump_buffer_timer.is_stopped() == false and is_on_floor()

	if can_jump:
		velocity.y = JUMP_VELOCITY
		jump_sfx.play()
		jump_buffer_timer.stop()

	# 4. Input Gerakan
	var direction := Input.get_axis("move left", "move right")

	# 5. Flip Sprite & Laser Position
	if direction > 0:
		# HADAP KANAN
		animated_sprite.flip_h = false
		if laser_beam:
			laser_beam.scale.x = 1 # Laser normal
			laser_beam.position.x = abs(default_laser_x) # Posisi di kanan
			
	elif direction < 0:
		# HADAP KIRI
		animated_sprite.flip_h = true
		if laser_beam:
			laser_beam.scale.x = -1 # Laser dibalik
			laser_beam.position.x = -abs(default_laser_x) # Posisi pindah ke kiri

	# 6. Animasi Gerak
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


# --- FUNGSI UPDATE UI ---
func update_ui():
	if life_label:
		life_label.text = "x " + str(Global.lives)
	if coin_label and game_manager:
		coin_label.text = "x " + str(game_manager.score) + " / " + str(game_manager.total_coins)


# --- FUNGSI SERANGAN MELEE ---
func attack():
	is_attacking = true
	animated_sprite.play("attack")
	hitbox_collision.set_deferred("disabled", false)


# --- FUNGSI SERANGAN LASER ---
func fire_laser():
	if not Global.has_laser_ability:
		return
	
	if laser_beam:
		laser_beam.fire()


# --- FUNGSI KEMATIAN ---
func die():
	if is_dead: return
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
		var sisa_nyawa = Global.decrease_life()
		if sisa_nyawa > 0:
			Engine.time_scale = 1.0
			get_tree().reload_current_scene()
		else:
			Engine.time_scale = 1.0
			Global.reset_lives()
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			
	elif animated_sprite.animation == "attack":
		is_attacking = false
		hitbox_collision.set_deferred("disabled", true)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(1)
