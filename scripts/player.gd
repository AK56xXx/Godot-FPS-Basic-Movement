extends CharacterBody3D

# Movement speed
var current_speed = 5.0
var walking_speed = 5.0
var sprinting_speed = 7.5
var crouching_speed = 3

# Movement states
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

# Slide variables
var slide_timer = 0.0
var slider_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0

 



# Movement variables
var lerp_speed = 10
var jump_velocity = 4.5
var crouching_depth = -0.5
var free_look_tilt_amount = 5


# Input directions variables
var mouse_sens = 0.15
var direction = Vector3.ZERO

#drag and drop than press ctrl
# Nodes variables
@onready var head = $neck/head
@onready var neck = $neck
@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $neck/head/Camera3D



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _input(event):
	
	# Mouse movement logic
	
	if event is InputEventMouseMotion:
		# Free looking mode
		if free_looking:
			#rotating the neck ( - to invert the rotation to normal rotation)
			neck.rotate_y(- deg_to_rad(event.relative.x * mouse_sens))
			#the limit of neck rotation to prevent 180° rotation
			neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-90),deg_to_rad(90))
		
		else:
			# Normal rotation mode
			#degrees to radiance conversion needed : deg_to_rad
			# - to invert the rotation of right and left for X axis 
			rotate_y(- deg_to_rad(event.relative.x * mouse_sens))
			head.rotate_x(deg_to_rad(event.relative.y * mouse_sens))
			#the limit of the rotation up and down to prevent 180° rotation
			head.rotation.x = clamp(head.rotation.x,deg_to_rad(-90),deg_to_rad(90))
		
		
		

func _physics_process(delta):
	# handle movement states
	
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	
	
	# Crouching
	# or couching and sliding
	if Input.is_action_pressed("crouch") || sliding:
		current_speed = crouching_speed
		#lerp needed for smooth crouching
		head.position.y = lerp(head.position.y,crouching_depth,delta*lerp_speed)
		#enabling crouching collision
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		# Sliding
		
		#sprinting when crouching = sliding
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slider_timer_max
			slide_vector = input_dir
			free_looking = true
			print("Slide begin .. !") 
		
		walking = false
		sprinting = false
		crouching = true
		
		
		
	elif !ray_cast_3d.is_colliding():
		#ray cast 3d under the player node help us detect the collision to prevent gliches
		
		# Standing
		
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, 0.0 , delta*lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			
			# Sprinting
			
			current_speed = sprinting_speed
			
			walking = false
			sprinting = true
			crouching = false
		else:
			current_speed = walking_speed
			
			walking = true
			sprinting = false
			crouching = false
			
			
			
	# Handling free looking
	
	if Input.is_action_pressed("free_look") || sliding:
		
		free_looking = true
		
		#adding camera tilt
		camera_3d.rotation.z = deg_to_rad(neck.rotation.y * free_look_tilt_amount)
	else:
		free_looking = false
		#intialise the neck default position after looking around
		#neck.rotation.y = 0.0
		#it works but we need to make it smooth so we will add lerp function and delta time
		neck.rotation.y = lerp(neck.rotation.y,0.0,delta*lerp_speed)
		#intialise the camera default position after looking around
		camera_3d.rotation.z = lerp(camera_3d.rotation.z,0.0,delta*lerp_speed)
	
	
	# Handle sliding
	
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0 :
			sliding = false
			free_looking = false
			print("Slide end.") 
	
	
	
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	
	#ray cast 3d detect the collision to prevent gliches when crouching and jumping
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !ray_cast_3d.is_colliding():
		velocity.y = jump_velocity
		
		#jump to stop the slide
		if sliding:
			sliding = false
			print("Slide stop")

	# Get the input direction and handle the movement/deceleration.
	
	#lerp needed for smooth movement
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta * lerp_speed)
	
	# Sliding direction (*)
	if sliding:
		direction = (transform.basis *  Vector3(slide_vector.x,0,slide_vector.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		#sliding duration and speed
		if sliding:
			# value 0.1 to add smooth at the end of the slide 
			velocity.x = direction.x * (slide_timer + 0.5 ) * slide_speed
			velocity.z = direction.z * (slide_timer + 0.5 ) * slide_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
