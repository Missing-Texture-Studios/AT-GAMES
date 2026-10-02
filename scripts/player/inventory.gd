extends Control
@onready var player = get_tree().get_first_node_in_group("player")
@onready var item_list: ItemList = $Panel/ItemList
@onready var animation_player: AnimationPlayer = $AnimationPlayer
enum state {OPEN,CLOSED}
var estado_atual = state.CLOSED
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed('inventory') and !	animation_player.is_playing():
		toggleInv()

func toggleInv():
	if !player.can_move:
		return
		
	if estado_atual == state.CLOSED:
		# Loop through the objects in your player's inventory
		for item in player.inventory:
			# Find the item data inside ItemListGlobal using a loop instead of index
			var global_data = null
			for g_item in ItemListGlobal.items:
				if g_item.ID == item.ItemID: # Assumes your global items have an '.id' property
					global_data = g_item
					break
			
			# Fallback check just in case the ItemID doesn't exist in your database
			if global_data != null:
				var item_name = global_data.Name + " x" + str(item.item_amount) + " "
				var item_icon = load(global_data.Icon)
				item_list.add_item(item_name, item_icon)
				
		visible = true
		get_tree().paused = true
		animation_player.play("Open")
		await animation_player.animation_finished
		estado_atual = state.OPEN
	else:
		item_list.clear() # CRITICAL: Clears the UI so items don't stack up next time you open it
		get_tree().paused = false
		animation_player.play("Close")
		await animation_player.animation_finished
		visible = false
		estado_atual = state.CLOSED
