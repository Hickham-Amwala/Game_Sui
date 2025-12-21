extends CharacterBody2D

# --- REFERENSI NODE ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var laser_beam: Area2D = $LaserBeam 
@onready var game_manager = %GameManager
@onready var health_bar: ProgressBar = $ProgressBar

# --- [BARU] REFERENSI ITEM DROP ---
# Pastikan path ini benar (sesuai tempat kamu simpan scene AbilityPickup)
const DROP_ITEM_SCENE = preload("res://scenes/ability_pickup.tscn")

# --- STATE MACHINE ---
enum {
	IDLE,
	CHASE,
	ATTACK_SHOOT,
	HURT,
	DEAD
}

var current_state = IDLE

# --- VARIABEL STATUS ---
var hp = 1 
var speed = 60
var attack_range = 250 
var player_ref = null
var can_attack = true

# --- VARIABEL ANTI-CAMPING ---
var is_player_inside_body = false
var body_damage_timer = 0.0
var max_safe_time = 0.8 # Detik sebelum player didorong keluar


func _ready():
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	animated_sprite.play("idle")
	
	if health_bar:
		# Set nilai maksimal bar sama dengan HP awal bos
		health_bar.max_value = hp
		# Set nilai bar saat ini ke HP penuh
		health_bar.value = hp
	
	# Pastikan laser mati di awal
	if laser_beam:
		if laser_beam.has_method("stop_firing"):
			laser_beam.stop_firing()
		else:
			laser_beam.visible = false
			laser_beam.monitoring = false


func _physics_process(delta):
	# 1. Gravitasi (Hanya jika belum mati)
	if current_state != DEAD and not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Logika Anti-Camping (Zona Panas)
	if is_player_inside_body and current_state != DEAD:
		body_damage_timer += delta
		if body_damage_timer > max_safe_time:
			print("JANGAN DIAM DI BAWAH BOS!")
			force_push_player()
			body_damage_timer = 0.0 # Reset timer

	# 3. State Machine
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


# --- LOGIKA TIAP STATE ---

func _process_idle():
	velocity.x = 0
	animated_sprite.play("idle")


func _process_chase():
	if player_ref != null:
		# A. Balik Badan & Laser
		var direction = (player_ref.global_position - global_position).normalized()
		
		if direction.x > 0:
			animated_sprite.flip_h = false 
			# Laser & BodyHitbox ikut berbalik (jika perlu offset)
			laser_beam.position.x = abs(laser_beam.position.x)
			laser_beam.scale.x = 1
		else:
			animated_sprite.flip_h = true  
			laser_beam.position.x = -abs(laser_beam.position.x)
			laser_beam.scale.x = -1
			
		# B. Cek Jarak Tembak
		var distance = global_position.distance_to(player_ref.global_position)
		if distance < attack_range and can_attack:
			current_state = ATTACK_SHOOT
			return 
		
		# C. Kejar
		velocity.x = direction.x * speed
		animated_sprite.play("run")

	else:
		current_state = IDLE


func _process_attack_shoot():
	velocity.x = 0 
	
	if animated_sprite.animation != "shoot":
		animated_sprite.play("shoot")
	
	# Nyalakan laser di frame 4
	if animated_sprite.frame >= 4:
		if laser_beam.has_method("fire"):
			laser_beam.fire()
	else:
		if laser_beam.has_method("stop_firing"):
			laser_beam.stop_firing()


# --- HELPER: DORONG PLAYER KELUAR (VERSI AGRESIF) ---
func force_push_player():
	if player_ref != null:
		var diff_x = player_ref.global_position.x - global_position.x
		var push_dir_x = 0
		
		if abs(diff_x) < 10.0:
			var random_side = [-1, 1].pick_random()
			push_dir_x = random_side
		else:
			push_dir_x = sign(diff_x)

		var push_vector = Vector2(push_dir_x, -0.5).normalized()
		player_ref.velocity = push_vector * 800
		
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(1)


# --- SINYAL ANIMASI SELESAI ---
func _on_animation_finished():
	if current_state == DEAD:
		if animated_sprite.animation == "die":
			animated_sprite.stop()
			animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("die") - 1
		return

	var anim_name = animated_sprite.animation
	
	if anim_name == "shoot":
		if laser_beam.has_method("stop_firing"):
			laser_beam.stop_firing()
			
		# Cooldown
		can_attack = false
		current_state = IDLE
		animated_sprite.play("idle")
		
		await get_tree().create_timer(2.0).timeout 
		
		if current_state == DEAD: return
		
		can_attack = true
		if player_ref != null:
			current_state = CHASE
		else:
			current_state = IDLE


# --- DAMAGE & MATI ---
func take_damage(amount):
	if current_state == DEAD: return
	
	hp -= amount
	
	if health_bar:
		var bar_tween = create_tween()
		bar_tween.tween_property(health_bar, "value", hp, 0.2).set_trans(Tween.TRANS_SINE)
		
	# Efek Berkedip Merah (Hit Flash)
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0:
		die()
		return

	# [SUPER ARMOR] Jangan stun jika sedang menembak
	if current_state == ATTACK_SHOOT:
		return 


func die():
	if current_state == DEAD: return
	
	print("Boss Kalah!")
	current_state = DEAD
	
	if game_manager:
		game_manager.boss_defeated()
	
	if health_bar:
		health_bar.hide()
		
	if laser_beam.has_method("stop_firing"):
		laser_beam.stop_firing()
	
	# Matikan fisika total
	set_physics_process(false)
	body_collision.set_deferred("disabled", true)
	$BodyHitbox.set_deferred("monitoring", false)
	
	# 1. JALANKAN VISUAL MATI DULUAN (Supaya tidak kaku)
	animated_sprite.play("die")
	
	# Animasi Melayang (Durasi 1 detik)
	var tween = create_tween()
	tween.tween_property(self, "position", position - Vector2(0, 18), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 2. TUNGGU 1 DETIK (Selama animasi melayang berjalan)
	await get_tree().create_timer(1.0).timeout
	
	# 3. BARU MUNCULKAN ITEM
	spawn_drop()


# --- [BARU] FUNGSI SPAWN ITEM ---
func spawn_drop():
	# Cek apakah scene item sudah ada
	if DROP_ITEM_SCENE:
		var item = DROP_ITEM_SCENE.instantiate()
		item.global_position = global_position
		
		# Masukkan ke scene utama (Root)
		get_tree().root.add_child(item)
		print("Item Ability Dropped!")
	else:
		print("ERROR: Scene Item Drop belum di-preload!")


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
