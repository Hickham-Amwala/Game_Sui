extends Area2D

var speed = 400       # [SARAN] Saya ubah jadi 400 biar "melesat". Kalau 10 nanti lambat banget kayak siput.
var direction = 1     # 1 Kanan, -1 Kiri
var damage = 3        # Damage es
var is_active = true  # Status apakah peluru masih hidup (belum nabrak)

# [BARU] Variabel untuk menahan gerak saat spawn
var is_flying = false 

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# 1. Mulai dengan animasi "Spawn"
	animated_sprite.play("spawn")
	
	# Saat awal, is_flying masih FALSE (diam di tempat)
	is_flying = false 
	
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# [LOGIKA BARU]
	# Peluru hanya bergerak JIKA:
	# 1. is_active (belum nabrak)
	# 2. DAN is_flying (animasi spawn sudah selesai)
	if is_active and is_flying:
		position.x += speed * direction * delta

func _on_body_entered(body):
	if body.is_in_group("player"): return
	
	# Jika nabrak saat masih spawn atau saat terbang
	if is_active:
		is_active = false # Stop logika collision selanjutnya
		is_flying = false # Stop pergerakan seketika
		
		if body.is_in_group("enemy"):
			if body.has_method("take_damage"):
				body.take_damage(damage)
				print("Musuh beku kena damage!")
		
		animated_sprite.play("hit")

func _on_animation_finished():
	if animated_sprite.animation == "spawn":
		# [POINT UTAMA]
		# Setelah animasi 'spawn' selesai (frame 0-4 beres):
		# 1. Ganti animasi ke 'fly'
		animated_sprite.play("fly")
		# 2. IZINKAN PELURU BERGERAK SEKARANG
		is_flying = true 
		
	elif animated_sprite.animation == "hit":
		queue_free()
