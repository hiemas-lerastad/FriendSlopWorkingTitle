class_name Game;
extends Node

@export var level: Level;

func _on_lobby_started_game() -> void:
	_spawn_players();

func _spawn_players() -> void:
	level.spawn_player(1);
	
	for peer in multiplayer.get_peers():
		level.spawn_player(peer);
