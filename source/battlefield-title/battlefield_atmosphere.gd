extends Node3D
const C=preload("res://scripts/stone_court.gd")
var wisps:Array[MeshInstance3D]=[]
var clock:=0.0
func _ready():
 var texture=smoke_texture()
 for pos in [Vector3(-6.5,.1,-5.5),Vector3(6.3,.1,-7),Vector3(-7.7,.1,2.4),Vector3(6.9,.1,4.4)]:
  var smoke=CPUParticles3D.new();smoke.name="CampSmoke";smoke.amount=12;smoke.lifetime=9;smoke.preprocess=9;smoke.position=pos;smoke.direction=Vector3.UP;smoke.spread=22;smoke.gravity=Vector3(.035,.015,0);smoke.initial_velocity_min=.16;smoke.initial_velocity_max=.32;smoke.scale_amount_min=.8;smoke.scale_amount_max=1.7;smoke.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE;smoke.emission_sphere_radius=.28
  var mesh=QuadMesh.new();mesh.size=Vector2(2.2,2.2);smoke.mesh=mesh
  var mat=StandardMaterial3D.new();mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES;mat.albedo_texture=texture;mat.vertex_color_use_as_albedo=true;mat.albedo_color=Color(.68,.69,.65,.32);mat.no_depth_test=false;smoke.material_override=mat;smoke.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var gradient=Gradient.new();gradient.set_color(0,Color(1,1,1,0));gradient.set_color(1,Color(1,1,1,0));gradient.add_point(.18,Color(1,1,1,.8));gradient.add_point(.6,Color(1,1,1,.45));smoke.color_ramp=gradient;add_child(smoke)
 for x in [-6.2,6.2]:
  for z in [-3.0,2.0]:
   var mist=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2(4,1.1);mist.mesh=quad;mist.position=Vector3(x,.15,z)
   var mat=StandardMaterial3D.new();mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;mat.albedo_texture=texture;mat.albedo_color=Color(.65,.7,.68,.17);mist.material_override=mat;mist.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(mist);wisps.append(mist)
 debris()
func smoke_texture()->ImageTexture:
 var image=Image.create(64,64,false,Image.FORMAT_RGBA8);var noise=FastNoiseLite.new();noise.seed=812;noise.frequency=.09
 for y in range(64):
  for x in range(64):
   var radius=Vector2(x-31.5,y-31.5).length()/31.5
   var alpha=pow(maxf(0,1-radius*radius),2)*(noise.get_noise_2d(x,y)*.35+.65)
   image.set_pixel(x,y,Color(1,1,1,alpha))
 return ImageTexture.create_from_image(image)
func debris():
 var wood=C.material(Color("493827"));var iron=C.material(Color("69685c"),.65);var gold=C.material(Color("9e7c3e"),.55);var leather=C.material(Color("342c24"))
 for side in [-1,1]:
  var pile=Node3D.new();pile.position=Vector3(side*6.1,-.42,side*1.5);pile.rotation.y=side*.5;add_child(pile)
  # Splintered cart rails and a fallen wheel, outside all playable squares.
  for i in range(5):
   var plank=C.box(pile,Vector3(.13,.10,1.2+i*.16),Vector3((i-2)*.2,.08+i*.035,0),wood);plank.rotation.y=(i-2)*.33
  var wheel=Node3D.new();wheel.position=Vector3(.8,.18,.2);wheel.rotation_degrees=Vector3(18,0,70);pile.add_child(wheel)
  var rim=MeshInstance3D.new();var torus=TorusMesh.new();torus.inner_radius=.44;torus.outer_radius=.52;torus.rings=16;torus.ring_segments=8;rim.mesh=torus;rim.material_override=wood;wheel.add_child(rim)
  for i in range(6):
   var spoke=C.box(wheel,Vector3(.04,.05,.95),Vector3.ZERO,wood);spoke.rotation.y=i*PI/6
  for i in range(3):
   var sword=Node3D.new();sword.position=Vector3(-.8+i*.5,.11,.8+i*.3);sword.rotation.y=.5+i*1.7;pile.add_child(sword)
   C.box(sword,Vector3(.085,.025,.75),Vector3(0,0,-.2),iron);C.box(sword,Vector3(.32,.045,.05),Vector3(0,0,.2),gold);C.box(sword,Vector3(.06,.04,.23),Vector3(0,0,.34),leather)
  var shield=C.cylinder(pile,Vector3(-.7,.13,-.7),.34,.055,iron);shield.rotation_degrees=Vector3(12,0,8)
  C.cylinder(pile,Vector3(-.7,.18,-.7),.08,.06,gold)
func _process(delta:float):
 if not is_visible_in_tree():return
 clock+=delta
 for i in range(wisps.size()):
  wisps[i].position.x=(-6.2 if i<2 else 6.2)+sin(clock*.12+i)*.35
