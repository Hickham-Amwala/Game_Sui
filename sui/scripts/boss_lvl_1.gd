extends CharacterBody2D

# ==============================================================================
# 1. KONFIGURASI & VARIABEL
# ==============================================================================

# --- REFERENSI NODE (VISUAL & FISIK) ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var laser_beam: Area2D = $LaserBeam 
@onready var health_bar: ProgressBar = $ProgressBar
@onready var game_manager = %GameManager

# --- REFERENSI AUDIO ---
@onready var walk_sfx: AudioStreamPlayer2D = $WalkSfx
@onready var laser_sfx: AudioStreamPlayer2D = $LaserSfx
@onready var hit_sfx: AudioStreamPlayer2D = $HitSfx
@onready var die_sfx: AudioStreamPlayer2D = $DieSfx

# --- PRELOAD SCENES ---
const DROP_ITEM_SCENE = preload("res://scenes/ability_pickup.tscn")

# --- SETTING STATS BOSS ---
var hp = 20
var speed = 60
var attack_range = 250 
var can_attack = true

# --- LOGIKA ANTI-CAMPING ---
var is_player_inside_body = false
var body_damage_timer = 0.0
var max_safe_time = 0.8 

# --- STATE MACHINE ---
enum {IDLE, CHASE, ATTACK_SHOOT, HURT, DEAD}
var current_state = IDLE
var player_ref = null

# ==============================================================================
# 2. FUNGSI UTAMA (INIT & PHYSICS)
# ==============================================================================

func _ready():
	# Setup Animation Signal
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	animated_sprite.play("idle")
	
	# Setup Health Bar
	if health_bar:
		health_bar.max_value = hp
		health_bar.value = hp
	
	# Reset Laser
	if laser_beam:
		if laser_beam.has_method("stop_firing"):
			laser_beam.stop_firing()
		else:
			laser_beam.visible = false
			laser_beam.monitoring = false

func _physics_process(delta):
	# A. Gravitasi (Hanya jika belum mati)
	if current_state != DEAD and not is_on_floor():
		velocity += get_gravity() * delta

	# B. Logika Anti-Camping (Zona Panas di bawah boss)
	_handle_anti_camping(delta)

	# C. State Machine (Logika Perilaku)
	match current_state:
		IDLE:
			_process_idle()
		CHASE:
			_process_chase()
		ATTACK_SHOOT:
			_process_attack_shoot()
		DEAD:
			pass 

	move_and_slide()

# ==============================================================================
# 3. LOGIKA STATE (PERILAKU)
# ==============================================================================

func _process_idle():
	velocity.x = 0
	animated_sprite.play("idle")
	_stop_walk_sound()

func _process_chase():
	if player_ref != null:
		# 1. Tentukan Arah
		var direction = (player_ref.global_position - global_position).normalized()
		
		# 2. Flip Sprite & Laser Position
		_flip_boss_and_laser(direction.x)
			
		# 3. Cek Jarak Tembak
		var distance = global_position.distance_to(player_ref.global_position)
		if distance < attack_range and can_attack:
			_start_attack_sequence()
			return 
		
		# 4. Gerakan Mengejar
		velocity.x = direction.x * speed
		animated_sprite.play("run")
		
		# 5. Audio Jalan
		if walk_sfx and not walk_sfx.playing:
			walk_sfx.play()

	else:
		current_state = IDLE

func _process_attack_shoot():
	velocity.x = 0 
	_stop_walk_sound()

	if animated_sprite.animation != "shoot":
		animated_sprite.play("shoot")
	
	# Logika Laser (Nyalakan di frame 4 ke atas)
	if animated_sprite.frame >= 4:
		if laser_beam.has_method("fire"):
			laser_beam.fire()
	else:
		if laser_beam.has_method("stop_firing"):
			laser_beam.stop_firing()

# ==============================================================================
# 4. HELPER FUNCTIONS (FUNGSI BANTUAN)
# ==============================================================================

func _flip_boss_and_laser(dir_x):
	if dir_x > 0:
		animated_sprite.flip_h = false 
		laser_beam.position.x = abs(laser_beam.position.x)
		laser_beam.scale.x = 1
	else:
		animated_sprite.flip_h = true  
		laser_beam.position.x = -abs(laser_beam.position.x)
		laser_beam.scale.x = -1

