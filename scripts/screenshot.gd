# TODO: Commandline arguments to start as screenshot utility
# TODO: Commandline arguments to start as gif taker (with status indicator)
# TODO: How to copy images to the clipboard?
# TODO: Allow for editing screenshot before saving/copying
# TODO: Test to see if it's possible to open the program multiple times.
# 		If it is, try to make it so only one instance can ever run.
# TODO: Create "options" for the application. When you start it normally
# 		it starts in the system tray and allows you to open the options
#		and change settings (e.g. save shortcut, cuztomiation, etc..)
# TODO: Use a date format by default for the filename (e.g. 2025-10-27_05-46a_gshot.png)
# 		The format can be configured in the options.

extends Control

@onready var file_dialog := FileDialog.new()

var screenshot: Image
var screenshot_texture: ImageTexture
var region_start = Vector2.ZERO
var region_end = Vector2.ZERO
var dragging = false

func _on_file_selected(path: String):
	var region_cap: bool = region_start > Vector2.ZERO or region_end > Vector2.ZERO
	img_capture(region_cap).save_png(path)
	get_tree().quit()

# Shortcut constants
func _input(event):
	if event is InputEventMouseButton:
		# Region selecting with your mouse
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				region_start = event.position
				region_end = event.position
			else:
				dragging = false
				queue_redraw()
				save_where()
				file_dialog.popup_centered()
	
	# Currently dragging, therefore keep resizing 
	# 	the selected region within draw()
	elif event is InputEventMouseMotion and dragging:
		region_end = event.position
		queue_redraw()
	
	# Shortcut inputs
	elif event is InputEventKey:
		# Quit application
		if event.is_action_pressed("Quit"):
			get_tree().quit()
			
		# Save entire desktop screenshot
		elif event.is_action_pressed("Save image"):
			queue_redraw()
			save_where()
			file_dialog.popup_centered()
		
		#elif event.is_action_pressed("Copy to clipboard"):
			#var region_cap = region_start > Vector2.ZERO or region_end > Vector2.ZERO
			#save_clipboard()
			#get_tree().quit()
		
# Responsible for basically drawing the screenshot on your screen.
func _draw():
	if screenshot_texture:
		draw_texture(screenshot_texture, Vector2.ZERO)
		
	# Draw dark overlay
	var screen_rect = Rect2(Vector2.ZERO, get_viewport_rect().size)
	var crop_rect = Rect2(region_start, region_end - region_start).abs()
	
	draw_rect(screen_rect, Color(0, 0, 0, 0.5))
	if file_dialog and file_dialog.visible:
		return
	
	if screenshot_texture and crop_rect.size.x > 0 and crop_rect.size.y > 0:
		draw_texture_rect_region(screenshot_texture, crop_rect, crop_rect)

# Application depends on you binding it to a shortcut to start
# e.g. press print screen to execute the utility.
func _ready():
	capture_screen()
	add_child(file_dialog)
	filedialog_configure()

func filedialog_configure():
	# Configure the dialog
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.mode = FileDialog.MODE_WINDOWED
	file_dialog.filters = ["*.png ; PNG Images"]
	
	file_dialog.current_file = "screenshot.png"
	file_dialog.connect("file_selected", Callable(self, "_on_file_selected"))
	file_dialog.connect("canceled", Callable(self, "_on_save_canceled"))

func capture_screen():
	screenshot = DisplayServer.screen_get_image(DisplayServer.MAIN_WINDOW_ID)
	screenshot_texture = ImageTexture.create_from_image(screenshot)

func img_capture(region: bool):
	if screenshot_texture == null:
		return
	var img = screenshot_texture.get_image()
	if img == null:
		return
		
	var rect
	if region:
		rect = Rect2(region_start, region_end - region_start).abs()
	else:
		rect = Rect2(Vector2.ZERO, img.get_size())
		

	# Clip to image bounds (optional safety)
	var img_size = img.get_size()
	rect.position = rect.position.clamp(Vector2.ZERO, img_size)
	rect.size.x = min(rect.size.x, img_size.x - rect.position.x)
	rect.size.y = min(rect.size.y, img_size.y - rect.position.y)

	# Extract region
	return img.get_region(rect)

func save_where():
	file_dialog.popup_centered()

func save_clipboard():
	pass
	#var bytes = screenshot.save_png_to_buffer()
	#DisplayServer.clipboard_set(bytes.get_string_from_utf8())

func quit_application():
	#get_tree().quit()
	OS.kill(OS.get_process_id())
