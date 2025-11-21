extends Node2D

# Game State
var current_level: int = 1
var score: int = 0
var game_active: bool = true
var enemies_defeated: int = 0
var total_enemies: int = 0

# Biome System
var current_biome: String = "dragon_peak"
var biomes = ["dragon_peak", "ancient_ruins", "cosmic_realm"]

# Player Reference
var player: Drakelord

# UI References
@onready var score_label: Label = $UI/ScoreLabel
@onready var level_label: Label = $UI/LevelLabel
@onready var biome_label: Label = $UI/BiomeLabel
@onready var enemies_label: Label = $UI/EnemiesLabel
@onready var start_screen: Control = $StartScreen
@onready var victory_screen: Control = $VictoryScreen
@onready var defeat_screen: Control = $DefeatScreen

# Audio
@onready var music_player: AudioStreamPlayer = $Audio/MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $Audio/SFXPlayer

func _ready():
	# Connect UI buttons
	start_screen.get_node("StartButton").pressed.connect(_on_start_button_pressed)
	victory_screen.get_node("NextLevelButton").pressed.connect(_on_next_level_pressed)
	victory_screen.get_node("RestartButton").pressed.connect(_on_restart_pressed)
	defeat_screen.get_node("RestartButton").pressed.connect(_on_restart_pressed)
	
	# Show start screen
	show_start_screen()

func _process(delta):
	if game_active:
		update_ui()

func show_start_screen():
	game_active = false
	start_screen.visible = true
	victory_screen.visible = false
	defeat_screen.visible = false
	play_music("menu_theme")

func _on_start_button_pressed():
	start_screen.visible = false
	start_level()

func start_level():
	game_active = true
	score = 0
	enemies_defeated = 0
	
	# Load level based on current level
	load_level(current_level)
	
	# Play appropriate music
	match current_biome:
		"dragon_peak":
			play_music("main_theme")
		"ancient_ruins":
			play_music("battle_theme")
		"cosmic_realm":
			play_music("victory_theme")

func load_level(level_num: int):
	# Clear existing enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	
	# Set biome based on level
	current_biome = biomes[(level_num - 1) % biomes.size()]
	
	# Spawn enemies for this level
	spawn_enemies_for_level(level_num)
	
	# Update UI
	biome_label.text = "Biome: " + current_biome.replace("_", " ").capitalize()

func spawn_enemies_for_level(level_num: int):
	var enemy_configs = get_enemy_configs_for_level(level_num)
	total_enemies = enemy_configs.size()
	
	for config in enemy_configs:
		var enemy = preload("res://scenes/Enemy.tscn").instantiate()
		enemy.enemy_type = config.type
		enemy.max_health = config.health
		enemy.current_health = config.health
		enemy.speed = config.speed
		enemy.attack_damage = config.damage
		enemy.behavior = config.behavior
		enemy.global_position = config.position
		enemy.add_to_group("enemies")
		
		# Connect enemy signals
		enemy.enemy_died.connect(_on_enemy_died)
		enemy.damage_dealt.connect(_on_damage_dealt)
		
		add_child(enemy)

func get_enemy_configs_for_level(level_num: int) -> Array:
	var configs = []
	
	match level_num:
		1:
			# Dragon Peak - Cultists and Wyverns
			configs = [
				{
					"type": "cultist",
					"health": 40,
					"speed": 80,
					"damage": 15,
					"behavior": "patrol",
					"position": Vector2(300, 400)
				},
				{
					"type": "wyvern",
					"health": 60,
					"speed": 120,
					"damage": 20,
					"behavior": "chase",
					"position": Vector2(500, 300)
				},
				{
					"type": "cultist",
					"health": 40,
					"speed": 80,
					"damage": 15,
					"behavior": "patrol",
					"position": Vector2(700, 450)
				}
			]
		2:
			# Ancient Ruins - Guardians and more powerful enemies
			configs = [
				{
					"type": "guardian",
					"health": 100,
					"speed": 60,
					"damage": 30,
					"behavior": "chase",
					"position": Vector2(400, 350)
				},
				{
					"type": "wyvern",
					"health": 80,
					"speed": 140,
					"damage": 25,
					"behavior": "shoot",
					"position": Vector2(600, 250)
				},
				{
					"type": "cultist",
					"health": 50,
					"speed": 100,
					"damage": 18,
					"behavior": "patrol",
					"position": Vector2(200, 400)
				},
				{
					"type": "guardian",
					"health": 100,
					"speed": 60,
					"damage": 30,
					"behavior": "custom",
					"position": Vector2(800, 300)
				}
			]
		_:
			# Cosmic Realm - Boss level
			configs = [
				{
					"type": "guardian",
					"health": 200,
					"speed": 80,
					"damage": 40,
					"behavior": "custom",
					"position": Vector2(400, 300)
				},
				{
					"type": "wyvern",
					"health": 100,
					"speed": 160,
					"damage": 30,
					"behavior": "chase",
					"position": Vector2(300, 200)
				},
				{
					"type": "wyvern",
					"health": 100,
					"speed": 160,
					"damage": 30,
					"behavior": "chase",
					"position": Vector2(500, 200)
				}
			]
	
	return configs

func _on_enemy_died(enemy: Enemy):
	enemies_defeated += 1
	score += 100 * current_level
	
	# Player gains experience
	if player:
		player.gain_experience(50 * current_level)
	
	# Check win condition
	if enemies_defeated >= total_enemies:
		level_complete()

func _on_damage_dealt(damage: float):
	play_sfx("enemy_hit")

func level_complete():
	game_active = false
	score += 1000 * current_level
	play_music("victory_theme")
	victory_screen.visible = true

func _on_next_level_pressed():
	victory_screen.visible = false
	current_level += 1
	start_level()

func _on_restart_pressed():
	victory_screen.visible = false
	defeat_screen.visible = false
	current_level = 1
	start_level()

func update_ui():
	score_label.text = "Score: " + str(score)
	if player:
		level_label.text = "Level: " + str(player.level)
	enemies_label.text = "Enemies: " + str(enemies_defeated) + "/" + str(total_enemies)

func play_music(track_name: String):
	# Load and play music track
	var music_path = "res://assets/music/" + track_name + ".ogg"
	if ResourceLoader.exists(music_path):
		var music = load(music_path)
		music_player.stream = music
		music_player.play()

func play_sfx(sound_name: String):
	# Load and play sound effect
	var sfx_path = "res://assets/sounds/" + sound_name + ".wav"
	if ResourceLoader.exists(sfx_path):
		var sfx = load(sfx_path)
		sfx_player.stream = sfx
		sfx_player.play()