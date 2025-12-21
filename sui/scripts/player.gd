extends CharacterBody2D

signal player_died

const SPEED = 70
const JUMP_VELOCITY = -300.0

var is_attacking: bool = false
var is_dead: bool = false
var is_casting_laser: bool = false 

# --- VARIABEL UNTUK MEREKAM POSISI & SKALA ASLI ---
var default_laser_x: float = 0.0
var initial_laser_scale: Vector2 = Vector2(1, 1) # Default jaga-jaga
# --------------------------------------------------

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sfx: AudioStreamPlayer2D = $Jump
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D 
@onready var laser_beam: Area2D = $LaserBeam

@onready var coin_label: Label = $CanvasLayer/CoinContainer/CoinLabel
@onready var life_label: Label = $CanvasLayer/LifeContainer/LifeLabel
@onready var game_manager = %GameManager

func _ready():
	if laser_beam:
		laser_beam.is_from_player = true
		laser_beam.visible = false 
		
		# --- [PENTING] REKAM SETTINGAN EDITOR ---
		# Catat posisi X asli
		default_laser_x = laser_beam.position.x
		# Catat Skala (ukuran) asli yang Anda atur di Inspector
		initial_laser_scale = laser_beam.scale
		# ----------------------------------------

func _physics_process(delta: float) -> void:
	update_ui()

	if not is_on_floor():
		velocity += get_gravity() * delta

	# CEGAH GERAK SAAT NEMBAK LASER
	if is_casting_laser:
		velocity.x = 0
		animated_sprite.play("idle")
		move_and_slide()
		return 

	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	if Input.is_action_just_pressed("shoot"):
		fire_laser()

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()

	var can_jump: bool = jump_buffer_timer.is_stopped() == false and is_on_floor()

	if can_jump:
		velocity.y = JUMP_VELOCITY
		jump_sfx.play()
		jump_buffer_timer.stop()

	var direction := Input.get_axis("move left", "move right")

	# --- LOGIKA ARAH & UKURAN LASER (PERBAIKAN TOTAL) ---
	if direction > 0:
		# HADAP KANAN
		animated_sprite.flip_h = false
		if laser_beam:
			# 1. Kembalikan posisi ke kanan
			laser_beam.position.x = abs(default_laser_x)
			
			# 2. Paksa ukuran kembali ke UKURAN ASLI (mengatasi penyok & kecil)
			# Kita gunakan 'abs' untuk memastikan nilainya positif (hadap kanan)
			laser_beam.scale.x = abs(initial_laser_scale.x)
			laser_beam.scale.y = abs(initial_laser_scale.y)
			
	elif direction < 0:
		# HADAP KIRI
		animated_sprite.flip_h = true
		if laser_beam:
			# 1. Pindahkan posisi ke kiri
			laser_beam.position.x = -abs(default_laser_x)
			
			# 2. Paksa ukuran ASLI tapi dibalik X-nya (mengatasi tidak berputar)
			laser_beam.scale.x = -abs(initial_laser_scale.x)
			laser_beam.scale.y = abs(initial_laser_scale.y)
			
	else:
		# SAAT DIAM (Jaga agar tetap konsisten)
		if laser_beam:
			# Pastikan scale Y tidak penyok saat diam
			laser_beam.scale.y = abs(initial_laser_scale.y)
			# Scale X biarkan saja mengikuti arah terakhirnya
	# ----------------------------------------------------

	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("walk")
		else:
			animated_sprite.play("jump")

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func update_ui():
	if life_label:
		life_label.text = "x " + str(Global.lives)
	if coin_label and game_manager:
		coin_label.text = "x " + str(game_manager.score) + " / " + str(game_manager.total_coins)


func attack():
	is_attacking = true
	animated_sprite.play("attack")
	hitbox_collision.set_deferred("disabled", false)


func fire_laser():
	# Cek syarat dasar
	if not Global.has_laser_ability: return
	if is_casting_laser: return 
	if not is_on_floor(): return 
	
	# --- [PERBAIKAN BUG] ---
	# Jika sedang memukul (melee), batalkan paksa!
	if is_attacking:
		is_attacking = false
		hitbox_collision.set_deferred("disabled", true)
	# -----------------------

	# Mulai proses laser
	is_casting_laser = true
	velocity.x = 0 
	
	if laser_beam:
		laser_beam.fire()
		# Tunggu animasi laser selesai
		await laser_beam.get_node("AnimatedSprite2D").animation_finished
		# Tunggu cooldown 1 detik
		await get_tree().create_timer(0.5).timeout
		
	is_casting_laser = false


func die():
	if is_dead: return
	is_dead = true
	player_died.emit()
	set_physics_process(false)
	death_sound.play()
	animated_sprite.play("dies")
	$CollisionShape2D.set_deferred("disabled", true)
	Engine.time_scale = 0.5

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
