extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var music_2: AudioStreamPlayer = $music2


func _ready() -> void:
	MusicController.stop_music()
	player.player_died.connect(_on_player_died)
	var tween = create_tween()
	tween.tween_property(music_2, "volume_db", 0.0, 2.0)
	
func _on_player_died():
	music_2.stop()
