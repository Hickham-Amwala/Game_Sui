extends Area2D

@export var boss_node : CharacterBody2D
@export var player_node : CharacterBody2D
@export var falling_object : AnimatedSprite2D # [UBAH TIPE DATA JADI ANIMATED SPRITE]
@export var boss_stop_marker : Marker2D

var event_triggered = false

func _ready():
	if falling_object:
		falling_object.visible = false # Sembunyi dulu

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
	
	# 4. Batu Jatuh
	if falling_object:
		falling_object.visible = true
		falling_object.play("Falling") # Mainkan animasi jatuh
		
		var tween = get_tree().create_tween()
		# Gerakkan batu ke kepala boss dalam 0.4 detik (cepat)
		tween.tween_property(falling_object, "global_position", boss_stop_marker.global_position, 0.4)
		
		await tween.finished # Tunggu sampai kena kepala
		
		# 5. Efek Hancur (Crash)
		falling_object.play("Crash") # Mainkan animasi hancur
		
		# 6. Boss Pingsan (Stun) TEPAT saat batu kena
		if boss_node:
			boss_node.is_in_cutscene = false 
			boss_node.start_stun() 

		# Tunggu animasi Crash selesai baru batunya hilang
		await falling_object.animation_finished
		falling_object.queue_free() 
	
	# 7. Player Bergerak Lagi
	if player_node.has_method("set_cutscene_mode"):
		player_node.set_cutscene_mode(false)
		
	queue_free()
