"""Generates the raw AI images for the parallax backdrop with Stable Diffusion XL, locally
on the Mac's GPU (free; PLAN.md section 30). Run process_backgrounds.py afterwards to turn
them into game art.

Model: stabilityai/stable-diffusion-xl-base-1.0 (CreativeML Open RAIL++-M: commercial use of
outputs allowed, with its use restrictions) + madebyollin/sdxl-vae-fp16-fix (MIT), downloaded
once into the Hugging Face cache (~7 GB, ~/.cache/huggingface).

Usage (from the repo root):
    tools/art/.venv/bin/python tools/art/generate_ai_backgrounds.py            # all layers
    tools/art/.venv/bin/python tools/art/generate_ai_backgrounds.py mid near   # some layers
    tools/art/.venv/bin/python tools/art/generate_ai_backgrounds.py far --seed 7 --count 3

Raw images go to tools/art/raw/<layer>_<seed>.png (not committed). Prompts, seeds and the
model are listed here so every image can be reproduced and logged in ASSET_LICENSES.md.
Prompts must never name other games, studios or artists.
"""

import argparse
from pathlib import Path

import torch
from diffusers import AutoencoderKL, StableDiffusionXLPipeline

RAW_DIR = Path(__file__).with_name("raw")
MODEL = "stabilityai/stable-diffusion-xl-base-1.0"
VAE = "madebyollin/sdxl-vae-fp16-fix"
# Wide images (about 1 megapixel, SDXL's native size) so layers rarely repeat on screen.
WIDTH, HEIGHT = 1792, 576

NEGATIVE = (
    "text, letters, words, watermark, logo, signature, people, person, character, car, "
    "frame, border, blurry, lowres, jpeg artifacts, bright daylight, sun"
)

LAYERS = {
    "far": {
        "seed": 1101,
        "prompt": (
            "wide panoramic matte painting of a distant futuristic megacity skyline at night, "
            "heavy rain and fog, layered hazy skyscrapers fading into mist, cold teal and deep "
            "navy blue palette, a few warm amber lit windows, dark moody cloudy sky, atmospheric "
            "perspective, 2d side-scrolling game background"
        ),
    },
    "mid": {
        "seed": 2202,
        "prompt": (
            "side view of dark cyberpunk skyscrapers and towers in a row, neon signs, hanging "
            "cables, antennas, lit windows, rainy night, teal neon and a few warm amber lights, "
            "flat 2d side-scrolling game background layer, buildings standing on the bottom edge, "
            "isolated on a plain white background"
        ),
    },
    "near": {
        "seed": 3303,
        "prompt": (
            "side view silhouettes of city rooftops with water tanks, satellite dishes, pipes, "
            "vents and antennas, very dark near-black navy shapes, small red warning lights, "
            "flat 2d side-scrolling game foreground layer, shapes standing on the bottom edge, "
            "isolated on a plain white background"
        ),
    },
}


def load_pipeline() -> StableDiffusionXLPipeline:
    vae = AutoencoderKL.from_pretrained(VAE, torch_dtype=torch.float16)
    pipe = StableDiffusionXLPipeline.from_pretrained(
        MODEL, vae=vae, torch_dtype=torch.float16, variant="fp16", use_safetensors=True
    )
    device = "mps" if torch.backends.mps.is_available() else "cpu"
    pipe = pipe.to(device)
    pipe.enable_attention_slicing()
    return pipe


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("layers", nargs="*", default=list(LAYERS), choices=list(LAYERS))
    parser.add_argument("--seed", type=int, help="override the layer's seed")
    parser.add_argument("--count", type=int, default=1, help="images per layer (seed, seed+1, ...)")
    parser.add_argument("--steps", type=int, default=30)
    args = parser.parse_args()

    RAW_DIR.mkdir(exist_ok=True)
    pipe = load_pipeline()
    for name in args.layers:
        layer = LAYERS[name]
        first = args.seed if args.seed is not None else layer["seed"]
        for seed in range(first, first + args.count):
            generator = torch.Generator("cpu").manual_seed(seed)
            image = pipe(
                prompt=layer["prompt"],
                negative_prompt=NEGATIVE,
                width=WIDTH,
                height=HEIGHT,
                num_inference_steps=args.steps,
                guidance_scale=6.5,
                generator=generator,
            ).images[0]
            path = RAW_DIR / f"{name}_{seed}.png"
            image.save(path)
            print(f"wrote {path.relative_to(Path.cwd()) if path.is_relative_to(Path.cwd()) else path}", flush=True)


if __name__ == "__main__":
    main()
