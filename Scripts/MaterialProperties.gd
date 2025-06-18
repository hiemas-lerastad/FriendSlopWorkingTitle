class_name MaterialProperties;
extends PhysicsMaterial;

@export_group("Spatial Audio")
@export_range(0.0, 1.0, 0.01) var occlusion: float = 1.0;
@export_range(0.0, 1.0, 0.01) var signal_occlusion: float = 1.0;
@export_range(0.0, 1.0, 0.01) var radiation : float = 1.0;
