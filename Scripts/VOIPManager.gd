class_name VOIPManager;
extends Node;

@export_subgroup("Nodes")
@export var input: AudioStreamPlayer3D;
@export var outputs: Array[AudioStreamPlayer3D];

@export_subgroup("Settings")
@export var enabled: bool = true;
@export var buffer_size: int = 1024;
@export var bus_name: String = "Record";
@export var effect_id: int = 0;
@export var microphone_input: bool = true;

var idx: int;
var effect: AudioEffect;
var playbacks: Array[AudioStreamGeneratorPlayback];

func _ready() -> void:
	if is_multiplayer_authority():
		if microphone_input:
			input.stream = AudioStreamMicrophone.new();
			input.play();

		idx = AudioServer.get_bus_index(bus_name);
		effect = AudioServer.get_bus_effect(idx, effect_id);

	for output in outputs:
		output.play()

		playbacks.append(output.get_stream_playback());

func _process(_delta: float) -> void:
	if not is_multiplayer_authority() or not enabled: return;

	buffer_size = effect.get_frames_available();

	if effect.can_get_buffer(buffer_size):
		send_data.rpc(effect.get_buffer(buffer_size));
		#send_data(effect.get_buffer(buffer_size));

	effect.clear_buffer();
	
@rpc("any_peer", "call_remote", "reliable")
func send_data(data : PackedVector2Array):
	for playback in playbacks:
		for i in range(0, data.size()):
			playback.push_frame(data[i]);
