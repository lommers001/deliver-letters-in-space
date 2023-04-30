shader_type canvas_item;

uniform float offset = 0.0;
uniform float multiplier;

void fragment() {
    float u = offset * multiplier * TEXTURE_PIXEL_SIZE.x * TIME;
    COLOR = texture(TEXTURE, vec2(UV.x, UV.y + u));
}