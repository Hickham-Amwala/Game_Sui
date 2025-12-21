extends CharacterBody2D

# --- KONFIGURASI ---
@export var speed = 60.0
@export var hp = 20          # Total HP
@export var hp_phase_2 = 10  # Titik darah dimana Boss akan bangun (Setengah)
@export var damage_body = 1    
@export var damage_attack = 2  
@export var game_manager : Node 

# --- VARIABEL STATUS ---
var is_active = false       
var is_stunned = false      
var is_attacking = false    
var is_dying = false        # [BARU] Status sedang proses mati

# --- VARIABEL CUTSCENE ---
var target_cutscene_pos : Vector2 = Vector2.ZERO
var is_in_cutscene = false
var has_entered_phase_2 = false 

# --- REFERENSI NODE ---
@onready var sprite = $AnimatedSprite2D
@onready var stun_timer = $StunTimer
@onready var attack_range = $AttackRange 
@onready var body_hitbox = $BodyHitbox

func _ready():
	stun_timer.one_shot = true
	
	if attack_range:
		attack_range.body_entered.connect(_on_attack_range_entered)
	if body_hitbox:
		body_hitbox.body_entered.connect(_on_body_contact)
	
	sprite.frame_changed.connect(_on_frame_changed)

func _physics_process(delta):
	# Jika sedang mati, jangan lakukan apa-apa
	if is_dying:
		return

	# LOGIKA CUTSCENE
	if is_in_cutscene:
		var direction = (target_cutscene_pos - global_position).normalized()
		velocity.x = direction.x * speed
		sprite.play("BossWalk")
		
		if global_position.distance_to(target_cutscene_pos) < 5:
			velocity.x = 0
			sprite.play("Iddle")
			
		move_and_slide()
		return 

	# LOGIKA NORMAL
	if is_active and not is_stunned and not is_attacking:
		velocity.x = speed 
		sprite.play("BossWalk")
		move_and_slide()
	
	elif is_attacking or is_stunned:
		velocity.x = 0

# --- LOGIKA EVENT & PHASE 2 ---
func walk_to_position(pos):
	is_in_cutscene = true
	target_cutscene_pos = pos

func force_wake_up():
	if has_entered_phase_2:
		return
		
	has_entered_phase_2 = true
	print("DARAH SETENGAH! BOSS BANGUN (PHASE 2)!")
	
	is_stunned = false
	is_in_cutscene = false 
	is_attacking = true  # Paksa status attacking agar diam saat teriak
	
	sprite.modulate = Color(1, 1, 1) 
	
	if sprite.sprite_frames.has_animation("WakeUp"):
		sprite.play("WakeUp")
		await sprite.animation_finished 
	else:
		sprite.play("Hit") 
		await get_tree().create_timer(1.0).timeout
	
	is_attacking = false
	print("Boss Kembali Mengejar!")
	cek_area_badan()

# --- LOGIKA SERANGAN BOSS ---
func _on_attack_range_entered(body):
	if body.name == "Player" and not is_attacking and not is_stunned and is_active and not is_in_cutscene and not is_dying:
		start_attack()

func start_attack():
	is_attacking = true
	sprite.play("Attack")

func _on_frame_changed():
	if sprite.animation == "Attack":
		if sprite.frame == 9:
			deal_attack_damage()
		if sprite.frame == sprite.sprite_frames.get_frame_count("Attack") - 1:
			finish_attack()

func deal_attack_damage():
	var targets = attack_range.get_overlapping_bodies()
	for target in targets:
		if target.name == "Player":
			if target.has_method("die"):
				target.die()
			elif target.has_method("take_damage"):
				target.take_damage(damage_attack)

func finish_attack():
	is_attacking = false
	sprite.play("BossWalk")

# --- LOGIKA TABRAK BADAN ---
func _on_body_contact(body):
	if is_stunned or is_dying: return # AMAN saat stun atau boss mati

	if body.name == "Player":
		if body.has_method("die"):
			body.die()
		elif body.has_method("take_damage"):
			body.take_damage(damage_body)

func cek_area_badan():
	if body_hitbox:
		var targets = body_hitbox.get_overlapping_bodies()
		for t in targets:
			if t.name == "Player":
				if t.has_method("die"):
					t.die()
				elif t.has_method("take_damage"):
					t.take_damage(damage_body)

# --- FUNGSI UTAMA ---
func activate_boss():
	if is_active: return

	if sprite.sprite_frames.has_animation("WakeUp"):
		sprite.play("WakeUp")
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
		
		sprite.modulate = Color(0.5, 0.5, 0.5) 
		sprite.play("Iddle") 
		print("BOSS PINGSAN! Pukuli sekarang!")

func _on_stun_finished():
	pass 

func take_damage(amount):
	# 1. Jika Boss sudah mati/sedang proses mati, abaikan hit baru
	if is_dying:
		return

	# Boss hanya bisa dilukai saat STUN
	if is_stunned:
		hp -= amount
		print("Boss HP: ", hp)
		
		# --- PRIORITAS 1: CEK KEMATIAN DULU ---
		if hp <= 0:
			die()
			return # Stop fungsi di sini, JANGAN mainkan animasi Hit
		
		# --- PRIORITAS 2: CEK PHASE 2 ---
		if hp <= hp_phase_2 and hp > 0 and not has_entered_phase_2:
			force_wake_up()
			return # Stop fungsi di sini
			
		# --- PRIORITAS 3: ANIMASI HIT BIASA ---
		# Kalau masih hidup dan belum phase 2, baru mainkan Hit
		sprite.play("Hit") 
		sprite.modulate = Color(1, 0, 0)
		
		await get_tree().create_timer(0.4).timeout
		
		# Kembalikan ke posisi pingsan jika masih stun dan belum mati
		if is_stunned and not is_dying and not has_entered_phase_2:
			sprite.modulate = Color(0.5, 0.5, 0.5)
			sprite.play("Iddle") 

func die():
	is_dying = true # Kunci status mati
	print("Boss Kalah!")
	
	# Matikan semua interaksi
	set_physics_process(false)
	if body_hitbox: body_hitbox.set_deferred("monitoring", false)
	if attack_range: attack_range.set_deferred("monitoring", false)
	
	sprite.modulate = Color(1, 1, 1) # Kembalikan warna normal
	sprite.play("Death")
	
	if game_manager:
		game_manager.boss_defeated()
		
	await sprite.animation_finished
	queue_free()
