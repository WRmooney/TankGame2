extends Area2D

@export var line_points: PackedVector2Array
@export var wait_time: float
@export var duration: float
@export var width: float


func _ready() -> void:
	$Line2D.points = line_points
	$Line2D.width = width *2
	$HitBoxTimer.start(wait_time)



func _on_hit_box_timer_timeout() -> void:
	$HitBoxTimer.stop()
	$LaserSound.play()
	for i in range(len($Line2D.points) - 1):
		var shape = ConvexPolygonShape2D.new()
		var angle = atan2($Line2D.points[i+1].y - $Line2D.points[i].y, $Line2D.points[i+1].x - $Line2D.points[i].x)
		shape.points = [$Line2D.points[i] + Vector2(width, 0).rotated(angle + 90), $Line2D.points[i] + Vector2(width, 0).rotated(angle - 90), $Line2D.points[i+1] + Vector2(width, 0).rotated(angle - 90), $Line2D.points[i+1] + Vector2(width, 0).rotated(angle + 90)]
		var collision = CollisionShape2D.new()
		collision.shape = shape
		add_child(collision)
	$Line2D.default_color = Color.ORANGE
	$DurationTimer.start(duration)



func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.hit(1) # damage?


func _on_duration_timer_timeout() -> void:
	queue_free()
