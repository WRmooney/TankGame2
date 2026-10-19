extends Node2D

@onready var windup = $Windup
@onready var explosion = $Explosion
@onready var extraparticles = $ExtraParticles
@onready var winduptimer = $WindupTimer
@onready var explosiondelay = $ExplosionDelay
@onready var endtimer = $EndTimer
@onready var hitbox = $Hitbox
@onready var circlecollisionshape = $Hitbox/CircleCollisionShape

var cur_state = "windup"

var in_explosion = false

func _ready() -> void:
	cur_state = "windup"
	windup.emitting = true
	winduptimer.start(3.0)

func _process(delta: float) -> void:
	if not in_explosion:
		return
	# in_explosion is true
	circlecollisionshape.shape.radius += 5

func _on_windup_timer_timeout() -> void:
	windup.emitting = false
	explosiondelay.start(1.0)


func _on_explosion_delay_timeout() -> void:
	explosion.emitting = true
	extraparticles.emitting = true
	
	in_explosion = true
	circlecollisionshape.disabled = false
	
	endtimer.start(1.0)

func _on_end_timer_timeout() -> void:
	extraparticles.emitting = false
	$DeleteTimer.start(1.0)

func _on_delete_timer_timeout() -> void:
	queue_free()

func _on_hitbox_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if body.is_in_group("player"):
		return
	elif body.is_in_group("hurtable"):
		body.hit(10)
	elif body.is_in_group("bullets"):
		body.queue_free()
