shader_type canvas_item;

// 0..1 wipe position
uniform float progress: hint_range(0.0, 1.0) = 0.0;
// The size of logical pixels in screen pixels
uniform float pixel_size = 4.0;
// A repeating dither texture (maybe blue noise?)
uniform sampler2D dither_tex: hint_default_white, filter_nearest, repeat_enable;
// The dimension of the dither texture in pixels
uniform float dither_tex_size = 32.0;
// Higher creates a sharper front and lower creates a fuzzier one
uniform float edge_multiplier = 5.0;

// Color to wipe from
uniform vec4 color_from: source_color = vec4(0.0, 0.0, 0.0, 1.0);
// The shadow color
uniform vec4 shadow_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
// The offset of the shadow in logical pixels
uniform vec2 shadow_offset = vec2(1.0, 1.0);

// Wipe direction in screen space, e.g. (1,0) is left to right, (0,1) is top to bottom, and (1,1) is diagonal TL to BR
uniform vec2 direction = vec2(1.0, 0.0);

float sample_dither(vec2 pixel_pos) {
    // Use texture with nearest filtering to preserve pixel look
    return texture(dither_tex, (pixel_pos + 0.5) / dither_tex_size).r;
}

float ease(float t) {
    return t * t * (3.0 - 2.0 * t);
}

void fragment() {
    vec2 uv = UV;
    vec2 pixel_pos = floor(uv / SCREEN_PIXEL_SIZE / pixel_size);
    vec2 quantized_uv = pixel_pos * pixel_size * SCREEN_PIXEL_SIZE + SCREEN_PIXEL_SIZE * 0.5;
    vec2 dir = normalize(direction);

    // Calculate the projected min and max positions for the screen corners in the wipe direction
    float min_proj = dot(vec2(0.0, 0.0), dir);
    float max_proj = dot(vec2(1.0, 1.0), dir);
    if (min_proj > max_proj) {
        float tmp = min_proj;
        min_proj = max_proj;
        max_proj = tmp;
    }

    // Project the pixel position onto the wipe direction and normalize to 0..1
    float pos = (dot(quantized_uv, dir) - min_proj) / (max_proj - min_proj);

    // Increase progress based on edge_multiplier so we go fully from 0 to 1 over the distance of the screen diagonal
    float adjusted_progress = progress + progress / edge_multiplier;

    float edge = clamp((adjusted_progress - pos) * edge_multiplier, 0.0, 1.0);
    float dither = sample_dither(pixel_pos) * (254. / 255.);

    // Shadow
    vec2 shadow_pixel_pos =  floor(uv / SCREEN_PIXEL_SIZE / pixel_size - shadow_offset);
    vec2 shadow_uv = shadow_pixel_pos * pixel_size * SCREEN_PIXEL_SIZE + SCREEN_PIXEL_SIZE * 0.5;
    float shadow_pos = (dot(shadow_uv, dir) - min_proj) / (max_proj - min_proj);
    float shadow_edge = clamp((adjusted_progress - shadow_pos) * edge_multiplier, 0.0, 1.0);
    float shadow_dither = sample_dither(shadow_pixel_pos) * (254. / 255.);

    if(dither < ease(edge)) {
        COLOR = color_from;
    } else if(shadow_dither < ease(shadow_edge)) {
        COLOR = shadow_color;
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}