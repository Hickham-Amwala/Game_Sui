extends Area2D

# Referensi ke boss (bisa ditarik via inspector atau cari manual)
@export var boss_node : CharacterBody2D 

func _on_body_entered(body):
	# Cek apakah yang lewat adalah Player
	if body.name == "Player": # Pastikan nama node player kamu "Player"
		if boss_node:
			boss_node.activate_boss() # Panggil fungsi di script boss
			
			# Hapus trigger agar tidak terpanggil berkali-kali
			queue_free()