func _start_attack_sequence():
	current_state = ATTACK_SHOOT
	_stop_walk_sound()
	
	# Delay sedikit sebelum suara laser (Charging effect)
	await get_tree().create_timer(0.3).timeout
	if laser_sfx:
		laser_sfx.play()

func _stop_walk_sound():
	if walk_sfx and walk_sfx.playing:
		walk_sfx.stop()

func _handle_anti_camping(delta):
	if is_player_inside_body and current_state != DEAD:
		body_damage_timer += delta
		if body_damage_timer > max_safe_time:
			print("JANGAN DIAM DI BAWAH BOS!")
			force_push_player()
			body_damage_timer = 0.0 

func force_push_player():
	if player_ref != null:
		var diff_x = player_ref.global_position.x - global_position.x
		var push_dir_x = sign(diff_x)
		if abs(diff_x) < 10.0: push_dir_x = [-1, 1].pick_random()

		var push_vector = Vector2(push_dir_x, -0.5).normalized()
		player_ref.velocity = push_vector * 800
		
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(1)

# ==============================================================================
# 5. LOGIKA DAMAGE & KEMATIAN
# ==============================================================================

func take_damage(amount):
	if current_state == DEAD: return
	
	hp -= amount
	
	# Audio Hit
	if hit_sfx:
		hit_sfx.pitch_scale = randf_range(0.8, 1.2) # Variasi suara hit
		hit_sfx.play()
	
	# Animasi HP Bar
	if health_bar:
		var bar_tween = create_tween()
		bar_tween.tween_property(health_bar, "value", hp, 0.2).set_trans(Tween.TRANS_SINE)
		
	# Efek Flash Merah
	modulate = Color.RED
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0:
		die()
		return

	# [SUPER ARMOR] Jangan stun jika sedang menembak
	if current_state == ATTACK_SHOOT:
		return 

func die():
	if current_state == DEAD: return
	current_state = DEAD
	
	print("Boss Kalah!")
	
	# Stop Audio & Fisika
	_stop_walk_sound()
	if die_sfx: die_sfx.play()
	if laser_beam.has_method("stop_firing"): laser_beam.stop_firing()
	
	set_physics_process(false)
	body_collision.set_deferred("disabled", true)
	$BodyHitbox.set_deferred("monitoring", false)
	
	# Hide UI
	if health_bar: health_bar.hide()
	
	# Animasi Mati & Melayang
	animated_sprite.play("die")
	var tween = create_tween()
	tween.tween_property(self, "position", position - Vector2(0, 18), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(1.0).timeout
	
	spawn_drop()
	
	if game_manager:
		game_manager.boss_defeated()

func spawn_drop():
	if DROP_ITEM_SCENE:
		var item = DROP_ITEM_SCENE.instantiate()
		item.global_position = global_position
		get_tree().root.add_child(item)
		print("Item Ability Dropped!")
	else:
		print("ERROR: Scene Item Drop belum di-preload!")

# ==============================================================================
# 6. SIGNALS (EVENT HANDLER)
# ==============================================================================

func _on_animation_finished():
	if current_state == DEAD:
		if animated_sprite.animation == "die":
			animated_sprite.stop()
			animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("die") - 1
		return

	var anim_name = animated_sprite.animation
	
	if anim_name == "shoot":
		# Matikan laser setelah animasi selesai
		if laser_beam.has_method("stop_firing"):
			laser_beam.stop_firing()
			
		# Cooldown Logic
		can_attack = false
		current_state = IDLE
		animated_sprite.play("idle")
		
		# Tunggu 2 detik sebelum bisa ngejar/nembak lagi
		await get_tree().create_timer(2.0).timeout 
		
		if current_state == DEAD: return
		
		can_attack = true
		if player_ref != null:
			current_state = CHASE
		else:
			current_state = IDLE

# --- SENSOR DETEKSI PLAYER ---
func _on_detection_area_body_entered(body):
	if current_state == DEAD: return
	if body.is_in_group("player"):
		player_ref = body
		if current_state == IDLE:
			current_state = CHASE

func _on_detection_area_body_exited(body):
	if current_state == DEAD: return
	if body.is_in_group("player"):
		player_ref = null

# --- SENSOR ANTI-CAMPING ---
func _on_body_hitbox_body_entered(body):
	if body.is_in_group("player"):
		is_player_inside_body = true
		body_damage_timer = 0.0

func _on_body_hitbox_body_exited(body):
	if body.is_in_group("player"):
		is_player_inside_body = false
		body_damage_timer = 0.0
