class_name RadiationReciever;
extends Node;

@export var accumulated_radiation: float = 1.0;
@export var radiation_dissapation_rate: float = 0.02;

func _physics_process(_delta: float) -> void:
	accumulated_radiation -= radiation_dissapation_rate;

	for transmitter in get_tree().get_nodes_in_group("Radiation Transmitter"):
		if transmitter is SpatialTransmitter:
			accumulated_radiation += transmitter.value;

	accumulated_radiation = clampf(accumulated_radiation, 0, 10000000);
