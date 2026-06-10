#!/usr/bin/env python3
"""
img_to_hex.py  —  Convert any image to data memory hex for RISC-V CPU
Usage: python3 img_to_hex.py <input_image> [max_size]
       max_size = longest edge in pixels (default 128, max ~200 for fast sim)
Output: image_in.hex, image_meta.txt   (put both in your sim/ folder)

NOTE: larger images = longer simulation time
  64x64   ~  280K cycles  ~ fast
  128x128 ~ 1.1M cycles   ~ few minutes in ModelSim
  256x256 ~ 4.5M cycles   ~ slow but works
"""
import sys, os
from PIL import Image

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 img_to_hex.py <image.jpg/png> [max_size]")
        sys.exit(1)

    img_path = sys.argv[1]
    max_size = int(sys.argv[2]) if len(sys.argv) > 2 else 128

    if not os.path.exists(img_path):
        print(f"Error: {img_path} not found")
        sys.exit(1)

    img = Image.open(img_path).convert("RGB")
    W0, H0 = img.size
    print(f"Loaded: {W0}x{H0} pixels from {img_path}")

    # Resize keeping aspect ratio
    scale = max_size / max(W0, H0)
    W = max(4, int(W0 * scale))
    H = max(4, int(H0 * scale))
    img = img.resize((W, H), Image.LANCZOS)
    print(f"Resized to: {W}x{H} = {W*H} pixels")
    print(f"Estimated sim cycles: ~{W*H*70:,}")

    pixels = list(img.getdata())
    N = W * H

    # Memory layout (65536 words = 256KB):
    # [0]     = W
    # [1]     = H
    # [2..N+1] = input pixels as 0x00RRGGBB
    # [0x4000..0x4000+N-1] = grayscale output (CPU writes here)
    # [0x8000..0x8000+N-1] = edge output (CPU writes here)
    # [0xC000..] = stack region (untouched)
    TOTAL_WORDS = 65536
    mem = [0] * TOTAL_WORDS
    mem[0] = W
    mem[1] = H
    for i, (r, g, b) in enumerate(pixels):
        mem[2 + i] = (r << 16) | (g << 8) | b

    with open("image_in.hex", "w") as f:
        for w in mem:
            f.write(f"{w:08x}\n")

    with open("image_meta.txt", "w") as f:
        f.write(f"{W} {H}\n")

    print(f"\nimage_in.hex written  ({TOTAL_WORDS} words)")
    print(f"image_meta.txt written ({W} {H})")
    print(f"\nNext steps:")
    print(f"  1. Copy image_in.hex and image_meta.txt to your sim/ folder")
    print(f"  2. Run ModelSim: do run_sim.do   (or use iverilog testbench)")
    print(f"  3. After sim: python3 hex_to_img.py image_out.hex image_meta.txt")

if __name__ == "__main__":
    main()
