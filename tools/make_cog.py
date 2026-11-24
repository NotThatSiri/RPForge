# Draws RP Forge's cogwheel icon: 64x64, white with soft (anti-aliased) edges, saved as a 32-bit TGA.
import math, struct, sys
out = sys.argv[1]
N = 64; C = N / 2 - 0.5
TEETH = 8
R_BODY, R_TOOTH, R_HOLE = 20.5, 28.0, 8.5
SS = 4  # samples per axis per pixel

def inside(x, y):
    dx, dy = x - C, y - C
    r = math.hypot(dx, dy)
    if r < R_HOLE or r > R_TOOTH:
        return False
    if r <= R_BODY:
        return True
    a = (math.atan2(dy, dx) + math.pi / TEETH / 2) % (2 * math.pi / TEETH)
    period = 2 * math.pi / TEETH
    t = (r - R_BODY) / (R_TOOTH - R_BODY)          # 0 at the body, 1 at the tooth tip
    half = period * (0.30 - 0.08 * t)               # teeth narrow towards the tip
    return abs(a - period / 2) <= half

pixels = bytearray()
for py in range(N):
    for px in range(N):
        hits = 0
        for sy in range(SS):
            for sx in range(SS):
                if inside(px + (sx + 0.5) / SS - 0.5, py + (sy + 0.5) / SS - 0.5):
                    hits += 1
        alpha = round(255 * hits / (SS * SS))
        pixels += bytes((255, 255, 255, alpha))  # B, G, R, A
header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, N, N, 32, 8 | 0x20)
open(out, "wb").write(header + pixels)
print("wrote", out, len(header + pixels), "bytes")
