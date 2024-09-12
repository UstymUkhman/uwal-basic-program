fn random(uv: vec2f) -> f32
{
    return fract(sin(dot(uv, vec2f(12.9898, 78.233))) * 43758.5453);
}

fn blend(base: vec3f, factor: vec3f) -> vec3f
{
    return mix(
        1 - 2 * (1 - base) * (1 - factor),
        2 * base * factor, step(base, vec3f(0.5))
    );
}

fn vignette(col: vec3f, uv: vec2f) -> vec3f
{
    var position = uv - 0.5;
    position.x *= resolution.x / resolution.y;

    var color = mix(vec3f(0.0), col, smoothstep(
        -0.25, 0.5, 1 - length(position)
    ));

    return mix(
        color,
        blend(
            color,
            vec3f(
                random(uv * 0.1),
                random(uv * 2.5),
                random(uv)
            )
        ),
        0.025
    );
}
