shader_type canvas_item;
render_mode unshaded;

uniform float cutoff : hint_range(0.0,1.0);
uniform float smoothSize : hint_range(0.0, 1.0);
uniform sampler2D mask : hint_albedo;

void fragment(){
	float value=texture(mask,UV).r;
	float alpha=smoothstep(cutoff,cutoff+smoothSize,value*(1.0-smoothSize)+smoothSize);
	COLOR=vec4(COLOR.rgb,alpha);
}