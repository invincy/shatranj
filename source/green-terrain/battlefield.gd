extends RefCounted
const C=preload("res://scripts/stone_court.gd")
const CLOTH=preload("res://scripts/camp_cloth.gdshader")

static func cloth(color: String,banner := false) -> ShaderMaterial:
 var m=ShaderMaterial.new(); m.shader=CLOTH; m.set_shader_parameter("cloth_color",Color(color)); m.set_shader_parameter("banner",banner); m.set_shader_parameter("wind",.055 if banner else 0.0); return m

static func surface(parent: Node3D,vertices: Array,uvs: Array,mat: Material) -> void:
 var batches: Dictionary=parent.get_meta("surface_batches",{})
 var key=mat.get_instance_id()
 if not batches.has(key): batches[key]={"vertices":[],"uvs":[],"material":mat}
 batches[key].vertices.append_array(vertices);batches[key].uvs.append_array(uvs)
 parent.set_meta("surface_batches",batches)

static func flush_surfaces(parent: Node3D) -> void:
 for child in parent.get_children():
  if child is Node3D:flush_surfaces(child)
 for batch in parent.get_meta("surface_batches",{}).values():
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(0)
  for i in range(batch.vertices.size()):st.set_uv(batch.uvs[i]);st.add_vertex(batch.vertices[i])
  st.generate_normals();var mesh=MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=batch.material;parent.add_child(mesh)
 if parent.has_meta("surface_batches"):parent.remove_meta("surface_batches")

static func quad(parent: Node3D,a: Vector3,b: Vector3,c: Vector3,d: Vector3,mat: Material) -> void:
 surface(parent,[a,b,c,a,c,d],[Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)],mat)

static func rod(parent: Node3D,a: Vector3,b: Vector3,r: float,mat: Material) -> void:
 var ob=C.cylinder(parent,(a+b)*.5,r,a.distance_to(b),mat)
 ob.quaternion=Quaternion(Vector3.UP,(b-a).normalized())

static func pavilion(parent: Node3D,pos: Vector3,r: float,height: float,royal: bool,green := false,facing := 0.0) -> void:
 var tent=Node3D.new(); tent.position=pos; tent.rotation.y=facing; tent.name="GreenPavilion" if green else "RedPavilion"; parent.add_child(tent)
 var red=cloth("24533e" if green else "641f24"); var cream=cloth("8d7a5f"); var gold=C.material(Color("a87d37"),.45); var timber=C.material(Color("392c20")); var rope=C.material(Color("77664a"))
 var n=96; var roof=height*.68
 # Curved roof gores: supported seams and sagging fabric between poles.
 for i in range(n):
  var a=TAU*i/n; var b=TAU*(i+1)/n
  var mat=red if int(i/8)%3!=2 else cream
  for j in range(12):
   var points=[]
   for v in [Vector2(a,j/12.0),Vector2(b,j/12.0),Vector2(b,(j+1)/12.0),Vector2(a,(j+1)/12.0)]:
    var radius=r*v.y
    var y=height-(height-roof)*pow(v.y,.62)-.08*sin(v.x*12)*v.y
    points.append(Vector3(sin(v.x)*radius,y,cos(v.x)*radius))
   quad(tent,points[0],points[1],points[2],points[3],mat)
  # Leave the entrance open and pleat the side walls.
  if cos(a)<.85:
   var ra=r+.045*sin(a*48);var rb=r+.045*sin(b*48)
   quad(tent,Vector3(sin(a)*ra,roof,cos(a)*ra),Vector3(sin(b)*rb,roof,cos(b)*rb),Vector3(sin(b)*rb,0,cos(b)*rb),Vector3(sin(a)*ra,0,cos(a)*ra),red)
  var y=roof-.18-.1*sin((i%8)/8.0*PI)
  quad(tent,Vector3(sin(a)*r,roof,cos(a)*r),Vector3(sin(b)*r,roof,cos(b)*r),Vector3(sin(b)*r,y,cos(b)*r),Vector3(sin(a)*r,y,cos(a)*r),gold)
 for i in range(12):
  var a=TAU*i/12
  var edge=Vector3(sin(a)*r,roof,cos(a)*r)
  rod(tent,Vector3(edge.x,0,edge.z),edge,.035,timber)
  rod(tent,edge,Vector3(sin(a)*(r+.7),-.05,cos(a)*(r+.7)),.012,rope)
 rod(tent,Vector3(0,0,0),Vector3(0,height+.5,0),.045,gold)
 C.cylinder(tent,Vector3(0,height+.35,0),.1,.3,gold,0)
 # Tied entrance curtains with gathered folds.
 for side in [-1,1]:
  for i in range(18):
   var y0=roof*i/18.0;var y1=roof*(i+1)/18.0
   var x0=side*(r*.52-.23*sin(PI*i/18.0));var x1=side*(r*.52-.23*sin(PI*(i+1)/18.0))
   quad(tent,Vector3(x0-.22,y0,r*.85),Vector3(x0+.22,y0,r*.85+.08),Vector3(x1+.22,y1,r*.85+.08),Vector3(x1-.22,y1,r*.85),red)
 if royal:
  C.box(tent,Vector3(1.3,.18,1.3),Vector3(0,.08,.25),timber)
  C.box(tent,Vector3(.8,1.35,.12),Vector3(0,.8,-.15),gold)
  C.box(tent,Vector3(.8,.15,.7),Vector3(0,.5,.15),red)
  for x in [-.48,.48]: C.cylinder(tent,Vector3(x,.46,.25),.055,.9,gold)

