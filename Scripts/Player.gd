class_name Player;
extends CharacterBody3D;

@export var pivot: Node3D;
@export var held_item: Node3D;
@export var camera: Camera3D;
@export var voip_manager: VOIPManager;

const SPEED = 5.0;
const JUMP_VELOCITY = 100;

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)));

	if voip_manager:
		voip_manager.set_multiplayer_authority(int(str(name)));

func _ready() -> void:
	if is_multiplayer_authority():
		for sig in get_tree().get_nodes_in_group("Transmitter"):
			sig.target = self;

		camera.set_multiplayer_authority(int(str(name)));
		camera.current = true;

		if held_item:
			held_item.set_multiplayer_authority(int(str(name)));
	else:
		camera.queue_free();

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return;

	for sig in get_tree().get_nodes_in_group("Transmitter"):
		if not sig.target:
			sig.target = self;

	if not is_on_floor():
		velocity += get_gravity() * delta;

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY;

	var input_dir: Vector2 = Input.get_vector("movement_left", "movement_right", "movement_forward", "movement_backward");
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized();
	if direction:
		velocity.x = direction.x * SPEED;
		velocity.z = direction.z * SPEED;
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED);
		velocity.z = move_toward(velocity.z, 0, SPEED);

	move_and_slide();

func _input(event: InputEvent) -> void:
	if held_item and "input_update" in held_item:
		held_item.input_update(event);

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * 0.006);
			pivot.rotate_x(-event.relative.y * 0.006);
			pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-60), deg_to_rad(60));
