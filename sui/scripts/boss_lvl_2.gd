extends CharacterBody2D

# ==============================================================================
# 1. KONFIGURASI & VARIABEL
# ==============================================================================

# --- REFERENSI NODE (UI & COMPONENT) ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox 
@onready var body_hitbox: Area2D = $BodyHitbox 
@onready var health_bar: ProgressBar = $ProgressBar
@onready var game_manager = %GameManager 

# --- REFERENSI AUDIO ---
@onready var walk_sfx: AudioStreamPlayer2D = $WalkSfx
@onready var attack_sfx: AudioStreamPlayer2D = $AttackSfx
@onready var die_sfx: AudioStreamPlayer2D = $DieSfx

# --- PRELOAD SCENES ---
const DROP_ITEM_SCENE = preload("res://scenes/ability_pickup2.tscn")

# --- SETTING STATS BOSS ---
var hp = 35
var speed = 50
var attack_range = 60 
var damage = 1

# --- LOGIKA ANTI-CAMPING ---
var is_player_inside_body = false
var body_damage_timer = 0.0
var max_safe_time = 0.8 

# --- STATE MACHINE ---
enum {IDLE, CHASE, ATTACK, HURT, DEAD}
var current_state = IDLE
var player_ref = null
var is_cooldown = false 

# ==============================================================================
# 2. FUNGSI UTAMA (INIT & PHYSICS)
# ==============================================================================

func _ready():
	add_to_group("enemy") 
	
	# Setup Hitbox
	hitbox.monitoring = false
	
	# Setup Health Bar
	if health_bar:
		health_bar.max_value = hp
		health_bar.value = hp
	
	# Connect Signal Animasi secara aman
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# A. Gravitasi
	if not is_on_floor():
		velocity += get_gravity() * delta

	# B. Logika Anti-Camping (Player diam di dalam badan boss)
	_handle_anti_camping(delta)

	# C. State Machine (Logika Perilaku)
	match current_state:
		IDLE:
			_process_idle()
		CHASE:
			_process_chase()
		ATTACK:
			_process_attack()
		DEAD:
			velocity.x = 0
			_stop_walk_sound()

	move_and_slide()

# ==============================================================================
# 3. LOGIKA STATE (PERILAKU)
# ==============================================================================

func _process_idle():
	velocity.x = 0
	animated_sprite.play("idle")
	_stop_walk_sound()

func _process_chase():
	if player_ref:
		# 1. Tentukan Arah & Flip Sprite
		var direction = (player_ref.global_position - global_position).normalized()
		_flip_sprite(direction.x)
		
		# 2. Gerakan
		velocity.x = direction.x * speed
		animated_sprite.play("walk")
		
		# 3. Suara Jalan
		if walk_sfx and not walk_sfx.playing:
			walk_sfx.play()
		
		# 4. Cek Jarak Serang
		var dist = global_position.distance_to(player_ref.global_position)
		if dist < attack_range and not is_cooldown:
			current_state = ATTACK
	else:
		current_state = IDLE

func _process_attack():
	velocity.x = 0 
	_stop_walk_sound()
	
	# Mainkan animasi & suara HANYA SEKALI di awal state
	if animated_sprite.animation != "attack":
		animated_sprite.play("attack")
		if attack_sfx:
			attack_sfx.play() # [PERBAIKAN] Suara attack dipindah kesini agar tidak looping
		
	# Hitbox aktif di frame tertentu (frame 3 sampai 4)
	if animated_sprite.frame >= 3 and animated_sprite.frame <= 4:
		hitbox.monitoring = true
	else:
		hitbox.monitoring = false

# ==============================================================================
# 4. HELPER FUNCTIONS (FUNGSI BANTUAN)
# ==============================================================================

func _flip_sprite(dir_x):
	if dir_x > 0:
		animated_sprite.flip_h = true
		hitbox.scale.x = -1 
	else:
		animated_sprite.flip_h = false
		hitbox.scale.x = 1 

func _stop_walk_sound():
	if walk_sfx and walk_sfx.playing:
		walk_sfx.stop()

func _handle_anti_camping(delta):
	if is_player_inside_body and current_state != DEAD:
		body_damage_timer += delta
		if body_damage_timer > max_safe_time:
			print("JANGAN DIAM DI DALAM BOSS!")
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
	if health_bar: health_bar.value = hp
	
	# Efek Flash Merah
	modulate = Color.RED
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# Jika tidak sedang menyerang, mainkan animasi hurt
	if current_state != ATTACK:
		animated_sprite.play("damage")
		current_state = HURT
	
	if hp <= 0:
		die()

func die():
	if current_state == DEAD: return
	current_state = DEAD
	
	print("Boss Melee Kalah!")
	
	# Audio & Cleanup
	if die_sfx: die_sfx.play()
	_stop_walk_sound()
	
	# Matikan Fisika & Hitbox
	$CollisionShape2D.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	if has_node("BodyHitbox"):
		$BodyHitbox.set_deferred("monitoring", false)
	
	if health_bar: health_bar.hide()
	set_physics_process(false)
	
	# Animasi Mati
	animated_sprite.play("death") 
	
	# Spawn Item & Lapor Manager
	await get_tree().create_timer(2.5).timeout
	spawn_drop()
	
	if game_manager:
		game_manager.boss_defeated()

func spawn_drop():
	if DROP_ITEM_SCENE:
		var item = DROP_ITEM_SCENE.instantiate()
		item.global_position = global_position
		get_tree().root.add_child(item)
		print("Power Up Dropped!")

# ==============================================================================
# 6. SIGNALS (EVENT HANDLER)
# ==============================================================================

func _on_animation_finished():
	if animated_sprite.animation == "attack":
		hitbox.set_deferred("monitoring", false)
		current_state = IDLE
		is_cooldown = true 
		animated_sprite.play("idle")
		
		# Timer Cooldown
		await get_tree().create_timer(1.0).timeout 
		is_cooldown = false
		
		# Kembali mengejar jika player masih ada
		if player_ref and current_state != DEAD: 
			current_state = CHASE
		
	elif animated_sprite.animation == "damage":
		current_state = IDLE
		if player_ref: current_state = CHASE

# --- SENSOR DETEKSI PLAYER ---
func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		if current_state != DEAD: current_state = CHASE

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_ref = null
		if current_state != DEAD: current_state = IDLE

# --- SENSOR HITBOX SERANGAN ---
func _on_hitbox_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		elif body.has_method("die"): 
			body.die()

# --- SENSOR ANTI-CAMPING ---
func _on_body_hitbox_body_entered(body):
	if body.is_in_group("player"):
		is_player_inside_body = true
		body_damage_timer = 0.0

func _on_body_hitbox_body_exited(body):
	if body.is_in_group("player"):
		is_player_inside_body = false
		body_damage_timer = 0.0
