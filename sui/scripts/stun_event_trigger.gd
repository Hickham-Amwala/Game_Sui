extends Area2D

@export var boss_node : CharacterBody2D
@export var player_node : CharacterBody2D
@export var falling_object : AnimatedSprite2D
@export var boss_stop_marker : Marker2D

# [BARU] Variabel untuk kamera cinematic
@export var cinematic_camera : Camera2D 

var event_triggered = false

func _ready():
	if falling_object:
		falling_object.visible = false 
	
	# Pastikan kamera cinematic mati di awal (biar pake kamera player)
	if cinematic_camera:
		cinematic_camera.enabled = false

func _on_body_entered(body):
	if body.name == "Player" and not event_triggered:
		start_cinematic_event()

func start_cinematic_event():
	event_triggered = true
	print("EVENT MULAI: Cutscene Batu Jatuh")
	
	# 1. Player Diam
	if player_node.has_method("set_cutscene_mode"):
		player_node.set_cutscene_mode(true)
	
	# 2. Boss Jalan ke Tengah
	if boss_node:
		boss_node.walk_to_position(boss_stop_marker.global_position)
	
	# 3. Tunggu Boss Sampai (Estimasi 3 detik)
	await get_tree().create_timer(3.0).timeout
	
	# 4. Batu Jatuh & PINDAH KAMERA
	if falling_object:
		falling_object.visible = true
		falling_object.play("Falling")
		
		# [BARU] AKTIFKAN KAMERA BATU!
		# Kamera akan otomatis pindah fokus ke batu yang sedang jatuh
		if cinematic_camera:
			cinematic_camera.enabled = true
			cinematic_camera.make_current() # Paksa jadi kamera utama
		
		var tween = get_tree().create_tween()
		# Gerakkan batu ke kepala boss dalam 0.5 detik
		# (Sedikit diperlambat biar kamera sempat mengikuti)
		tween.tween_property(falling_object, "global_position", boss_stop_marker.global_position, 0.5)
		
		await tween.finished 
		
		# 5. Efek Hancur (Crash)
		falling_object.play("Crash")
		
		# Efek kamera getar (Screen Shake) simpel
		if cinematic_camera:
			var shake_tween = get_tree().create_tween()
			shake_tween.tween_property(cinematic_camera, "offset", Vector2(5, 5), 0.05)
			shake_tween.tween_property(cinematic_camera, "offset", Vector2(-5, -5), 0.05)
			shake_tween.tween_property(cinematic_camera, "offset", Vector2.ZERO, 0.05)
		
		# 6. Boss Pingsan
		if boss_node:
			boss_node.is_in_cutscene = false 
			boss_node.start_stun() 

		# Tunggu animasi Crash selesai
		await falling_object.animation_finished
		
		# [BARU] KEMBALIKAN KAMERA KE PLAYER
		if cinematic_camera:
			cinematic_camera.enabled = false 
			# Saat kamera ini mati, Godot otomatis balik ke kamera Player yang aktif
		
		falling_object.queue_free() 
	
	# 7. Player Bergerak Lagi
	if player_node.has_method("set_cutscene_mode"):
		player_node.set_cutscene_mode(false)
		
	queue_free()
