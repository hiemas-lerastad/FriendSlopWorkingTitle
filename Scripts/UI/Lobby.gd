class_name Lobby;
extends Control;

signal started_game;
signal quit_game;

@export var host_controls: Array[Control] = [];
@export var player_card_scene: PackedScene;
@export var player_cards: HBoxContainer;

func setup_screen() -> void:
	if not multiplayer.is_server():
		for control in host_controls:
			control.hide();
	else:
		var player_card: Control = player_card_scene.instantiate()
		player_card.name = "1";
		player_cards.add_child(player_card);

		multiplayer.peer_connected.connect(
			func(id: int) -> void:
				var client_player_card: Control = player_card_scene.instantiate();
				client_player_card.name = str(id);
				player_cards.add_child(client_player_card);
		);

		multiplayer.peer_disconnected.connect(
			func(id: int) -> void:
				var client_player_card: Control = player_cards.get_node(str(id));
				client_player_card.queue_free();
		);

func _on_visibility_changed() -> void:
	if visible:
		setup_screen();

func _on_start_pressed() -> void:
	started_game.emit();

func _on_quit_pressed() -> void:
	multiplayer.multiplayer_peer.close();
	quit_game.emit();
