extends Control

@onready var video_player = $VideoStreamPlayer
# Tambahkan referensi ke node baru
@onready var skip_label = $SkipLabel
@onready var animation_player = $AnimationPlayer

var next_scene_path = "res://scenes/stage1.tscn"

func _ready():
	MusicController.stop_music()
	video_player.finished.connect(_on_video_finished)
	
	# Pastikan label sembunyi di awal (jaga-jaga kalau lupa uncheck Visible di editor)
	skip_label.visible = false

# --- FUNGSI BARU DARI TIMER ---
# Fungsi ini otomatis jalan setelah 5 detik
func _on_show_text_timer_timeout():
	# 1. Munculkan teks
	skip_label.visible = true
	
	# 2. Mulai animasi kedip
	animation_player.play("blink")
# ------------------------------

func _on_video_finished():
	_go_to_next_stage()

func _unhandled_input(event):
	# Logika skip tetap sama
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event is InputEventMouseButton:
		_go_to_next_stage()

func _go_to_next_stage():
	get_tree().change_scene_to_file(next_scene_path)
