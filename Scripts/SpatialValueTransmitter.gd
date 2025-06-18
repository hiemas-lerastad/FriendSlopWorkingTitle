class_name SpatialValueTransmitter;
extends Node3D;

@export_subgroup("Nodes")
@export var target: Node3D;

@export_subgroup("Settings")
@export var exclusions: Array[Node3D] = [];
@export var default_occlusion_value: float = 1.0;
@export var frame_update_spacing: int = 5;
@export var frame_update_offset: int = 0;
@export var transmitting: bool = false;
@export var base_value: float = 1.0;
@export var occlusion_property: String = "occlusion";

@export_subgroup("Smoothing")
@export var smooth_occlusion: bool = false;
@export var smoothing_duration: float = 0.2;

@export_subgroup("Signal")
@export var use_frequency: bool = false;
@export var frequency_map: Gradient;
@export_range(0.0, 10000.0, 0.1) var range_partial : float;
@export_range(0.0, 10000.0, 0.1) var range_full : float;

@export_subgroup("Debug")
@export var active_color: Color = ProjectSettings.get_setting("debug/shapes/collision/shape_color");
@export var inactive_color: Color = ProjectSettings.get_setting("debug/shapes/collision/contact_color");
@export var disable_debug_markers: bool = true;
@export var disable_range_markers: bool = false;
@export var disable_occlusion_markers: bool = false;

var cast_array: Array;
var value: float = 1.0;

var frequency_value: float = 0.0;
var occlusion_multiplier: float = 0.0;
var occlusion_amount: float = 0.0;

var debug: bool;
var debug_draw_calls: Array[Dictionary] = [];

var time: float = 0.0;

func _ready() -> void:
	debug = is_debug();

func _process(_delta: float) -> void:
	if debug and debug_draw_calls.size():
		for draw_call in debug_draw_calls:
			Debug[draw_call.function_call].call(draw_call.point_one, draw_call.point_two, draw_call.color);

func _physics_process(delta) -> void:
	if Engine.get_physics_frames() % frame_update_spacing == frame_update_offset:
		if debug:
			debug_draw_calls = [];
			
		var output_value: float;
		if smooth_occlusion:
			if time < smoothing_duration:
				time += delta * frame_update_spacing;
				output_value = lerpf(value, (frequency_value) * (1.0 - occlusion_amount * occlusion_multiplier), time / smoothing_duration);

		else:
			output_value = (frequency_value) * (1.0 - occlusion_amount * occlusion_multiplier);

		if not target or is_nan(output_value):
			output_value = 0.0;

		value = output_value;

		if not use_frequency:
			update_strength(get_signal_strength(1.0));

		if debug and not disable_range_markers and target:
			var distance: float = global_position.distance_to(target.global_position);

			if distance > range_partial:
				debug_draw_calls.append({
					'function_call': 'draw_sphere',
					'point_one': global_position,
					'point_two': range_partial,
					'color': active_color
				});

				debug_draw_calls.append({
					'function_call': 'draw_sphere',
					'point_one': global_position,
					'point_two': range_full,
					'color': active_color
				})
			elif distance > range_full and distance < range_partial:
				debug_draw_calls.append({
					'function_call': 'draw_sphere',
					'point_one': global_position,
					'point_two': range_partial,
					'color': inactive_color
				});

				debug_draw_calls.append({
					'function_call': 'draw_sphere',
					'point_one': global_position,
					'point_two': range_full,
					'color': active_color
				})
			else:
				debug_draw_calls.append({
					'function_call': 'draw_sphere',
					'point_one': global_position,
					'point_two': range_partial,
					'color': inactive_color
				});

				debug_draw_calls.append({
					'function_call': 'draw_sphere',
					'point_one': global_position,
					'point_two': range_full,
					'color': inactive_color
				})

