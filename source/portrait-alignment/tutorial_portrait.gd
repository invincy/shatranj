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
 var environment=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_CLEAR_COLOR;environment.environment.background_color=Color("102326");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("eadfc9");environment.environment.ambient_light_energy=.9;stage.add_child(environment)
 var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,-35,0);key.light_energy=1.6;stage.add_child(key)
 var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,140,0);fill.light_energy=.9;stage.add_child(fill)
 var rim=DirectionalLight3D.new();rim.rotation_degrees=Vector3(-25,170,0);rim.light_color=Color("ffd386");rim.light_energy=1.1;stage.add_child(rim)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.position=Vector3(3,1.0,4);stage.add_child(camera);camera.look_at(Vector3(0,1.0,0));camera.current=true
 resized.connect(frame_model);resized.connect(queue_redraw)
func show_piece(piece:String,square:int):
 if is_instance_valid(model):stage.remove_child(model);model.queue_free()
 model=app._piece(piece,square);model.reparent(stage,false);model.position=Vector3.ZERO;model.rotation=Vector3(0,.15,0)
 animal=piece.to_lower() in ["r","b","n"]
 cycle=0;app._animate(model,"idle",.7);frame_model()
func frame_model():
 if not camera or not is_instance_valid(model):return
 camera.h_offset=0;camera.v_offset=0
 var lower=Vector2(INF,INF);var upper=Vector2(-INF,-INF)
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  var bounds:AABB=mesh.get_aabb()
  for i in range(8):
   var point:Vector3=camera.global_transform.affine_inverse()*mesh.global_transform*bounds.get_endpoint(i)
   lower=lower.min(Vector2(point.x,point.y));upper=upper.max(Vector2(point.x,point.y))
 if not is_finite(lower.x):return
 var ground:float=.038-camera.position.y
 var extent=upper-lower
 camera.size=maxf((upper.y-ground)*1.12,extent.x*size.y/maxf(size.x,1.0)*1.12)
 camera.h_offset=(lower.x+upper.x)*.5
 # Shared foot line, even when a wide animal needs extra headroom.
 camera.v_offset=ground+camera.size*.46
func _process(delta:float):
 if not is_instance_valid(model):return
 var previous=cycle
 cycle+=delta
 if cycle>12.0:cycle=0;app._animate(model,"idle",.7)
 elif cycle>2.0 and previous<=2.0:app._animate(model,"attack",.6)
 elif cycle>5.8 and previous<=5.8:app._animate(model,"idle",.7)
 # One lightweight character, lit separately; no repeated sound over the narration.
 model.rotation.y=.15+.18*sin(cycle*.6)
