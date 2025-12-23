extends CharacterBody2D

# ==============================================================================
# 1. KONFIGURASI & KONSTANTA
# ==============================================================================
signal player_died

const SPEED = 72
const JUMP_VELOCITY = -300.0

# Preload Scenes
const ICE_SCENE = preload("res://scenes/ice_projectile.tscn")

# ==============================================================================
# 2. VARIABEL STATUS (STATE)
# ==============================================================================
# Status Player
var is_attacking: bool = false
var is_dead: bool = false
var is_cutscene: bool = false # Mode Event

# Status Skill
var is_casting_laser: bool = false 
var is_casting_ice: bool = false 

# Cooldowns
var can_fire_ice = true
var ice_cooldown_time = 1 

# Laser Settings
var default_laser_x: float = 0.0
var initial_laser_scale: Vector2 = Vector2(1, 1) 

# ==============================================================================
# 3. REFERENSI NODE
# ==============================================================================
# Visual & Physics
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D 
@onready var laser_beam: Area2D = $LaserBeam
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

# UI
@onready var coin_label: Label = $CanvasLayer/CoinContainer/CoinLabel
@onready var life_label: Label = $CanvasLayer/LifeContainer/LifeLabel
@onready var game_manager = %GameManager
@onready var game_over: Label = $CanvasLayer/GameOver

# Audio (SFX)
@onready var jump_sfx: AudioStreamPlayer2D = $Jump
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var ice_shoot_sfx: AudioStreamPlayer2D = $IceShootSfx
@onready var laser_sfx: AudioStreamPlayer2D = $LaserSfx
@onready var attack_sfx: AudioStreamPlayer2D = $AttackSfx
@onready var walk_sfx: AudioStreamPlayer2D = $WalKSfx 
@onready var game_over_sfx: AudioStreamPlayer2D = $GameOverSfx

# ==============================================================================
# 4. FUNGSI UTAMA (INIT & PHYSICS)
# ==============================================================================

func _ready():
	if game_over:
		game_over.visible = false
	
	if laser_beam:
		laser_beam.is_from_player = true
		laser_beam.visible = false 
		
		# Rekam posisi asli laser untuk keperluan flip
		default_laser_x = laser_beam.position.x
		initial_laser_scale = laser_beam.scale

func _physics_process(delta: float) -> void:
	# A. UPDATE UI SETIAP FRAME
	update_ui()
	
	# B. PRIORITY 1: CUTSCENE MODE
	if is_cutscene:
		_handle_cutscene_physics(delta)
		return # Stop input player
	
	# C. PRIORITY 2: CASTING SKILLS (Diam saat nembak)
	if is_casting_ice or is_casting_laser:
		velocity.x = 0
		if not is_on_floor(): velocity += get_gravity() * delta
		move_and_slide()
		
		# Pastikan suara jalan mati saat nembak diam
		if walk_sfx and walk_sfx.playing: walk_sfx.stop()
		return 

	# D. GRAVITASI
	if not is_on_floor():
		velocity += get_gravity() * delta

	# E. INPUT ACTIONS (Serang / Skill)
	_handle_input_actions()

	# F. MOVEMENT & JUMP
	_handle_movement_and_jump()

	# G. ANIMASI & AUDIO JALAN
	_update_animation_and_audio()

	move_and_slide()

# ==============================================================================
# 5. LOGIKA MOVEMENT & AUDIO (HANDLERS)
# ==============================================================================

func _handle_cutscene_physics(delta):
	velocity.x = 0
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		animated_sprite.play("idle")
	
	# Stop suara jalan saat cutscene
	if walk_sfx and walk_sfx.playing: walk_sfx.stop()
	
	move_and_slide()

func _handle_input_actions():
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	if Input.is_action_just_pressed("shoot"):
		fire_laser()

	if Input.is_action_pressed("shoot_ice") and can_fire_ice:
		fire_ice()

func _handle_movement_and_jump():
	# 1. Handle Jump Buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()

	var can_jump: bool = jump_buffer_timer.is_stopped() == false and is_on_floor()
	if can_jump:
		velocity.y = JUMP_VELOCITY
		jump_sfx.play()
		jump_buffer_timer.stop()

	# 2. Handle Horizontal Move
	var direction := Input.get_axis("move left", "move right")
	
	# Flip Sprite Logic
	if direction > 0:
		animated_sprite.flip_h = false
		_update_laser_position(1)
	elif direction < 0:
		animated_sprite.flip_h = true
		_update_laser_position(-1)
	else:
		_update_laser_position(0) # Keep Y scale

	# Apply Velocity
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func _update_animation_and_audio():
	if is_attacking: return # Jangan ganggu animasi attack

	# 1. Animasi
	if is_on_floor():
		if velocity.x == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("walk")
	else:
		animated_sprite.play("jump")
	
	# 2. Audio Jalan (Walk SFX) - [BAGIAN BARU]
	if is_on_floor() and velocity.x != 0:
		if walk_sfx and not walk_sfx.playing:
			walk_sfx.play()
	else:
		# Stop jika diam atau di udara
		if walk_sfx and walk_sfx.playing:
			walk_sfx.stop()

