extends SubViewportContainer
var app
var viewport3d:SubViewport
var stage:Node3D
var camera:Camera3D
var model:Node3D
var cycle:=0.0
var animal:=false
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE;stretch=true
 viewport3d=SubViewport.new();viewport3d.own_world_3d=true;viewport3d.transparent_bg=true;viewport3d.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport3d)
 stage=Node3D.new();viewport3d.add_child(stage)
 var environment=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("102326");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("eadfc9");environment.environment.ambient_light_energy=.65;stage.add_child(environment)
 var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,-35,0);key.light_energy=1.3;stage.add_child(key)
 var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,140,0);fill.light_energy=.5;stage.add_child(fill)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.position=Vector3(3,1.8,4);stage.add_child(camera);camera.look_at(Vector3(0,.85,0));camera.current=true
 resized.connect(frame_model)
func show_piece(piece:String,square:int):
 if is_instance_valid(model):stage.remove_child(model);model.queue_free()
 model=app._piece(piece,square);model.reparent(stage,false);model.position=Vector3.ZERO;model.rotation=Vector3(0,.15,0)
 animal=piece.to_lower() in ["r","b","n"]
 cycle=0;app._animate(model,"attack");frame_model()
func frame_model():
 if camera:camera.size=maxf(2.2 if animal else 1.65,(1.7 if animal else .85)*size.y/maxf(size.x,1.0))
func _process(delta:float):
 if not is_instance_valid(model):return
 var previous=cycle
 cycle+=delta
 if cycle>5.5:cycle=0;app._animate(model,"attack")
 elif cycle>1.8 and previous<=1.8:app._animate(model,"idle")
 # One lightweight character, lit separately; no repeated sound over the narration.
 model.rotation.y=.15+.18*sin(cycle*.6)
