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

# --- [BARU] VARIABEL CUTSCENE (EVENT) ---
var is_cutscene: bool = false # Penanda apakah player sedang dalam mode event/cutscene
# ----------------------------------------

# --- [BARU] VARIABEL COOLDOWN ES ---
var can_fire_ice = true
var ice_cooldown_time = 1 
# -----------------------------------
var is_casting_ice: bool = false 

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
	# --- [BARU] LOGIKA CUTSCENE (PRIORITAS TERTINGGI) ---
	# Jika sedang cutscene, player dipaksa diam tapi tetap kena gravitasi
	if is_cutscene:
		velocity.x = 0 # Stop gerak kiri/kanan
		
		# Tetap terapkan gravitasi agar kaki menapak tanah
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			# Jika di tanah, mainkan animasi diam
			animated_sprite.play("idle")
			
		move_and_slide()
		return # STOP! Jangan baca kode input tombol di bawah ini
	# ----------------------------------------------------

	update_ui()
	
	# --- LOGIKA CHARGE ES ---
	if is_casting_ice:
		velocity = Vector2.ZERO 
		move_and_slide()
		return 

	# Kode gravitasi normal 
	if not is_on_floor():
		velocity += get_gravity() * delta

	# CEGAH GERAK SAAT NEMBAK LASER 
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

	# --- INPUT TEMBAK ES ---
	if Input.is_action_pressed("shoot_ice") and can_fire_ice:
		fire_ice()
	# -----------------------

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
		animated_sprite.flip_h = false
		if laser_beam:
			laser_beam.position.x = abs(default_laser_x)
			laser_beam.scale.x = abs(initial_laser_scale.x)
			laser_beam.scale.y = abs(initial_laser_scale.y)
			
	elif direction < 0:
		animated_sprite.flip_h = true
		if laser_beam:
			laser_beam.position.x = -abs(default_laser_x)
			laser_beam.scale.x = -abs(initial_laser_scale.x)
			laser_beam.scale.y = abs(initial_laser_scale.y)
			
	else:
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

# --- [BARU] FUNGSI YANG DIPANGGIL OLEH TRIGGER EVENT ---
# Fungsi ini akan dipanggil oleh script StunEventTrigger
func set_cutscene_mode(active: bool):
	is_cutscene = active
	if active:
		# Reset kecepatan horizontal biar langsung berhenti
		velocity.x = 0
		# Matikan animasi serangan/charge jika sedang jalan
		is_attacking = false
		is_casting_ice = false
		is_casting_laser = false
		hitbox_collision.set_deferred("disabled", true)
# -------------------------------------------------------

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

# --- FUNGSI TEMBAK ES ---
func fire_ice():
	if not Global.has_ice_ability: return
	if is_casting_ice: return
	
	can_fire_ice = false
	
	if is_attacking:
		is_attacking = false
		hitbox_collision.set_deferred("disabled", true)
	
	is_casting_ice = true
	velocity = Vector2.ZERO 
	
	var ice = ICE_SCENE.instantiate()
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
	
	var ice_sprite = ice.get_node("AnimatedSprite2D")
	if ice_sprite:
		await ice_sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	is_casting_ice = false
	
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
