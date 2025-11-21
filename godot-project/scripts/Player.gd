extends CharacterBody2D
class_name Drakelord

# Core Stats
@export var max_health: float = 150.0
@export var current_health: float = 150.0
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0

# Combat Stats
@export var attack_power: float = 25.0
@export var defense: float = 10.0
@export var crit_chance: float = 0.15
@export var crit_multiplier: float = 2.0

# RPG Systems
@export var level: int = 1
@export var experience: int = 0
@export var experience_to_next: int = 100
@export var skill_points: int = 0

# Abilities
@export var dragon_breath_cooldown: float = 3.0
@export var wing_burst_cooldown: float = 5.0
@export var ancient_rage_cooldown: float = 10.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_ancient_rage_active: bool = false
var rage_timer: float = 0.0

# Cooldown Timers
var dragon_breath_timer: float = 0.0
var wing_burst_timer: float = 0.0
var ancient_rage_timer: float = 0.0

# References
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var level_label: Label = $UI/LevelLabel
@onready var ability_cooldowns: HBoxContainer = $UI/AbilityCooldowns

signal health_changed(current: float, max: float)
signal level_up(new_level: int)
signal experience_gained(amount: int)
signal ability_used(ability_name: String)

func _ready():
	health_changed.emit(current_health, max_health)
	level_up.emit(level)

func _physics_process(delta):
	# Handle gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Handle movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# Update cooldowns
	update_cooldowns(delta)
	
	# Handle abilities
	handle_abilities()
	
	# Update rage timer
	if is_ancient_rage_active:
		rage_timer -= delta
		if rage_timer <= 0:
			deactivate_ancient_rage()

	move_and_slide()

func handle_abilities():
	# Dragon Breath (Space)
	if Input.is_action_just_pressed("dragon_breath") and dragon_breath_timer <= 0:
		use_dragon_breath()
	
	# Wing Burst (Shift)
	if Input.is_action_just_pressed("wing_burst") and wing_burst_timer <= 0:
		use_wing_burst()
	
	# Ancient Rage (R)
	if Input.is_action_just_pressed("ancient_rage") and ancient_rage_timer <= 0:
		use_ancient_rage()

func use_dragon_breath():
	dragon_breath_timer = dragon_breath_cooldown
	var breath = preload("res://scenes/DragonBreath.tscn").instantiate()
	get_parent().add_child(breath)
	breath.global_position = global_position + Vector2(50 * sign(sprite.scale.x), 0)
	ability_used.emit("Dragon Breath")

func use_wing_burst():
	wing_burst_timer = wing_burst_cooldown
	velocity.y = jump_velocity * 1.5
	velocity.x = speed * 2 * sign(sprite.scale.x)
	
	# Create wing effect
	var wing_effect = preload("res://scenes/WingEffect.tscn").instantiate()
	get_parent().add_child(wing_effect)
	wing_effect.global_position = global_position
	ability_used.emit("Wing Burst")

func use_ancient_rage():
	ancient_rage_timer = ancient_rage_cooldown
	is_ancient_rage_active = true
	rage_timer = 5.0
	attack_power *= 2
	speed *= 1.5
	sprite.modulate = Color.RED
	ability_used.emit("Ancient Rage")

func deactivate_ancient_rage():
	is_ancient_rage_active = false
	attack_power /= 2
	speed /= 1.5
	sprite.modulate = Color.WHITE

func update_cooldowns(delta):
	if dragon_breath_timer > 0:
		dragon_breath_timer -= delta
	if wing_burst_timer > 0:
		wing_burst_timer -= delta
	if ancient_rage_timer > 0:
		ancient_rage_timer -= delta

func take_damage(damage: float):
	var actual_damage = max(0, damage - defense)
	current_health -= actual_damage
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()

func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func gain_experience(amount: int):
	experience += amount
	experience_gained.emit(amount)
	
	while experience >= experience_to_next:
		level_up()

func level_up():
	experience -= experience_to_next
	level += 1
	experience_to_next = int(experience_to_next * 1.5)
	skill_points += 1
	
	# Increase stats
	max_health += 20
	current_health = max_health
	attack_power += 5
	defense += 2
	speed += 10
	
	health_changed.emit(current_health, max_health)
	level_up.emit(level)

func die():
	# Handle player death
	get_tree().change_scene_to_file("res://scenes/DefeatScreen.tscn")