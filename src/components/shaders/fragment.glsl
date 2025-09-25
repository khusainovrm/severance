// === fragment shader ===
uniform float u_time;
uniform vec3 u_color;
varying vec2 vUv;

// расстояние до круга
float sdCircle(vec2 uv, vec2 center, float r) {
    return length(uv - center) - r;
}

// простейший value noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f*f*(3.0-2.0*f);
    return mix(a, b, u.x) +
    (c - a)* u.y * (1.0 - u.x) +
    (d - b)* u.x * u.y;
}

void main() {
    vec2 uv = vUv;

    // === "лужа" кофе ===
    float dripLine = 0.01*u_time + 0.015*sin(uv.y*5.0 + u_time) + noise(uv*5.0 + u_time*0.1)*0.1;
    float fluidMask = step(uv.y, dripLine);

    // итоговый цвет
    vec3 col = mix(vec3(0.0), u_color, fluidMask);
    float alpha = fluidMask;

    gl_FragColor = vec4(col, alpha);
}
