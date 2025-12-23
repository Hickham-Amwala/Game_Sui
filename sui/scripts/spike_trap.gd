extends Area2D

# Tarik node AudioStreamPlayer2D ke sini (pastikan namanya sesuai)
@onready var trap_sound = $AudioStreamPlayer2D

# Setting berapa detik diamnya (Ganti angka ini sesuai keinginan)
var waktu_jeda = 0.73 

func _ready():
	# Mulai mainkan suara saat game mulai
	putar_suara_loop()

func _on_body_entered(body):
	if body.name == "Player":
		print("Player kena duri!")
		if body.has_method("die"):
			body.die()

# --- FUNGSI BARU UNTUK LOOPING DENGAN JEDA ---
func putar_suara_loop():
	# Cek keamanan: Jika trap sudah dihapus dari game, berhenti looping
	if not is_inside_tree(): return
	
	if trap_sound:
		# 1. Mainkan Suara
		trap_sound.play()
		
		# 2. Tunggu sampai durasi suara selesai (misal suaranya 0.5 detik)
		await trap_sound.finished
		
		# 3. Tunggu lagi selama waktu jeda (misal 2 detik)
		await get_tree().create_timer(waktu_jeda).timeout
		
		# 4. Panggil diri sendiri lagi (Ulangi dari langkah 1)
		putar_suara_loop()
