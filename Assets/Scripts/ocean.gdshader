shader_type spatial;
uniform float speed = 1.0;
uniform float wave_height = 1;
uniform vec4 shallow_color : source_color = vec4(0.0, 0.5, 1.0, 0.8);
uniform vec4 deep_color : source_color = vec4(0.0, 0.2, 0.6, 0.9);

void fragment() {
    float wave = sin(UV.x * 10.0 + TIME * speed) * 0.5 + 
                 sin(UV.y * 10.0 + TIME * speed * 1.2) * 0.5;
    ALBEDO = mix(shallow_color.rgb, deep_color.rgb, UV.y + wave * wave_height);
    ALPHA = shallow_color.a;
}
