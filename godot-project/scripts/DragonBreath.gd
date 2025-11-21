extends Area2D
class_name DragonBreath

@export var speed: float = 400.0
@export var damage: float = 35.0
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var time_alive: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Connect body entered signal
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Move projectile
	global_position += direction * speed * delta
	
	# Update lifetime
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
	# Rotate sprite to match direction
	sprite.rotation = direction.angle()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		# Deal damage to enemy
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# Create impact effect
		create_impact_effect()
		
		# Destroy projectile
		queue_free()
	elif body.is_in_group("walls"):
		# Create impact effect and destroy
		create_impact_effect()
		queue_free()

func create_impact_effect():
	# Create visual impact effect
	var impact = preload("res://scenes/ImpactEffect.tscn").instantiate()
	get_tree().current_scene.add_child(impact)
	impact.global_position = global_position