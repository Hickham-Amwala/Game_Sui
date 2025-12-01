extends Area2D

# Variabel untuk menentukan level selanjutnya (isi di Inspector nanti)
@export_file("*.tscn") var next_level_path

@onready var collision_shape = $CollisionShape2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var game_manager = %GameManager # Mengakses GameManager

func _ready():
	# 1. SEMBUNYIKAN KUNCI SAAT GAME MULAI
	hide() # Membuat visualnya hilang
	
	# Matikan collision agar player tidak bisa menabrak "kunci hantu"
	collision_shape.disabled = true 
	
	# 2. DENGARKAN SINYAL DARI GAME MANAGER
	if game_manager:
		game_manager.level_unlocked.connect(_on_level_unlocked)

# Fungsi ini jalan saat koin habis (GameManager mengirim sinyal)
func _on_level_unlocked():
	print("Kunci Muncul!")
	
	# 3. MUNCULKAN KUNCI
	show() # Membuat visualnya terlihat
	
	# Nyalakan collision lagi (pakai set_deferred agar aman dari error fisika)
	collision_shape.set_deferred("disabled", false)
	
	# Mainkan animasi (opsional, jika punya animasi muncul)
	animated_sprite.play("start")
	
	animated_sprite.play("idle")

# Saat Player menyentuh kunci
func _on_body_entered(body):
	print("Sesuatu menyentuh kunci! Bernama: ", body.name)
	
	if body.is_in_group("player"):
		print("Kunci diambil! Menuju level berikutnya...")
		
		# Pindah ke level selanjutnya
		if next_level_path:
			call_deferred("change_level")

func change_level():
	get_tree().change_scene_to_file(next_level_path)
