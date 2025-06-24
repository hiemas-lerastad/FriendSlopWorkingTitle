class_name Radio;
extends Node3D;

@export_group("Settings")
@export var desired_frequency: float = 0.1;
@export var static_stream: AudioStream;
@export_range(-20.0, 0.0, 1.0) var static_volume: float = -20.0;
@export var transmitting: bool = false;

@export_group("Nodes")
@export var voice_output: SpatialTransmitter;

@export_group("Visuals")
@export var mesh: MeshInstance3D;
@export var gradient_strength: Gradient;
@export var gradient_spectrogram: Gradient;
@export var animation_tree: AnimationTree;

@export_group("Materials")
@export var oscilloscope_material: ShaderMaterial;
@export var spectrogram_material: ShaderMaterial;
@export var strength_indicator_material: ShaderMaterial;

var radio_bus_listener: AudioEffectInstance;

var reciever_signal_strength: float = 0.0;
var signal_strengths: float;
var frequency: float = 0.0;

var strength_texture: GradientTexture2D = GradientTexture2D.new();

var spectrogram_img: Image;
var spectrogram_texture: ImageTexture;
var spectrogram_timer: Timer;

func _ready() -> void:
	spectrogram_img = Image.create(512, 256, false, Image.FORMAT_RGBA8);
	spectrogram_texture = ImageTexture.create_from_image(spectrogram_img);
	spectrogram_timer = Timer.new();

	make_unique();

	var radio_bus_id: int = AudioServer.get_bus_index("Radio Effects");
	
	if not is_multiplayer_authority():
		radio_bus_id = AudioServer.get_bus_index("Radio Output");
	
	radio_bus_listener = AudioServer.get_bus_effect_instance(radio_bus_id, 0);
	
	spectrogram_img.fill(gradient_spectrogram.sample(0.0));

	add_child(spectrogram_timer);
	spectrogram_timer.wait_time = 0.016;
	spectrogram_timer.timeout.connect(update_spectrogram);
	spectrogram_timer.start();

func make_unique() -> void:
	if mesh.mesh:
		var new_mesh: Mesh = mesh.mesh.duplicate();
		mesh.mesh = new_mesh;

		for i in mesh.mesh.get_surface_count():
			var material: Material = mesh.mesh.surface_get_material(i);
			if material:
				var new_material = material.duplicate();

				#if is_multiplayer_authority():
					#new_material.set_shader_parameter("foreground", true);

				match material:
					oscilloscope_material:
						oscilloscope_material = new_material;
					spectrogram_material:
						spectrogram_material = new_material;
					strength_indicator_material:
						strength_indicator_material = new_material;

				mesh.mesh.surface_set_material(i, new_material);

func input_update(event):
	if is_multiplayer_authority():
		if frequency < 0.999 and event.is_action_pressed("device_tune_up"):
			desired_frequency += 0.01

		if frequency > 0.001 and event.is_action_pressed("device_tune_down"):
			desired_frequency -= 0.01

		desired_frequency = clamp(desired_frequency, 0.0, 1.0)
		
		if event.is_action_pressed("device_state_toggle"):
			update_transmitting_state.rpc(!transmitting);
			update_transmitting_state(!transmitting);

@rpc("authority", "call_remote")
func update_transmitting_state(state: bool) -> void:
	transmitting = state;
	voice_output.transmitting = state;

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		update(delta);

func update(delta):
	frequency = lerpf(frequency, desired_frequency, delta * 4)
	update_visuals(delta)
	reciever_signal_strength = 0.0
	find_signals()

func find_signals():
	for sig in get_tree().get_nodes_in_group("Signal Transmitter"):
		if sig is SpatialTransmitter:
			if sig.use_frequency:
				var signal_strength = sig.get_signal_strength(frequency);
				reciever_signal_strength += signal_strength * (1.0 - (sig.occlusion_amount * sig.occlusion_multiplier));
				sig.update_strength(signal_strength);

func update_visuals(_delta):
	var strength = reciever_signal_strength
	oscilloscope_material.set_shader_parameter("frequency", (frequency) * 60);

	if transmitting:
		strength_indicator_material.set_shader_parameter("albedo", Vector3(0, 0, 1));
		strength_indicator_material.set_shader_parameter("albedo", Vector3(0, 0, 1));
		strength_indicator_material.set_shader_parameter("emission_energy", 1.0);
	else:
		strength_indicator_material.set_shader_parameter("albedo", gradient_strength.sample(strength));
		strength_indicator_material.set_shader_parameter("emission", gradient_strength.sample(strength));
		strength_indicator_material.set_shader_parameter("emission_energy", 1.0);

	spectrogram_material.set_shader_parameter("texture_albedo", spectrogram_texture);
	spectrogram_material.set_shader_parameter("texture_emission", spectrogram_texture);
	
	animation_tree.set("parameters/Frequency/blend_amount", frequency);
	
	_update_client_visuals.rpc(strength, frequency);

@rpc("authority", "call_remote")
func _update_client_visuals(strength: float, client_frequency: float) -> void:
	oscilloscope_material.set_shader_parameter("frequency", (client_frequency) * 60);

	if transmitting:
		strength_indicator_material.set_shader_parameter("albedo", Vector3(0, 0, 1));
		strength_indicator_material.set_shader_parameter("albedo", Vector3(0, 0, 1));
		strength_indicator_material.set_shader_parameter("emission_energy", 1.0);
	else:
		strength_indicator_material.set_shader_parameter("albedo", gradient_strength.sample(strength));
		strength_indicator_material.set_shader_parameter("emission", gradient_strength.sample(strength));
		strength_indicator_material.set_shader_parameter("emission_energy", 1.0);
	
	animation_tree.set("parameters/Frequency/blend_amount", client_frequency);

	spectrogram_material.set_shader_parameter("texture_albedo", spectrogram_texture);
	spectrogram_material.set_shader_parameter("texture_emission", spectrogram_texture);

func update_spectrogram() -> void:
	var height: float = spectrogram_img.get_height();
	var tempImg: Image = Image.new();
	
	tempImg.copy_from(spectrogram_img);
	spectrogram_img.blit_rect(tempImg, Rect2(0, 0, spectrogram_img.get_width() - 1, height), Vector2(1,0));
	
	var hz_segment: int = int(16000.0 / height);
	var hz_prev: int = 0;

	for i in height:
		var hz_current: int = hz_prev + hz_segment;

		hz_prev = hz_current;
		spectrogram_img.set_pixel(
			0,
			int(height - i - 1),
			gradient_spectrogram.sample(
				1000 * radio_bus_listener.get_magnitude_for_frequency_range(hz_prev, hz_current).length()
			)
		);

	spectrogram_texture = ImageTexture.create_from_image(spectrogram_img);