func _update_laser_position(dir: int):
	if not laser_beam: return
	
	if dir == 1: # Kanan
		laser_beam.position.x = abs(default_laser_x)
		laser_beam.scale.x = abs(initial_laser_scale.x)
	elif dir == -1: # Kiri
		laser_beam.position.x = -abs(default_laser_x)
		laser_beam.scale.x = -abs(initial_laser_scale.x)
	
	# Selalu reset skala Y
	laser_beam.scale.y = abs(initial_laser_scale.y)

# ==============================================================================
# 6. ACTION FUNCTIONS (ATTACK & SKILLS)
# ==============================================================================

func attack():
	is_attacking = true
	animated_sprite.play("attack")
	if attack_sfx: attack_sfx.play()
	hitbox_collision.set_deferred("disabled", false)

func fire_laser():
	if not Global.has_laser_ability: return
	if is_casting_laser: return 
	if not is_on_floor(): return 
	
	_cancel_melee_attack()

	is_casting_laser = true
	velocity.x = 0 
	
	if laser_sfx: laser_sfx.play(1.0)
	
	if laser_beam:
		laser_beam.fire()
		await laser_beam.get_node("AnimatedSprite2D").animation_finished
		await get_tree().create_timer(0.5).timeout
		
	is_casting_laser = false

func fire_ice():
	if not Global.has_ice_ability: return
	if is_casting_ice: return
	
	can_fire_ice = false
	_cancel_melee_attack()
	
	is_casting_ice = true
	velocity = Vector2.ZERO 
	
	# Play SFX Instan saat freeze
	if ice_shoot_sfx: ice_shoot_sfx.play(1.0)
	
	animated_sprite.play("attack")
	
	# Spawn Ice
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
	
	# Tunggu animasi
	var ice_sprite = ice.get_node("AnimatedSprite2D")
	if ice_sprite:
		await ice_sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	is_casting_ice = false
	
	await get_tree().create_timer(ice_cooldown_time).timeout
	can_fire_ice = true

func _cancel_melee_attack():
	if is_attacking:
		is_attacking = false
		hitbox_collision.set_deferred("disabled", true)

# ==============================================================================
# 7. EVENT & DAMAGE HANDLERS
# ==============================================================================

func set_cutscene_mode(active: bool):
	is_cutscene = active
	if active:
		velocity.x = 0
		is_attacking = false
		is_casting_ice = false
		is_casting_laser = false
		hitbox_collision.set_deferred("disabled", true)
		if walk_sfx: walk_sfx.stop()

func update_ui():
	if life_label:
		life_label.text = "x " + str(Global.lives - 1)
	if coin_label and game_manager:
		coin_label.text = "x " + str(game_manager.score) + " / " + str(game_manager.total_coins)

func die():
	if is_dead: return
	is_dead = true
	
	player_died.emit()
	set_physics_process(false)
	death_sound.play()
	animated_sprite.play("dies")
	$CollisionShape2D.set_deferred("disabled", true)
	if walk_sfx: walk_sfx.stop()
	Engine.time_scale = 0.5

func _on_animated_sprite_animation_finished():
	if animated_sprite.animation == "dies":
		var sisa_nyawa = Global.decrease_life()
		if sisa_nyawa > 0:
			Engine.time_scale = 1.0
			get_tree().reload_current_scene()
		else:
			trigger_game_over_sequence()
			
	elif animated_sprite.animation == "attack":
		is_attacking = false
		hitbox_collision.set_deferred("disabled", true)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(1)

func _on_boss_trigger_body_entered(_body: Node2D) -> void:
	pass

func trigger_game_over_sequence():
	if not game_over:
		Global.reset_lives()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
		
	game_over.visible = true
	
	if game_over_sfx:
		game_over_sfx.play()
	
	var center_pos = get_viewport_rect().size / 2
	game_over.position = Vector2(center_pos.x - (game_over.size.x / 2), -100)
	
	var tween = create_tween()
	tween.tween_property(game_over, "position:y", center_pos.y - (game_over.size.y / 2), 1.0)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	await tween.finished

	await get_tree().create_timer(0.7).timeout

	Engine.time_scale = 1.0
	Global.reset_lives()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
