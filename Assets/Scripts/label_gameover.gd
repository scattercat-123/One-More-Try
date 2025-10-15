extends Label

@export var messages: Array[String] = [
	"imagine losing 
	here 💀",
	"skill issue fr",
	"this game’s
	 good right?",
	"bro thought he 
	could win 😭",
	"get better lol",
	"try again, maybe 
	survive 2 more
	seconds"
]

var current_text := ""
var target_text := ""
var deleting := false

func _ready():
	randomize()
	_set_new_message()

func _set_new_message():
	target_text = messages[randi() % messages.size()]
	current_text = text
	deleting = true
	_delete_text()

func _delete_text():
	if current_text.length() > 0:
		current_text = current_text.substr(0, current_text.length() - 1)
		text = current_text
		await get_tree().create_timer(0.05).timeout
		_delete_text()
	else:
		await get_tree().create_timer(0.3).timeout
		_type_text()

func _type_text():
	if text.length() < target_text.length():
		text += target_text[text.length()]
		await get_tree().create_timer(0.05).timeout
		_type_text()
	else:
		await get_tree().create_timer(2.0).timeout
		_set_new_message()
