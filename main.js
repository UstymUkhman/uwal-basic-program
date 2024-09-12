import { UWAL, Shaders, TEXTURE } from "uwal";
import Vignette from "/vignette.wgsl?raw";
import Tunnel from "/tunnel.wgsl?raw";
import Bricks from "/bricks.jpg";

const canvas = document.getElementById("scene");
let Renderer, resolutionBuffer, target = [0, 0], lastTime = -Infinity, hover = -1;
const clamp = (value, min = 0, max = 1) => Math.max(min, Math.min(value, max));

try
{
    Renderer = new (await UWAL.RenderPipeline(canvas));
}
catch (error)
{
    alert(error);
    canvas.style.width = canvas.width = innerWidth;
    canvas.style.height = canvas.height = innerHeight;
    canvas.style.background = "center / cover no-repeat url('./preview.jpg')";
}

function resize()
{
    Renderer.SetCanvasSize(innerWidth, innerHeight);
    resolutionBuffer = Renderer.ResolutionBuffer;
}

addEventListener("resize", resize, false); resize();

const over = () => hover = 1;
addEventListener("mouseover", over, false);

function move(event)
{
    target[0] = clamp((event.clientX / innerWidth - 0.5) * 1.25, -0.5, 0.5);
    target[1] = clamp((event.clientY / innerHeight - 0.5) / 1.25, -0.25, 0.25);
}

addEventListener("mousemove", move, false);

const out = () => hover = -1;
addEventListener("mouseout", out, false);

Renderer.CreatePipeline(
    Renderer.CreateShaderModule([
        Shaders.Quad,
        Shaders.Resolution,
        Vignette,
        Tunnel
    ])
);

const { buffer, Input: { time, mouse, movement } } =
    Renderer.CreateUniformBuffer("Input");

const bricks = new Image();
bricks.src = Bricks;

bricks.onload = async () =>
{
    const Texture = new (await UWAL.Texture(Renderer));
    const texture = Texture.CopyImageToTexture(bricks);

    const sampler = Texture.CreateSampler({
        addressModeUV: TEXTURE.ADDRESS.REPEAT
    });

    Renderer.SetBindGroups(
        Renderer.CreateBindGroup(
            Renderer.CreateBindGroupEntries([
                { buffer: resolutionBuffer },
                texture.createView(),
                { buffer },
                sampler
            ])
        )
    );

    requestAnimationFrame(render);
};

function render(timestamp)
{
    time[0] = timestamp / 1000;

    mouse[0] += (target[0] - mouse[0]) * 0.025;
    mouse[1] += (target[1] - mouse[1]) * 0.025;

    movement[0] += (time[0] - lastTime) * hover;
    movement[0] = clamp(movement[0], 0, 1);

    Renderer.WriteBuffer(buffer, time.buffer);
    Renderer.Render(6);

    lastTime = +(hover > 0 && movement[0] < 1) * 0.012;
    lastTime ||= +(hover < 0 && movement[0] > -1) * 0.015;

    requestAnimationFrame(render);
    lastTime += time[0];
}
