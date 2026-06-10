// Bare-metal RISC-V image processing — RV32I (no multiply instruction)
//
// Memory map (DATA memory, byte-addressed, Harvard arch):
//   0x00000: W (image width,  1 word)
//   0x00004: H (image height, 1 word)
//   0x00008 + i*4: input pixels, 0x00RRGGBB, one word per pixel
//   0x10000 + i*4: grayscale output (pass 1 scratch + output)
//   0x20000 + i*4: Sobel edge output (pass 2)
//   0x30000: stack top (grows downward)

#define INPUT_BASE  0x00000
#define GRAY_BASE   0x10000
#define EDGE_BASE   0x20000

#define RMEM(addr)      (*((volatile unsigned int*)(addr)))
#define WMEM(addr,val)  (*((volatile unsigned int*)(addr)) = (val))

static inline unsigned int absi(int x)        { return x < 0 ? (unsigned int)(-x) : (unsigned int)x; }
static inline unsigned int clamp255(unsigned int v) { return v > 255 ? 255 : v; }

void process_image(void) {
    unsigned int W = RMEM(INPUT_BASE + 0);
    unsigned int H = RMEM(INPUT_BASE + 4);
    unsigned int N = W * H;
    unsigned int i, x, y;

    // ── Pass 1: RGB → Grayscale ──────────────────────────────────────
    // Y = (77R + 150G + 29B) >> 8   (fixed-point, no division)
    // All multiplies use shift+add; gcc will call __mulsi3 for W*H only
    for (i = 0; i < N; i++) {
        unsigned int px = RMEM(INPUT_BASE + 8 + (i << 2));
        unsigned int r  = (px >> 16) & 0xFF;
        unsigned int g  = (px >>  8) & 0xFF;
        unsigned int b  =  px        & 0xFF;

        // 77  = 64+8+4+1
        unsigned int yr = (r<<6)+(r<<3)+(r<<2)+r;
        // 150 = 128+16+4+2
        unsigned int yg = (g<<7)+(g<<4)+(g<<2)+(g<<1);
        // 29  = 16+8+4+1
        unsigned int yb = (b<<4)+(b<<3)+(b<<2)+b;

        WMEM(GRAY_BASE + (i << 2), (yr + yg + yb) >> 8);
    }

    // ── Pass 2: Sobel edge detection ─────────────────────────────────
    // Gx = [-1 0 +1; -2 0 +2; -1 0 +1]
    // Gy = [-1 -2 -1;  0  0  0; +1 +2 +1]
    // magnitude = clamp(|Gx| + |Gy|, 0, 255)
    for (y = 0; y < H; y++) {
        for (x = 0; x < W; x++) {
            unsigned int idx = y * W + x;
            unsigned int mag;

            if (x == 0 || x == W-1 || y == 0 || y == H-1) {
                // Border: copy grayscale value
                mag = RMEM(GRAY_BASE + (idx << 2));
            } else {
                int p00 = (int)RMEM(GRAY_BASE + (((y-1)*W + x-1) << 2));
                int p01 = (int)RMEM(GRAY_BASE + (((y-1)*W + x  ) << 2));
                int p02 = (int)RMEM(GRAY_BASE + (((y-1)*W + x+1) << 2));
                int p10 = (int)RMEM(GRAY_BASE + (( y   *W + x-1) << 2));
                int p12 = (int)RMEM(GRAY_BASE + (( y   *W + x+1) << 2));
                int p20 = (int)RMEM(GRAY_BASE + (((y+1)*W + x-1) << 2));
                int p21 = (int)RMEM(GRAY_BASE + (((y+1)*W + x  ) << 2));
                int p22 = (int)RMEM(GRAY_BASE + (((y+1)*W + x+1) << 2));

                int gx = -p00 + p02 + (-p10 << 1) + (p12 << 1) - p20 + p22;
                int gy = -p00 + (-p01 << 1) - p02 + p20 + (p21 << 1) + p22;

                mag = clamp255(absi(gx) + absi(gy));
            }
            WMEM(EDGE_BASE + (idx << 2), mag);
        }
    }
}
