extends CharacterBody2D
class_name Enemy

@export var enemy_type: String = "cultist"
@export var max_health: float = 50.0
@export var current_health: float = 50.0
@export var speed: float = 100.0
@export var attack_damage: float = 15.0
@export var detection_range: float = 200.0
@export var attack_range: float = 50.0
@export var behavior: String = "patrol"  # patrol, chase, shoot, custom

# AI State
enum State { PATROL, CHASE, ATTACK, IDLE }
var current_state: State = State.PATROL

# Movement
var patrol_start_position: Vector2
var patrol_direction: Vector2 = Vector2.RIGHT
var patrol_distance: float = 100.0

# Combat
var attack_cooldown: float = 1.5
var attack_timer: float = 0.0
var can_attack: bool = true

# References
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea

signal enemy_died(enemy: Enemy)
signal damage_dealt(damage: float)

func _ready():
	patrol_start_position = global_position
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Connect detection area
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Connect attack area
	attack_area.body_entered.connect(_on_attack_area_body_entered)

func _physics_process(delta):
	match current_state:
		State.PATROL:
			patrol_behavior(delta)
		State.CHASE:
			chase_behavior(delta)
		State.ATTACK:
			attack_behavior(delta)
		State.IDLE:
			idle_behavior(delta)
	
	# Update attack cooldown
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true

func patrol_behavior(delta):
	# Move back and forth
	var patrol_target = patrol_start_position + patrol_direction * patrol_distance
	
	if global_position.distance_to(patrol_target) < 10:
		patrol_direction *= -1
		sprite.flip_h = not sprite.flip_h
	
	velocity = patrol_direction * speed
	move_and_slide()

func chase_behavior(delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		current_state = State.PATROL
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	
	# Flip sprite to face player
	if direction.x > 0:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
	
	# Check if in attack range
	if global_position.distance_to(player.global_position) <= attack_range:
		current_state = State.ATTACK
	
	move_and_slide()

func attack_behavior(delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		current_state = State.PATROL
		return
	
	# Stop moving to attack
	velocity = Vector2.ZERO
	
	# Face player
	var direction = (player.global_position - global_position).normalized()
	if direction.x > 0:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
	
	# Attack if cooldown is ready
	if can_attack and global_position.distance_to(player.global_position) <= attack_range:
		perform_attack(player)
	
	# Return to chase if player is too far
	if global_position.distance_to(player.global_position) > attack_range * 1.5:
		current_state = State.CHASE

func idle_behavior(delta):
	velocity = Vector2.ZERO

func perform_attack(target):
	can_attack = false
	attack_timer = attack_cooldown
	
	# Deal damage to target
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
		damage_dealt.emit(attack_damage)
	
	# Play attack animation
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color.WHITE

func take_damage(damage: float):
	current_health -= damage
	health_bar.value = current_health
	
	# Flash red
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func die():
	enemy_died.emit(self)
	queue_free()

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		current_state = State.CHASE

func _on_detection_area_body_exited(body):
	if body.is_in_group("player") and current_state == State.CHASE:
		current_state = State.PATROL

func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and current_state == State.CHASE:
		current_state = State.ATTACK