extends CharacterBody2D

# ==============================================================================
# 1. KONFIGURASI & VARIABEL
# ==============================================================================

# --- REFERENSI NODE (VISUAL & UI) ---
@onready var sprite = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@onready var status_label: Label = $StatusLabel
@onready var game_manager : Node = get_node_or_null("%GameManager") # Opsional: cari node jika belum di-assign

# --- REFERENSI NODE (PHYSICS & LOGIC) ---
@onready var stun_timer = $StunTimer
@onready var attack_range = $AttackRange 
@onready var body_hitbox = $Hitbox

# --- REFERENSI AUDIO ---
@onready var roar_sfx: AudioStreamPlayer = $RoarSfx
@onready var burn_sfx: AudioStreamPlayer = $BurnSfx
@onready var attack_sfx: AudioStreamPlayer = $AttackSfx
@onready var walk_sfx: AudioStreamPlayer = $WalkSfx
@onready var hit_sfx: AudioStreamPlayer = $HitSfx

# --- SETTING STATS BOSS ---
@export var speed = 60.0
@export var hp = 40           # Total HP
@export var hp_phase_2 = 20   # Titik darah fase 2
@export var damage_body = 1    
@export var damage_attack = 2  

# --- STATE VARIABLES ---
var is_active = false        
var is_stunned = false       
var is_attacking = false     
var is_dying = false        
var has_entered_phase_2 = false 

# --- CUTSCENE & MOVEMENT VARS ---
var target_cutscene_pos : Vector2 = Vector2.ZERO
var is_in_cutscene = false

# --- SCREEN SHAKE VARS ---
var step_timer : float = 0.0
var step_interval : float = 1.0 # Getar setiap 1 detik

# ==============================================================================
# 2. FUNGSI UTAMA (INIT & PHYSICS)
# ==============================================================================

func _ready():
	stun_timer.one_shot = true
	
	# Setup UI
	if health_bar:
		health_bar.max_value = hp 
		health_bar.value = hp     
		health_bar.visible = false
		
	if status_label:
		status_label.text = ""
		status_label.visible = false
	
	# Setup Signal Connections (Hanya jika belum terhubung)
	if attack_range and not attack_range.body_entered.is_connected(_on_attack_range_entered):
		attack_range.body_entered.connect(_on_attack_range_entered)
			
	if body_hitbox and not body_hitbox.body_entered.is_connected(_on_body_contact):
		body_hitbox.body_entered.connect(_on_body_contact)
	
	if not sprite.frame_changed.is_connected(_on_frame_changed):
		sprite.frame_changed.connect(_on_frame_changed)

func _physics_process(delta):
	# Jika mati, hentikan semua proses
	if is_dying: return

	# A. Logika Cutscene
	if is_in_cutscene:
		_handle_cutscene_movement(delta)
		return 

	# B. Logika Normal (Mengejar Player)
	if is_active and not is_stunned and not is_attacking:
		_handle_chase_movement(delta)
	
	# C. Logika Diam (Stun / Attack)
	elif is_attacking or is_stunned:
		_handle_stationary_state()

# ==============================================================================
# 3. LOGIKA PERGERAKAN (HANDLERS)
# ==============================================================================

func _handle_cutscene_movement(_delta):
	var direction = (target_cutscene_pos - global_position).normalized()
	velocity.x = direction.x * speed
	sprite.play("BossWalk")
	
	# Audio Jalan
	if walk_sfx and not walk_sfx.playing:
		walk_sfx.play()
	
	# Cek Sampai Tujuan
	if global_position.distance_to(target_cutscene_pos) < 5:
		velocity.x = 0
		sprite.play("Iddle")
		_stop_walk_sound()
		
	move_and_slide()

func _handle_chase_movement(delta):
	velocity.x = speed 
	sprite.play("BossWalk")
	
	# --- Logic Screen Shake & Footstep ---
	step_timer += delta
	if step_timer >= step_interval:
		trigger_footstep_effect()
		step_timer = 0.0
	# -------------------------------------
	
	# Audio Jalan
	if walk_sfx and not walk_sfx.playing:
		walk_sfx.play()
		
	move_and_slide()

func _handle_stationary_state():
	velocity.x = 0
	
	# Reset timer sedikit biar pas jalan lagi gak instan getar
	if step_timer > 0.5: step_timer = 0.5
		
	_stop_walk_sound()

# ==============================================================================
# 4. LOGIKA EVENT & FASE BOSS
# ==============================================================================

func activate_boss():
	if is_active: return

	if sprite.sprite_frames.has_animation("WakeUp"):
		sprite.play("WakeUp")
		if roar_sfx: roar_sfx.play()
		await sprite.animation_finished
	else:
		sprite.play("Hit") 
		await get_tree().create_timer(1.0).timeout

	is_active = true
	sprite.play("BossWalk")

func start_stun():
	if not is_stunned and not is_dying:
		is_stunned = true
		is_attacking = false 
		_stop_walk_sound()
		
		# Tampilkan Status Label
		if status_label:
			status_label.visible = true
			if not has_entered_phase_2:
				status_label.text = "THE BOSS GOT STUNNED BY METEOR!\nATTACK NOW!"
				status_label.modulate = Color(0, 1, 0) # Hijau
			else:
				status_label.text = "THIS IS THE LAST HOPE..."
				status_label.modulate = Color(0.9, 0.4, 0.1) # Oranye
		
		if health_bar: health_bar.visible = true
		
		sprite.modulate = Color(0.5, 0.5, 0.5) 
		sprite.play("Iddle") 
		print("BOSS PINGSAN! Pukuli sekarang!")

