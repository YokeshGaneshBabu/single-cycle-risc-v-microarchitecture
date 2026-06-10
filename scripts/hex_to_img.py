#!/usr/bin/env python3
"""
hex_to_img.py  —  Reconstruct processed images from CPU memory dump
Usage: python3 hex_to_img.py image_out.hex image_meta.txt
Output: original.png, grayscale.png, edges.png
"""
import sys
from PIL import Image

def main():
    hex_file  = sys.argv[1] if len(sys.argv) > 1 else "image_out.hex"
    meta_file = sys.argv[2] if len(sys.argv) > 2 else "image_meta.txt"

    with open(meta_file) as f:
        W, H = map(int, f.read().split())

    with open(hex_file) as f:
        mem = [int(l.strip(), 16) for l in f if l.strip()]

    N = W * H
    print(f"Image: {W}x{H} = {N} pixels")

    # Input region: words 2..(N+1)
    orig = Image.new("RGB", (W, H))
    orig_pix = [((mem[2+i]>>16)&0xFF, (mem[2+i]>>8)&0xFF, mem[2+i]&0xFF)
                for i in range(N)]
    orig.putdata(orig_pix)
    orig.save("original.png")
    print("original.png saved")

    # Grayscale: GRAY_BASE = 0x10000 → word offset 0x4000
    GW = 0x10000 // 4
    gray = Image.new("L", (W, H))
    gray.putdata([min(255, mem[GW+i] & 0xFF) for i in range(N)])
    gray.save("grayscale.png")
    print("grayscale.png saved")

    # Sobel edges: EDGE_BASE = 0x20000 → word offset 0x8000
    EW = 0x20000 // 4
    edge = Image.new("L", (W, H))
    edge.putdata([min(255, mem[EW+i] & 0xFF) for i in range(N)])
    edge.save("edges.png")
    print("edges.png saved")
    print("\nDone! Open original.png, grayscale.png, edges.png")

if __name__ == "__main__":
    main()
