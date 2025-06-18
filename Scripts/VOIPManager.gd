class_name VOIPManager;
extends Node;

@export_subgroup("Nodes")
@export var input: AudioStreamPlayer3D;
@export var output: AudioStreamPlayer3D;

@export_subgroup("Settings")
@export var buffer_size: int = 1024;

var idx: int;
var effect: AudioEffectCapture;
var playback: AudioStreamGeneratorPlayback;

func _ready() -> void:
	if is_multiplayer_authority():
		input.stream = AudioStreamMicrophone.new();
		input.play();
		
		idx = AudioServer.get_bus_index("Record");
		effect = AudioServer.get_bus_effect(idx, 0);
	else:
		output.play()
		playback = output.get_stream_playback();

func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return;

	if effect.can_get_buffer(buffer_size):
		send_data.rpc(effect.get_buffer(buffer_size));

	effect.clear_buffer();
	
@rpc("any_peer", "call_remote", "reliable")
func send_data(data : PackedVector2Array):
	for i in range(0, buffer_size):
		playback.push_frame(data[i]);
