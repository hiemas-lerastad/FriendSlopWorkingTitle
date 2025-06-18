class_name UIManager;
extends CanvasLayer;

@export var connection_manager: ConnectionManager;
@export var lobby: Lobby;

func _on_connection_manager_hosting() -> void:
	_switch_to_lobby();

func _on_connection_manager_joining() -> void:
	_switch_to_lobby();

func _switch_to_lobby() -> void:
	connection_manager.hide();
	lobby.show();

func _on_lobby_started_game() -> void:
	hide_child.rpc(lobby.get_path());

func _on_lobby_quit_game() -> void:
	lobby.hide();
	connection_manager.show();

@rpc("call_local")
func hide_child(path: NodePath) -> void:
	get_node(path).hide();
