const RED = 7.0 / 5.0;
const BLUE = 8.0 / 5.0;
const PI = radians(180);

override SQUARE = false;

struct input
{
    time: f32,
    mouse: vec2f,
    movement: f32
};

@group(0) @binding(1) var Texture: texture_2d<f32>;
@group(0) @binding(2) var<uniform> Input: input;
@group(0) @binding(3) var Sampler: sampler;

@vertex fn vertex(@builtin(vertex_index) index: u32) -> @builtin(position) vec4f
{
    return vec4f(GetQuadCoord(index), 0, 1);
}

@fragment fn fragment(@builtin(position) coord: vec4f) -> @location(0) vec4f
{
    // Compute position from pixel coordinates and canvas resolution:
    var position = coord.xy - resolution * 0.5;
    position.y = 1 - position.y;
    position /= resolution.y;

    // Mix mouse movement and clockwise camera rotation:
    position.x -= mix(cos(Input.time * 0.25) * 0.5, Input.mouse.x, Input.movement);
    position.y += mix(sin(Input.time * 0.25) * 0.25, Input.mouse.y, Input.movement);

    // Angle to the center of the screen:
    let angle = atan(position.y / position.x);

    // Cylindrical tunnel shape:
    var radius = length(position);

    // Squareish tunnel shape:
    if (SQUARE)
    {
        // https://www.shadertoy.com/view/Ms2SWW:
        let position2 = position * position;
        let position4 = position2 * position2;
        let position8 = position4 * position4;
        radius = pow(position8.x + position8.y, 0.125);
    }

    // Get texture UV by using radius and current angle:
    let uv = vec2f(0.25 / radius + Input.time * 0.2, angle / PI);

    // Discontinuity fix (https://iquilezles.org/articles/tunnel):
    let uvDer = vec2f(uv.x, atan(position.y / abs(position.x)) / PI);

    // Partial derivatives of `uv` with respect to window x and y coordinates:
    var color = textureSampleGrad(Texture, Sampler, uv, dpdx(uvDer), dpdy(uvDer)).xyz;

    // Matrix formula (https://www.youtube.com/shorts/r9tQu77XoGY):
    color = vec3f(pow(color.r, RED), color.g, pow(color.b, BLUE));

    // Circular vignette with a slight noise on screen borders:
    color = vignette(color * radius, coord.xy / resolution);

    return vec4f(color, 1);
}
