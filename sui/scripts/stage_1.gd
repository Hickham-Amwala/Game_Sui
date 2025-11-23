extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var music_1: AudioStreamPlayer2D = $music1


func _ready() -> void:
	$FadeTransition/AnimationPlayer.play("Fade_Out")
	player.player_died.connect(_on_player_died)
	var tween = create_tween()
	tween.tween_property(music_1, "volume_db", 0.0, 2.0)
	
func _on_player_died():
	music_1.stop()