static func banner(parent: Node3D,pos: Vector3,green: bool) -> void:
 var gold=C.material(Color("ac843e"),.5); var pole=C.material(Color("49372a")); var m=cloth("243f35" if green else "651c25",true)
 rod(parent,pos,pos+Vector3(0,3.7,0),.035,pole)
 rod(parent,pos+Vector3(-.55,3.3,0),pos+Vector3(.55,3.3,0),.025,gold)
 C.cylinder(parent,pos+Vector3(0,3.77,0),.1,.3,gold,0)
 var verts=[];var uvs=[]
 for x in range(16):
  for y in range(24):
   for ij in [Vector2(x,y),Vector2(x+1,y),Vector2(x+1,y+1),Vector2(x,y),Vector2(x+1,y+1),Vector2(x,y+1)]:
    var u=ij.x/16;var v=ij.y/24;var bottom=.25*(1.0-abs(u-.5)*2.0)*pow(v,8)
    verts.append(pos+Vector3((u-.5)*1.05,3.25-v*1.9+bottom,.10*sin(u*PI*4+v*2)*v));uvs.append(Vector2(u,v))
 surface(parent,verts,uvs,m)

static func ridge(parent: Node3D,z: float,height: float,color: String,seed_value: int) -> void:
 var noise=FastNoiseLite.new(); noise.seed=seed_value;noise.frequency=.035
 var verts=[];var uvs=[]
 for x in range(80):
  for depth in range(12):
   for ij in [Vector2(x,depth),Vector2(x+1,depth),Vector2(x+1,depth+1),Vector2(x,depth),Vector2(x+1,depth+1),Vector2(x,depth+1)]:
    var xx=ij.x-40;var zz=z-ij.y*1.8
    var h=pow(sin(PI*ij.y/12),.8)*(height+noise.get_noise_2d(xx*1.8,zz)*height*.9)
    verts.append(Vector3(xx,h-.6,zz));uvs.append(Vector2(xx,zz))
 for i in range(0,verts.size(),3):
  var tmp=verts[i+1];verts[i+1]=verts[i+2];verts[i+2]=tmp
 surface(parent,verts,uvs,C.material(Color(color)))

static func fort(parent: Node3D) -> void:
 var root=Node3D.new();root.position=Vector3(13,2.2,-34);root.scale=Vector3.ONE*.58;parent.add_child(root)
 var stone=C.material(Color("514a3b"));var trim=C.material(Color("82745d"))
 C.box(root,Vector3(9,3,3),Vector3(0,1.2,0),stone)
 for x in [-4.5,4.5]:
  C.cylinder(root,Vector3(x,1.6,.3),1.0,4.2,stone)
  C.cylinder(root,Vector3(x,3.8,.3),1.15,.25,trim)
  for i in range(12):
   var a=TAU*i/12;C.box(root,Vector3(.28,.55,.28),Vector3(x+cos(a)*1,4.1,.3+sin(a)*1),stone)
 for x in range(-4,5): C.box(root,Vector3(.4,.6,.45),Vector3(x,3.0,1.4),stone)
 C.box(root,Vector3(2.6,3,2),Vector3(0,3,-.5),stone)
 C.cylinder(root,Vector3(0,4.8,-.5),1.5,.45,trim)
 var dome=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=1.15;sphere.height=2.3;dome.mesh=sphere;dome.scale.y=.65;dome.position=Vector3(0,5,-.5);dome.material_override=trim;root.add_child(dome)
 banner(root,Vector3(0,5.7,-.5),false)

static func grass(parent: Node3D) -> void:
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rng=RandomNumberGenerator.new();rng.seed=2511
 for i in range(2400):
  var x=rng.randf_range(-18,18);var z=rng.randf_range(-20,20)
  if absf(x)<4.9 and absf(z)<5.1:continue
  if absf(absf(x)-5.2)<.65:continue
  if absf(x)<3.7 and z< -7:continue
  var h=rng.randf_range(.09,.3);var w=.025
  st.set_color(Color("3d5635") if i%3 else Color("53663c"))
  for a in [0.0,1.1,2.2]:
   var edge=Vector3(cos(a)*w,0,sin(a)*w);var base=Vector3(x,-.46,z)
   for v in [base-edge,base+edge,base+Vector3(.04,h,.01)]:st.add_vertex(v)
 st.generate_normals();var mesh=MeshInstance3D.new();mesh.mesh=st.commit()
 var m=StandardMaterial3D.new();m.vertex_color_use_as_albedo=true;m.cull_mode=BaseMaterial3D.CULL_DISABLED;m.roughness=1
 mesh.material_override=m;parent.add_child(mesh)