func update_occlusion() -> void:
	if target and transmitting and is_in_range(target.global_position):
		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state;
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position, target.global_position);
		query.exclude = [target];
		var collision: Dictionary = space_state.intersect_ray(query);

		if collision:
			var collider: PhysicsBody3D = collision.collider;
			occlusion_multiplier = 1.0;

			if debug and not disable_occlusion_markers:
				debug_draw_calls.append({
					'function_call': 'draw_line',
					'point_one': global_position,
					'point_two': target.global_position,
					'color': inactive_color
				})

			if "physics_material_override" in collider:
					if collider.physics_material_override is MaterialProperties:
						occlusion_amount = collider.physics_material_override[occlusion_property];
					else:
						occlusion_amount = default_occlusion_value;
			else:
				occlusion_amount = default_occlusion_value;

			var path_found: bool = false;
			var distances: Array = [1.0, 2.0, 3.0, 4.0];

			for index in distances.size():
				var distance: float = distances[index];
				var cone_points: Array[Vector3] = get_circle_points(global_position, target.global_position, distance);

				for point in cone_points:
					query.to = point;
					var radial_collision: Dictionary = space_state.intersect_ray(query);

					if radial_collision:
						if debug and not disable_occlusion_markers:
							debug_draw_calls.append({
								'function_call': 'draw_line',
								'point_one': global_position,
								'point_two': point,
								'color': inactive_color
							})
					else:
						if debug and not disable_occlusion_markers:
							debug_draw_calls.append({
								'function_call': 'draw_line',
								'point_one': global_position,
								'point_two': point,
								'color': active_color
							})
						query.from = point;
						query.to = target.global_position;
		
						var inwards_collision: Dictionary = space_state.intersect_ray(query);
						query.from = global_position;
						
						if not inwards_collision:
							if debug and not disable_occlusion_markers:
								debug_draw_calls.append({
									'function_call': 'draw_line',
									'point_one': point,
									'point_two': target.global_position,
									'color': active_color
								})

							occlusion_multiplier = (1.0 / (distances.size() + 1)) * (index + 1);
							path_found = true;
							break;
						elif debug and not disable_occlusion_markers:
							debug_draw_calls.append({
								'function_call': 'draw_line',
								'point_one': point,
								'point_two': target.global_position,
								'color': inactive_color
							})

				if path_found:
					break;

		else:
			occlusion_multiplier = 0.0;

			if debug and not disable_occlusion_markers:
				debug_draw_calls.append({
					'function_call': 'draw_line',
					'point_one': global_position,
					'point_two': target.global_position,
					'color': active_color
				})

		time = 0.0;

func is_debug() -> bool:
	return (Engine.is_editor_hint() or get_tree().debug_collisions_hint) and not disable_debug_markers and Debug;

func is_in_range(pos: Variant = null) -> bool:
	if not target:
		return false;
	
	if not pos or not pos is Vector3:
		pos = target.global_position;

	var distance = global_position.distance_to(pos);
	if (distance <= range_partial):
		return true;
	else:
		return false;

func update_strength(new_strength: float) -> void:
	if Engine.get_physics_frames() % frame_update_spacing == frame_update_offset:
		if new_strength < 0.01:
			frequency_value = 0.0;
		elif new_strength > 0.99:
			frequency_value = base_value;
		else:
			frequency_value = remap(new_strength, 0.0, 1.0, 0.0, base_value);
		if new_strength > 0.0:
			update_occlusion();

func get_circle_points(tip: Vector3, center: Vector3, radius: float) -> Array[Vector3]:
	var points: Array[Vector3] = [];

	var axis: Vector3 = (center - tip).normalized();

	var up: Vector3 = Vector3(0, 1, 0);

	if abs(axis.dot(up)) > 0.99:
		up = Vector3(0, 0, 1);

	var u: Vector3 = up.cross(axis).normalized();
	var v: Vector3 = axis.cross(u).normalized();

	for i in range(8):
		var angle = deg_to_rad(i * 45);
		var dir = u * cos(angle) + v * sin(angle);
		var point = center + dir * radius;
		points.append(point);

	return points;

func get_signal_strength(frequency: float) -> float:
	if target:
		var freq_strength: float;
		var distance = global_position.distance_to(target.global_position);
		
		if not use_frequency:
			freq_strength = 1.0;
		else:
			freq_strength = frequency_map.sample(frequency).a;

		if is_in_range():
			distance = clampf(distance, range_full, range_partial);
			distance = remap(distance, range_full, range_partial, 0.0, 1.0);
			var signal_strength = (1 - distance) * freq_strength;
			return signal_strength;
		else:
			return 0.0;
	return 0.0;
