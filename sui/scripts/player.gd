extends CharacterBody2D

signal player_died

const SPEED = 70
const JUMP_VELOCITY = -300.0

# --- [BARU] PRELOAD SCENE PELURU ES ---
const ICE_SCENE = preload("res://scenes/ice_projectile.tscn")
# --------------------------------------

var is_attacking: bool = false
var is_dead: bool = false
var is_casting_laser: bool = false 

# --- [BARU] VARIABEL COOLDOWN ES ---
var can_fire_ice = true
var ice_cooldown_time = 1 # Jeda tembak 0.5 detik
# -----------------------------------
var is_casting_ice: bool = false # Penanda sedang charge es
# --- VARIABEL UNTUK MEREKAM POSISI & SKALA ASLI ---
var default_laser_x: float = 0.0
var initial_laser_scale: Vector2 = Vector2(1, 1) 
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
		
		# --- REKAM SETTINGAN EDITOR ---
		default_laser_x = laser_beam.position.x
		initial_laser_scale = laser_beam.scale
		# ------------------------------

func _physics_process(delta: float) -> void:
	update_ui()
	
	# --- [BARU] LOGIKA CHARGE ES (DIAM TOTAL) ---
	# Jika sedang casting es, hentikan semua gerakan & gravitasi
	if is_casting_ice:
		velocity = Vector2.ZERO # Berhenti total (melayang jika di udara)
		move_and_slide()
		return # Stop baca kode di bawahnya
	# --------------------------------------------

	# Kode gravitasi normal (Jalan kalau TIDAK casting es)
	if not is_on_floor():
		velocity += get_gravity() * delta

	# CEGAH GERAK SAAT NEMBAK LASER (Yang lama tetap ada)
	if is_casting_laser:
		velocity.x = 0
		animated_sprite.play("idle")
		move_and_slide()
		return 
	
	# ... (Sisa kode movement lainnya tetap sama) ...

	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	if Input.is_action_just_pressed("shoot"):
		fire_laser()

	# --- [BARU] INPUT TEMBAK ES (Pastikan Input Map 'shoot_ice' sudah dibuat) ---
	if Input.is_action_pressed("shoot_ice") and can_fire_ice:
		fire_ice()
	# ---------------------------------------------------------------------------

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()

	var can_jump: bool = jump_buffer_timer.is_stopped() == false and is_on_floor()

	if can_jump:
		velocity.y = JUMP_VELOCITY
		jump_sfx.play()
		jump_buffer_timer.stop()

	var direction := Input.get_axis("move left", "move right")

	# --- LOGIKA ARAH & UKURAN LASER ---
	if direction > 0:
		# HADAP KANAN
		animated_sprite.flip_h = false
		if laser_beam:
			laser_beam.position.x = abs(default_laser_x)
			laser_beam.scale.x = abs(initial_laser_scale.x)
			laser_beam.scale.y = abs(initial_laser_scale.y)
			
	elif direction < 0:
		# HADAP KIRI
		animated_sprite.flip_h = true
		if laser_beam:
			laser_beam.position.x = -abs(default_laser_x)
			laser_beam.scale.x = -abs(initial_laser_scale.x)
			laser_beam.scale.y = abs(initial_laser_scale.y)
			
	else:
		# SAAT DIAM
		if laser_beam:
			laser_beam.scale.y = abs(initial_laser_scale.y)
	# ----------------------------------

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
	if not Global.has_laser_ability: return
	if is_casting_laser: return 
	if not is_on_floor(): return 
	
	if is_attacking:
		is_attacking = false
		hitbox_collision.set_deferred("disabled", true)

	is_casting_laser = true
	velocity.x = 0 
	
	if laser_beam:
		laser_beam.fire()
		await laser_beam.get_node("AnimatedSprite2D").animation_finished
		await get_tree().create_timer(0.5).timeout
		
	is_casting_laser = false

# --- [BARU] FUNGSI TEMBAK ES ---
func fire_ice():
	if not Global.has_ice_ability: return
	
	# [BARU] Cek: Jangan nembak kalau lagi casting (biar ga double)
	if is_casting_ice: return
	
	can_fire_ice = false
	
	# Batalkan serangan melee jika sedang memukul
	if is_attacking:
		is_attacking = false
		hitbox_collision.set_deferred("disabled", true)
	
	# 1. MULAI MODE DIAM (FREEZE)
	is_casting_ice = true
	velocity = Vector2.ZERO # Reset kecepatan biar langsung berhenti
	
	# (Opsional) Mainkan animasi player tertentu, misal 'idle' atau 'attack'
	# animated_sprite.play("attack") 
	
	# 2. Instantiate Peluru
	var ice = ICE_SCENE.instantiate()
	
	# Setup Offset
	var vertical_offset = -5 
	if animated_sprite.flip_h: 
		ice.global_position = global_position + Vector2(-25, vertical_offset)
		ice.direction = -1
		ice.get_node("AnimatedSprite2D").flip_h = true 
	else: 
		ice.global_position = global_position + Vector2(25, vertical_offset)
		ice.direction = 1
		ice.get_node("AnimatedSprite2D").flip_h = false
		
	get_tree().root.add_child(ice)
	
	# 3. TUNGGU ANIMASI PELURU SELESAI (SINKRONISASI)
	# Kita akses Sprite di dalam peluru untuk tahu kapan animasi "spawn" beres
	var ice_sprite = ice.get_node("AnimatedSprite2D")
	
	# Pastikan node sprite ada biar ga error
	if ice_sprite:
		# Player diam menunggu sinyal 'animation_finished' dari peluru es
		await ice_sprite.animation_finished
	else:
		# Fallback kalau error: tunggu manual 0.5 detik
		await get_tree().create_timer(0.5).timeout
	
	# 4. KEMBALI GERAK
	is_casting_ice = false
	
	# Timer cooldown tembakan berikutnya
	await get_tree().create_timer(ice_cooldown_time).timeout
	can_fire_ice = true

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


func _on_boss_trigger_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
