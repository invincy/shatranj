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
 var halo=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2(3.2,3.2);halo.mesh=quad
 var glow=GradientTexture2D.new();glow.width=128;glow.height=128;glow.fill=GradientTexture2D.FILL_RADIAL;glow.fill_from=Vector2(.5,.5);glow.fill_to=Vector2(.5,1)
 var gradient=Gradient.new();gradient.set_color(0,Color(.85,.59,.22,.7));gradient.set_color(1,Color(.85,.59,.22,0));glow.gradient=gradient
 var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.albedo_texture=glow;material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
 halo.material_override=material;halo.position=Vector3(-.8,.9,-1.3);halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;stage.add_child(halo)
 var environment=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("102326");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("eadfc9");environment.environment.ambient_light_energy=.9;stage.add_child(environment)
 var key=DirectionalLight3D.new();key.rotation_degrees=Vector3(-35,-35,0);key.light_energy=1.6;stage.add_child(key)
 var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-15,140,0);fill.light_energy=.9;stage.add_child(fill)
 var rim=DirectionalLight3D.new();rim.rotation_degrees=Vector3(-25,170,0);rim.light_color=Color("ffd386");rim.light_energy=1.1;stage.add_child(rim)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.position=Vector3(3,1.8,4);stage.add_child(camera);camera.look_at(Vector3(0,.85,0));camera.current=true
 resized.connect(frame_model);resized.connect(queue_redraw)
func show_piece(piece:String,square:int):
 if is_instance_valid(model):stage.remove_child(model);model.queue_free()
 model=app._piece(piece,square);model.reparent(stage,false);model.position=Vector3.ZERO;model.rotation=Vector3(0,.15,0)
 animal=piece.to_lower() in ["r","b","n"]
 cycle=0;app._animate(model,"idle",.7);frame_model()
func frame_model():
 if camera:camera.size=maxf(2.2 if animal else 1.65,(1.7 if animal else .85)*size.y/maxf(size.x,1.0))
func _process(delta:float):
 if not is_instance_valid(model):return
 var previous=cycle
 cycle+=delta
 if cycle>12.0:cycle=0;app._animate(model,"idle",.7)
 elif cycle>2.0 and previous<=2.0:app._animate(model,"attack",.6)
 elif cycle>5.8 and previous<=5.8:app._animate(model,"idle",.7)
 # One lightweight character, lit separately; no repeated sound over the narration.
 model.rotation.y=.15+.18*sin(cycle*.6)
