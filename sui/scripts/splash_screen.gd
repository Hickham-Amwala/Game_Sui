extends Control

@export_file("*.tscn") var main_menu_scene = "res://scenes/main_menu.tscn"
@onready var video_player = $VideoStreamPlayer

func _ready():
	# --- [SOLUSI MUSIK] ---
	# Matikan musik apapun yang mungkin nyala otomatis dari Autoload
	if MusicController:
		MusicController.stop_music()
	# ----------------------
	
	if video_player:
		# Solusi tambahan biar video pas di layar lewat kodingan (kalau inspector bandel)
		video_player.expand = true 
		
		video_player.play()
		video_player.finished.connect(_on_video_finished)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
		_on_video_finished()

func _on_video_finished():
	if main_menu_scene:
		get_tree().change_scene_to_file(main_menu_scene)
