class_name Level;
extends Node

@export var player_scene: PackedScene;
@export var player_spawner: MultiplayerSpawner;

func _ready() -> void:
	player_spawner.spawn_function = _multiplayer_spawner_player;

func spawn_player(authority_pid: int) -> void:
	player_spawner.spawn(authority_pid);

func _multiplayer_spawner_player(authority_pid: int) -> Player:
	var player = player_scene.instantiate();
	player.name = str(authority_pid);

	return player;
