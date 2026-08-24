extends Node

@onready var parent = get_parent()
@onready var healthbar = $HealthBar
@onready var smoke_fx = $CT_Smoke
@onready var dis_timer = $DisableTimer
@onready var warn_timer = $WarningTimer

@export var disable_time: float = 20.0

var hbsize = 50

func _ready() -> void:
	if parent.maxhealth > 1:
		healthbar.visible = true

func _process(delta: float) -> void:
	if not dis_timer.is_stopped():
		parent.health = ((disable_time - dis_timer.time_left) / disable_time) * parent.maxhealth
	
	healthbar.size.x = 50 * (parent.health / parent.maxhealth)
	healthbar.position = parent.position + Vector2(-25, 20)

func freeze(time:float):
	if parent.disabled:
		$DisableTimer.paused = true
		$FreezeTimer.start(time)

func hit(damage: float):
	if not dis_timer.is_stopped():
		return
	parent.health -= damage
	if parent.health <= 0:
		# start smoke fx
		smoke_fx.position = parent.position
		smoke_fx.amount = 20
		smoke_fx.emitting = true
		
		$DisabledCT.play()
		
		# Disable enemy for short period
		parent.disabled = true
		
		dis_timer.start(disable_time)
		
		

func _on_disable_timer_timeout() -> void:
	# re-enable enemy
	parent.disabled = false
	
	parent.health = parent.maxhealth
	smoke_fx.emitting = false


func _on_freeze_timer_timeout() -> void:
	$DisableTimer.paused = false
