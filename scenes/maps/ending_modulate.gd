extends CanvasModulate

@onready var player = get_tree().get_first_node_in_group("player")
@onready var strength_material: ShaderMaterial = $"../CanvasLayer/ShakeRect".material as ShaderMaterial

# Vibrant, strong crimson color
var crimson_color : Color = Color(1.0, 0.0, 0.1) 

# --- HORIZONTAL BOUNDARIES (Moving Right) ---
var start_x : float = -383.0
var max_x : float = 200.0 # -383 + 400 pixels of walking right

# --- VERTICAL BOUNDARIES (Moving Up) ---
var start_y : float = 32.0
var max_y : float = -600.0 # 32 - 400 pixels of climbing upward

var start_color : Color

func _ready():
	start_color = self.color

func _process(delta):
	if not player:
		return
		
	# 1. Calculate Horizontal Progress (X)
	var current_x = player.global_position.x
	var t_x : float = (current_x - start_x) / (max_x - start_x)
	t_x = clamp(t_x, 0.0, 1.0)
	
	# 2. Calculate Vertical Progress (Y)
	var current_y = player.global_position.y
	var t_y : float = (current_y - start_y) / (max_y - start_y)
	t_y = clamp(t_y, 0.0, 1.0)
	
	# 3. Combine them using maxf() 
	# Moving to the upper-right corner will smoothly drive this to 1.0
	var combined_t : float = maxf(t_x, t_y)
	
	# Apply the transition
	self.color = start_color.lerp(crimson_color, combined_t)
	strength_material.set_shader_parameter("ShakeStrength", combined_t)
