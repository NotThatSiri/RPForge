# Draws RP Forge's own interface icons as 64x64 white 32-bit TGA files with soft edges.
# They are drawn white so the addon can colour them with the active theme.
# Usage: python tools/make_icons.py   (writes into Media/Icons next to this folder)
import math, os, struct

N = 64
C = N / 2 - 0.5
SS = 4  # samples per axis per pixel (anti-aliasing)


def cog(x, y):
    teeth, r_body, r_tooth, r_hole = 8, 20.5, 28.0, 8.5
    dx, dy = x - C, y - C
    r = math.hypot(dx, dy)
    if r < r_hole or r > r_tooth:
        return False
    if r <= r_body:
        return True
    period = 2 * math.pi / teeth
    a = (math.atan2(dy, dx) + period / 4) % period
    t = (r - r_body) / (r_tooth - r_body)  # 0 at the body, 1 at the tooth tip
    half = period * (0.30 - 0.08 * t)       # teeth narrow towards the tip
    return abs(a - period / 2) <= half


def close(x, y):
    # Two crossing bars with rounded ends, about as heavy as the cog's teeth.
    half_width, reach = 5.0, 21.0
    dx, dy = x - C, y - C
    for ux, uy in ((1, 1), (1, -1)):
        ux, uy = ux / math.sqrt(2), uy / math.sqrt(2)
        along = dx * ux + dy * uy
        across = abs(-dx * uy + dy * ux)
        if abs(along) <= reach and across <= half_width:
            return True
        end = math.copysign(reach, along)
        if abs(along) > reach and math.hypot(along - end, across) <= half_width:
            return True
    return False


def ring(x, y):
    # A round frame for portraits: a band near the edge, empty in the middle.
    r = math.hypot(x - C, y - C)
    return 27.0 <= r <= 31.5


def dot(x, y):
    # A filled circle, for dot ratings (traits).
    return math.hypot(x - C, y - C) <= 26.0


def hollow(x, y):
    # An empty circle with a fine edge, for the unfilled dots.
    r = math.hypot(x - C, y - C)
    return 21.5 <= r <= 26.0


def write(path, shape):
    pixels = bytearray()
    for py in range(N):
        for px in range(N):
            hits = sum(
                shape(px + (sx + 0.5) / SS - 0.5, py + (sy + 0.5) / SS - 0.5)
                for sy in range(SS) for sx in range(SS)
            )
            pixels += bytes((255, 255, 255, round(255 * hits / (SS * SS))))  # B, G, R, A
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, N, N, 32, 8 | 0x20)
    with open(path, "wb") as f:
        f.write(header + pixels)
    print("wrote", path)


if __name__ == "__main__":
    folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Media", "Icons")
    os.makedirs(folder, exist_ok=True)
    write(os.path.join(folder, "Cog.tga"), cog)
    write(os.path.join(folder, "Close.tga"), close)
    write(os.path.join(folder, "Ring.tga"), ring)
    write(os.path.join(folder, "Dot.tga"), dot)
    write(os.path.join(folder, "DotEmpty.tga"), hollow)