static func brazier(parent: Node3D,pos: Vector3) -> void:
 var stone=C.material(Color("5c5546"));var metal=C.material(Color("59442a"),.6)
 C.box(parent,Vector3(.65,.8,.65),pos+Vector3(0,.4,0),stone)
 C.box(parent,Vector3(.8,.12,.8),pos+Vector3(0,.86,0),stone)
 C.cylinder(parent,pos+Vector3(0,1.04,0),.25,.26,metal,.45)
 var fire=C.material(Color("e6a132"));fire.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;fire.emission_enabled=true;fire.emission=Color("ee7926")
 for offset in [-.13,0,.13]:
  var ob=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=.11;sphere.height=.42
  ob.mesh=sphere;ob.position=pos+Vector3(offset,1.35+absf(offset),0);ob.material_override=fire;parent.add_child(ob)

static func build(parent: Node3D) -> Node3D:
 var field=Node3D.new();field.name="Battlefield";parent.add_child(field)
 var earth=ShaderMaterial.new();earth.shader=preload("res://scripts/earth.gdshader");earth.set_shader_parameter("earth_color",Color("294b34")); earth.set_shader_parameter("terrain",true)
 C.box(field,Vector3(160,.16,160),Vector3(0,-.55,0),earth)
 ridge(field,-48,5.5,"34464b",21);ridge(field,-36,3.5,"2c3c32",48);ridge(field,-28,2.2,"28341f",88)
 var hill=MeshInstance3D.new(); var hillmesh=SphereMesh.new(); hillmesh.radius=1;hillmesh.height=2;hillmesh.radial_segments=48;hillmesh.rings=24
 hill.mesh=hillmesh;hill.position=Vector3(13,-1.8,-34);hill.scale=Vector3(8,4.5,5);hill.material_override=C.material(Color("28341f"));field.add_child(hill)
 fort(field)
 pavilion(field,Vector3(0,-.44,-11),3.2,5.0,true,true)
 pavilion(field,Vector3(0,-.44,11),3.2,5.0,true,false,PI)
 for x in [-8.0,8.0]:
  pavilion(field,Vector3(x,-.44,-10),1.9,3.2,false,true)
  pavilion(field,Vector3(x,-.44,10),1.9,3.2,false,false,PI)
  pavilion(field,Vector3(x*.9,-.44,2.8),1.8,3.4,true,false,PI)
  pavilion(field,Vector3(x*1.5,-.44,-14),2.1,3.4,false,true)
 for x in [-4.4,4.4]:
  pavilion(field,Vector3(x,-.44,7.5),1.1,1.9,false,false,PI)
 for x in [-5.4,5.4]:
  banner(field,Vector3(x,-.4,-6.1),true);banner(field,Vector3(x,-.4,4.8),false)
 var timber=C.material(Color("4c3827"));var iron=C.material(Color("353936"),.55)
 grass(field)
 stones(field)
 for x in [-5.7,5.7]: brazier(field,Vector3(x,-.44,3.2))
 for x in [-6.8,6.8]:
  for z in [-7.0,-6.0,6.0,7.0]:
   C.box(field,Vector3(.7,.6,.65),Vector3(x,-.12,z),timber)
   for plank in [-.2,0,.2]: C.box(field,Vector3(.015,.54,.68),Vector3(x+plank,-.12,z),iron)
   for y in [-.32,.12]:C.box(field,Vector3(.74,.06,.69),Vector3(x,y,z),iron)
 var atmosphere=preload("res://scripts/battlefield_atmosphere.gd").new();field.add_child(atmosphere)
 flush_surfaces(field)
 return field

static func stones(parent:Node3D)->void:
 var instances=MultiMeshInstance3D.new();instances.name="ScatteredMossStones"
 var batch=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true
 var rock=SphereMesh.new();rock.radius=1;rock.height=2;rock.radial_segments=7;rock.rings=3
 batch.mesh=rock;batch.instance_count=520
 var rng=RandomNumberGenerator.new();rng.seed=261126
 for i in range(520):
  var pos=Vector3.ZERO
  while absf(pos.x)<5.0 and absf(pos.z)<5.2:pos=Vector3(rng.randf_range(-17,17),-.43,rng.randf_range(-18,18))
  var scale=Vector3(rng.randf_range(.07,.24),rng.randf_range(.035,.12),rng.randf_range(.06,.20))
  var basis=Basis.from_euler(Vector3(0,rng.randf_range(0,TAU),rng.randf_range(-.18,.18))).scaled(scale)
  batch.set_instance_transform(i,Transform3D(basis,pos))
  batch.set_instance_color(i,Color("73786a").lerp(Color("3f4d3d"),rng.randf()).srgb_to_linear())
 var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=.95
 instances.multimesh=batch;instances.material_override=mat;instances.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(instances)
