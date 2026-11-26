extends RefCounted
## A board-readable L-shaped leap. Only presentation; rules still choose the square.
const Rig=preload("res://scripts/haathi_motion.gd")
static func travel_state(node: Node3D,target: Vector3,board_target: Vector3,duration: float,clearance: float) -> Dictionary:
 var rig=Rig.bind_rig(node);Rig.rest_pose(rig)
 var d=board_target-node.position
 var corner=node.position+ (Vector3(d.x,0,0) if absf(d.x)>absf(d.z) else Vector3(0,0,d.z))
 var first=corner-node.position;var second=target-corner
 return {"rig":rig,"start":node.position,"target":target,"corner":corner,"duration":duration,"yaw":node.rotation.y,"first_yaw":atan2(first.x,first.z),"last_yaw":atan2(second.x,second.z),"height":maxf(1.05,clearance),"footfalls":0}
static func travel_frame(elapsed: float,node: Node3D,state: Dictionary) -> void:
 var t=clampf(elapsed/state.duration,0,1);var rig: Dictionary=state.rig
 Rig.rest_pose(rig)
 if t>=1:
  node.position=state.target;node.rotation.y=state.last_yaw;state.footfalls=1
  node.set_meta("motion_phase","standing");return
 if t<.16:
  var p=Rig.smooth(t/.16)
  node.rotation.y=state.yaw+wrapf(state.first_yaw-state.yaw,-PI,PI)*p
  node.position=state.start
  crouch(rig,sin(p*PI)*.045)
  node.set_meta("motion_phase","anticipation")
 elif t<.86:
  var p=(t-.16)/.70
  # Long leg first, then the short leg. Ease to the corner while airborne.
  if p<.55:node.position=state.start.lerp(state.corner,Rig.smooth(p/.55))
  elif p<.70:node.position=state.corner
  else:node.position=state.corner.lerp(state.target,Rig.smooth((p-.70)/.30))
  node.position.y=lerpf(state.start.y,state.target.y,p)+state.height*pow(sin(p*PI),.65)
  node.rotation.y=state.first_yaw+wrapf(state.last_yaw-state.first_yaw,-PI,PI)*Rig.smooth((p-.55)/.15)
  var tuck=sin(p*PI)
  for suffix in Rig.FEET:
   var foot: Transform3D=rig.skeleton.global_transform*rig.rest["foot_"+suffix]
   foot.origin+=Vector3.UP*.18*tuck
   Rig.place_foot(rig,suffix,foot)
  var body: Transform3D=rig.skeleton.get_bone_global_pose(rig.bones.body)
  body.basis=body.basis*Basis(Vector3.RIGHT,-.10*sin(p*TAU))
  rig.skeleton.set_bone_global_pose(rig.bones.body,body)
  node.set_meta("motion_phase","airborne")
 else:
  var p=(t-.86)/.14
  node.position=state.target;node.rotation.y=state.last_yaw
  crouch(rig,sin(p*PI)*.045)
  state.footfalls=1;node.set_meta("motion_phase","landing")

static func crouch(rig: Dictionary,amount: float) -> void:
 var feet=Rig.rest_feet(rig)
 var body: Transform3D=rig.rest.body;body.origin.y-=amount
 rig.skeleton.set_bone_global_pose(rig.bones.body,body)
 for suffix in Rig.FEET: Rig.place_foot(rig,suffix,feet[suffix])
