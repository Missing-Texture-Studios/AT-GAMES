shader_type canvas_item;

uniform float strength = 1.5;
uniform float speed = 8.0;

// Simple pseudo-random function
float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	// Each character quad has a different center position
	vec2 id = floor(VERTEX.xy / 4.0);

	// Time snapping creates "frame-by-frame" jitter
	float t = floor(TIME * speed);

	// Random offsets
	float offset_x = rand(id + t) - 0.5;
	float offset_y = rand(id + t + 13.37) - 0.5;

	VERTEX.xy += vec2(offset_x, offset_y) * strength;
}