extends CharacterBody2D

# --- REFERENSI NODE ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D

# [BARU] Referensi langsung ke node LaserBeam yang jadi anak Bos
@onready var laser_beam: Area2D = $LaserBeam 

# --- STATE MACHINE ---
enum {
	IDLE,
	CHASE,
	ATTACK_SHOOT, # Ganti nama biar jelas (dulu ATTACK_SMASH)
	HURT,
	DEAD
}

var current_state = IDLE

# --- VARIABEL STATUS ---
var hp = 50
var speed = 40
var attack_range = 250 # Jarak tembak Godzilla (Agak jauh)
var player_ref = null
var can_attack = true


func _ready():
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	animated_sprite.play("idle")
	
	# Pastikan laser mati di awal
	if laser_beam:
		laser_beam.visible = false
		laser_beam.monitoring = false


func _physics_process(delta):
	if current_state != DEAD and not is_on_floor():
		velocity += get_gravity() * delta

	match current_state:
		IDLE:
			_process_idle()
		CHASE:
			_process_chase()
		ATTACK_SHOOT:
			_process_attack_shoot() # Logika Godzilla Beam
		HURT:
			_process_hurt()
		DEAD:
			pass

	move_and_slide()


# --- LOGIKA TIAP STATE ---

func _process_idle():
	velocity.x = 0
	animated_sprite.play("idle")


func _process_chase():
	if player_ref != null:
		# 1. Balik Badan & Laser
		var direction = (player_ref.global_position - global_position).normalized()
		
		if direction.x > 0:
			animated_sprite.flip_h = false 
			# [BARU] Laser ikut berbalik ke kanan
			laser_beam.position.x = abs(laser_beam.position.x)
			laser_beam.scale.x = 1
		else:
			animated_sprite.flip_h = true  
			# [BARU] Laser ikut berbalik ke kiri
			laser_beam.position.x = -abs(laser_beam.position.x)
			laser_beam.scale.x = -1
			
		# 2. Cek Jarak Tembak
		var distance = global_position.distance_to(player_ref.global_position)
		if distance < attack_range and can_attack:
			current_state = ATTACK_SHOOT
			return 
		
		# 3. Bergerak
		velocity.x = direction.x * speed
		animated_sprite.play("run")

	else:
		current_state = IDLE


func _process_attack_shoot():
	velocity.x = 0 # Bos diam saat nembak laser (Godzilla style)
	
	# [PERBAIKAN] Ganti nama animasi jadi "shoot"
	if animated_sprite.animation != "shoot":
		animated_sprite.play("shoot")
	
	# --- LOGIKA NYALAKAN LASER ---
	# Cek frame berapa mulut/mata golem terbuka. Misal frame 4.
	
	if animated_sprite.frame >= 4:
		# Nyalakan Laser!
		if laser_beam.has_method("fire"):
			laser_beam.fire()
	else:
		# Jika animasi belum sampai frame 4 (masih persiapan), laser mati
		if laser_beam.has_method("stop_firing"):
			laser_beam.stop_firing()


func _process_hurt():
	velocity.x = 0
	# Matikan laser jika kena pukul saat sedang nembak
	if laser_beam.has_method("stop_firing"):
		laser_beam.stop_firing()
		
	if animated_sprite.animation != "hurt":
		animated_sprite.play("hurt")


# --- SINYAL ANIMASI SELESAI ---
func _on_animation_finished():
	if current_state == DEAD:
		if animated_sprite.animation == "die":
			animated_sprite.stop()
		return

	var anim_name = animated_sprite.animation
	
	# [PERBAIKAN] Cek animasi "shoot"
	if anim_name == "shoot":
		# Matikan laser
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
			
	elif anim_name == "hurt":
		if player_ref != null:
			current_state = CHASE
		else:
			current_state = IDLE


# --- DAMAGE & MATI (SAMA SEPERTI SEBELUMNYA) ---
func take_damage(amount):
	if current_state == DEAD: return
	hp -= amount
	print("Bos HP: ", hp)
	
	if hp <= 0:
		die()
	else:
		current_state = HURT
		modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if current_state != DEAD:
			modulate = Color.WHITE

func die():
	if current_state == DEAD: return
	
	print("Bos Kalah!")
	current_state = DEAD
	
	# Matikan laser saat mati
	if laser_beam.has_method("stop_firing"):
		laser_beam.stop_firing()
	
	set_physics_process(false)
	body_collision.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.tween_property(self, "position", position - Vector2(0, 20), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	animated_sprite.play("die")


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
