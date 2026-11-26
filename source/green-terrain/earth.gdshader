shader_type spatial;
uniform vec4 earth_color : source_color = vec4(.22,.24,.18,1.0);
uniform bool terrain=false;
varying vec3 ground_position;
void vertex() { ground_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
float grain(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(grain(i),grain(i+vec2(1,0)),f.x),mix(grain(i+vec2(0,1)),grain(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
 vec2 p=ground_position.xz;
 float coarse=noise(p*9.0);
 float fine=grain(floor(p*110.0));
 float track=smoothstep(.09,.16,abs(sin(p.x*2.3+sin(p.y*.7)*.15)));
 ALBEDO=earth_color.rgb*(.80+coarse*.16+fine*.12);
 if(terrain){
  float patch=noise(p*.45);
  float path=1.0-smoothstep(.35,1.1,abs(abs(p.x)-5.2));
  vec3 dirt=vec3(.025,.041,.026);
  ALBEDO=mix(ALBEDO*(.78+patch*.22),dirt,clamp(path*.55+patch*.16,0.0,.65));
 }
 ROUGHNESS=.98;
}