func force_wake_up():
	if has_entered_phase_2: return
	has_entered_phase_2 = true
	
	_stop_walk_sound()
	
	# Update Label Phase 2
	if status_label:
		status_label.visible = true
		status_label.text = "THE BOSS WAKE UP AGAIN!\nRUNNN!!!"
		status_label.modulate = Color(1, 0, 0) # Merah
	
	if health_bar: health_bar.visible = false
	
	# Reset Status
	is_stunned = false
	is_in_cutscene = false 
	is_attacking = true 
	
	sprite.modulate = Color(1, 1, 1) 
	
	# Animasi Bangun & Roar
	if sprite.sprite_frames.has_animation("WakeUp"):
		sprite.play("WakeUp")
		if roar_sfx: roar_sfx.play()
		await sprite.animation_finished 
	else:
		sprite.play("Hit") 
		await get_tree().create_timer(1.0).timeout
	
	is_attacking = false
	print("Boss Kembali Mengejar!")
	cek_area_badan()

func walk_to_position(pos):
	is_in_cutscene = true
	target_cutscene_pos = pos

# ==============================================================================
# 5. LOGIKA SERANGAN BOSS
# ==============================================================================

func _on_attack_range_entered(body):
	if body.name == "Player" and not is_attacking and not is_stunned and is_active and not is_in_cutscene and not is_dying:
		start_attack()

func start_attack():
	is_attacking = true
	sprite.play("Attack")
	
	# Delay Audio agar pas dengan animasi pukulan
	await get_tree().create_timer(0.6).timeout
	if attack_sfx: attack_sfx.play()

func _on_frame_changed():
	if sprite.animation == "Attack":
		if sprite.frame == 9: # Frame saat damage dealt
			deal_attack_damage()
		if sprite.frame == sprite.sprite_frames.get_frame_count("Attack") - 1:
			finish_attack()

func deal_attack_damage():
	var targets = attack_range.get_overlapping_bodies()
	for target in targets:
		if target.name == "Player":
			if target.has_method("die"): target.die()
			elif target.has_method("take_damage"): target.take_damage(damage_attack)

func finish_attack():
	is_attacking = false
	sprite.play("BossWalk")

# ==============================================================================
# 6. LOGIKA DAMAGE & KEMATIAN
# ==============================================================================

func take_damage(amount):
	if is_dying: return
		
	# Boss hanya bisa dilukai saat STUN
	if is_stunned:
		hp -= amount
		
		# Audio Hit
		if hit_sfx:
			hit_sfx.pitch_scale = randf_range(0.8, 1.2) 
			hit_sfx.play()
		
		# Update UI
		if health_bar: health_bar.value = hp
		
		print("Boss HP: ", hp)
		
		# A. Cek Mati
		if hp <= 0:
			die()
			return 
		
		# B. Cek Phase 2
		if hp <= hp_phase_2 and hp > 0 and not has_entered_phase_2:
			force_wake_up()
			return 
			
		# C. Animasi Hit Biasa
		sprite.play("Hit") 
		sprite.modulate = Color(1, 0, 0)
		
		await get_tree().create_timer(0.4).timeout
		
		# Kembali ke posisi pingsan jika belum mati/bangun
		if is_stunned and not is_dying and not has_entered_phase_2:
			sprite.modulate = Color(0.5, 0.5, 0.5)
			sprite.play("Iddle")

func die():
	is_dying = true 
	_stop_walk_sound()
	
	if burn_sfx: burn_sfx.play()
	
	# Hide UI & Disable Physics
	if health_bar: health_bar.visible = false
	if status_label: status_label.visible = false
	
	set_physics_process(false)
	if body_hitbox: body_hitbox.set_deferred("monitoring", false)
	if attack_range: attack_range.set_deferred("monitoring", false)
	
	# Animasi Mati
	sprite.modulate = Color(1, 1, 1) 
	sprite.play("Death")
	
	if game_manager:
		game_manager.boss_defeated()
		
	await sprite.animation_finished
	queue_free()

# ==============================================================================
# 7. HELPER FUNCTIONS
# ==============================================================================

func _stop_walk_sound():
	if walk_sfx and walk_sfx.playing:
		walk_sfx.stop()

func trigger_footstep_effect():
	# Cari kamera dan jalankan shake
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("apply_shake"):
		cam.apply_shake(3.0) 

# --- LOGIKA TABRAK BADAN (Touch Damage) ---
func _on_body_contact(body):
	if is_stunned or is_dying: return 

	if body.name == "Player":
		if body.has_method("die"): body.die()
		elif body.has_method("take_damage"): body.take_damage(damage_body)

func cek_area_badan():
	if body_hitbox:
		var targets = body_hitbox.get_overlapping_bodies()
		for t in targets:
			if t.name == "Player":
				if t.has_method("die"): t.die()
				elif t.has_method("take_damage"): t.take_damage(damage_body)
