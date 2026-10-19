extends CollisionShape2D

@onready var parent = get_parent()
@onready var tankref = parent.parent

func _ready() -> void:
	parent.add_collision_exception_with(tankref)
	parent.ignore_parent = true

func _physics_process(delta: float) -> void:
	if parent.ignore_parent and parent.position.distance_to(tankref.position) > 30:
		parent.remove_collision_exception_with(tankref)
		parent.ignore_parent = false
