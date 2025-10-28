extends Control

var dragging := false
var drag_offset := Vector2.ZERO

func _ready():
	get_window().borderless = true
	get_window().transparent = true
	get_window().always_on_top = true
	
	# Make background semi-transparent
	modulate.a = 0.85
	# Optionally make the whole window not clip the background
	mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event):
	# Handle dragging by clicking anywhere on the window (or only title bar)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = get_global_mouse_position() - global_position
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - drag_offset

func _on_CaptureButton_pressed():
	take_screenshot()

func take_screenshot():
	var img = get_viewport().get_texture().get_image()
	var path = "user://screenshot_%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
	img.save_png(path)
	print("✅ Saved:", path)

	# Update preview
	var tex = ImageTexture.create_from_image(img)
	$Preview.texture = tex
