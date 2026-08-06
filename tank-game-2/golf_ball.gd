extends RigidBody2D

var level_started = false

func _ready() -> void:
	print("ready")

func hit(body):
	apply_impulse(Vector2(position.x - body.position.x, position.y - body.position.y).normalized() * 150, body.position - position)

func _process(delta: float) -> void:
	if not level_started:
		level_started = true
		if $VisibleOnScreenNotifier2D.is_on_screen():
			$TrackingArrow.visible = false
		else:
			$TrackingArrow.visible = true
	var cam = get_viewport().get_camera_2d()
	if cam:
		var ang_from_center = atan2(global_position.y - cam.global_position.y, global_position.x - cam.global_position.x)
		$TrackingArrow/Container/ColorRect.rotation = ang_from_center
	


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	$TrackingArrow.visible = false



func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$TrackingArrow.visible = true
