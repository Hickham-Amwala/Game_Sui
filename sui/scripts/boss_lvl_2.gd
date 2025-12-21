extends CharacterBody2D

# --- REFERENSI NODE ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox 
@onready var game_manager = %GameManager 
@onready var health_bar: ProgressBar = $ProgressBar
@onready var body_hitbox: Area2D = $BodyHitbox 

# --- [BARU] REFERENSI ITEM DROP ---
# Ganti path ini jika kamu punya item power up yang berbeda untuk stage 2
const DROP_ITEM_SCENE = preload("res://scenes/ability_pickup2.tscn")

# --- SETTING BOSS ---
var hp = 35
var speed = 50
var attack_range = 60 
var damage = 1

# --- VARIABEL ---
var is_cooldown = false 
var is_player_inside_body = false
var body_damage_timer = 0.0
var max_safe_time = 0.8 

enum {IDLE, CHASE, ATTACK, HURT, DEAD}
var current_state = IDLE
var player_ref = null

func _ready():
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	if health_bar:
		health_bar.max_value = hp
		health_bar.value = hp
	
	hitbox.monitoring = false
	add_to_group("enemy") 

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Anti-Camping Logic
	if is_player_inside_body and current_state != DEAD:
		body_damage_timer += delta
		if body_damage_timer > max_safe_time:
			print("JANGAN DIAM DI DALAM BOSS!")
			force_push_player()
			body_damage_timer = 0.0 

	match current_state:
		IDLE:
			velocity.x = 0
			animated_sprite.play("idle")
			
		CHASE:
			if player_ref:
				var direction = (player_ref.global_position - global_position).normalized()
				
				if direction.x > 0:
					animated_sprite.flip_h = true
					hitbox.scale.x = -1 
				else:
					animated_sprite.flip_h = false
					hitbox.scale.x = 1 
				
				velocity.x = direction.x * speed
				animated_sprite.play("walk")
				
				var dist = global_position.distance_to(player_ref.global_position)
				if dist < attack_range and not is_cooldown:
					current_state = ATTACK
			else:
				current_state = IDLE
				
		ATTACK:
			velocity.x = 0 
			if animated_sprite.animation != "attack":
				animated_sprite.play("attack")
			
			if animated_sprite.frame >= 3 and animated_sprite.frame <= 4:
				hitbox.monitoring = true
			else:
				hitbox.monitoring = false
				
		DEAD:
			velocity.x = 0

	move_and_slide()

# --- HELPER ---
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

# --- ANIMATION FINISHED ---
func _on_animation_finished():
	if animated_sprite.animation == "attack":
		hitbox.set_deferred("monitoring", false)
		current_state = IDLE
		is_cooldown = true 
		animated_sprite.play("idle")
		await get_tree().create_timer(1.0).timeout # Jeda serang
		is_cooldown = false
		if player_ref and current_state != DEAD: current_state = CHASE
		
	elif animated_sprite.animation == "damage":
		current_state = IDLE
		if player_ref: current_state = CHASE

# --- DAMAGE & MATI (YANG DIUBAH ADA DISINI) ---
func take_damage(amount):
	if current_state == DEAD: return
	
	hp -= amount
	if health_bar: health_bar.value = hp
	
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if current_state != ATTACK:
		animated_sprite.play("damage")
		current_state = HURT
	
	if hp <= 0:
		die()

func die():
	if current_state == DEAD: return
	current_state = DEAD
	print("Boss Melee Kalah!")
	
	# 1. Matikan semua interaksi fisik
	$CollisionShape2D.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	if has_node("BodyHitbox"):
		$BodyHitbox.set_deferred("monitoring", false)
	
	if health_bar: health_bar.hide()
	set_physics_process(false)
	
	# 2. Mainkan animasi mati
	animated_sprite.play("death") 
	
	# 3. [TUNDA 1 DETIK] Sebelum Drop Item
	await get_tree().create_timer(2.5).timeout
	
	# 4. Munculkan Item Drop
	spawn_drop()
	
	# 5. Lapor ke Game Manager 
	# (Game Manager di Stage 1 sudah punya delay 2 detik sendiri sebelum kunci muncul.
	# Jadi: Item muncul -> Lapor -> Tunggu 2 detik -> Kunci Muncul)
	if game_manager:
		game_manager.boss_defeated()

# --- [BARU] FUNGSI SPAWN ITEM ---
func spawn_drop():
	if DROP_ITEM_SCENE:
		var item = DROP_ITEM_SCENE.instantiate()
		item.global_position = global_position
		# Spawn di root scene (bukan di dalam boss)
		get_tree().root.add_child(item)
		print("Power Up Dropped!")

# --- SIGNALS ---
func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		current_state = CHASE

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player_ref = null
		current_state = IDLE

func _on_hitbox_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		elif body.has_method("die"): 
			body.die()

func _on_body_hitbox_body_entered(body):
	if body.is_in_group("player"):
		is_player_inside_body = true
		body_damage_timer = 0.0

func _on_body_hitbox_body_exited(body):
	if body.is_in_group("player"):
		is_player_inside_body = false
		body_damage_timer = 0.0
