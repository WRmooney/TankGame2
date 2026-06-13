extends GPUParticles2D

@onready var collisionshape = $Area2D/CollisionShape2D
@onready var area = $Area2D
@onready var col_on = $Col_on
@onready var col_off = $Col_off

@export var length: float
@export var damage: float = 1

@export var ex_radius: float = 2


var col_start: float
var col_end: float

func _ready() -> void:
	lifetime = length
	$Area2D/CollisionShape2D.scale = Vector2(ex_radius, ex_radius)
	process_material.scale_min = 0.5 * ex_radius
	process_material.scale_max = 0.5 * ex_radius
	col_start = length * 0.1
	col_end = length * 0.75
	col_on.start(col_start)
	col_off.start(col_end)
	emitting = true
	
func _process(_delta: float) -> void:
	#print(area.get_overlapping_bodies())
	if not emitting:
		queue_free()

func _on_col_on_timeout() -> void:
	collisionshape.disabled = false

func _on_col_off_timeout() -> void:
	collisionshape.disabled = true
