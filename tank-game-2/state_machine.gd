extends Node

@export var initial_state: Node

var node_states : Dictionary = {}
var current_state: Node
var current_state_name: String

@onready var parent = get_parent()
@onready var LOSChecker = $"../vision_component"
@onready var player = get_parent().player

func _ready() -> void:
	for child in get_children():
		node_states[child.name.to_lower()] = child
		child.transition_state.connect(transition_to)
		
	if initial_state:
		current_state = initial_state
		current_state_name = initial_state.name.to_lower()
		enter_initial_state.call_deferred()
		
	
func _process(delta: float) -> void:
	parent.sees_player = LOSChecker.can_see_player() # can replace 1000 with "sharpness" stat later
	if current_state:
		current_state.on_process()

func transition_to(new_state_name: String):
	if new_state_name == current_state.name.to_lower():
		return
	
	var new_node_state = node_states.get(new_state_name.to_lower())
	
	if !new_node_state:
		return
		
	if current_state:
		current_state.exit()
	
	new_node_state.enter()
	
	current_state = new_node_state
	current_state_name = current_state.name.to_lower()

func enter_initial_state() -> void:
	await get_tree().physics_frame
	initial_state.enter()
	
func _on_pathing_timer_timeout() -> void:
	current_state.pathing_timer_timeout()


func _on_navigation_agent_2d_target_reached() -> void:
	current_state.target_reached()
