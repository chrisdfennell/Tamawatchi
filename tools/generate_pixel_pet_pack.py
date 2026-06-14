from pathlib import Path
import struct
import zlib


class Resampling:
    NEAREST = 0


class Canvas:
    def __init__(self, size, color):
        self.width, self.height = size
        self.pixels = [color] * (self.width * self.height)

    @property
    def size(self):
        return (self.width, self.height)

    def _idx(self, x, y):
        return y * self.width + x

    def point(self, xy, fill):
        x, y = xy
        if 0 <= x < self.width and 0 <= y < self.height:
            self.pixels[self._idx(x, y)] = fill

    def rectangle(self, box, fill):
        x0, y0, x1, y1 = box
        for y in range(max(0, y0), min(self.height - 1, y1) + 1):
            for x in range(max(0, x0), min(self.width - 1, x1) + 1):
                self.point((x, y), fill)

    def resize(self, size, resample=None):
        nw, nh = size
        out = Canvas((nw, nh), (0, 0, 0, 0))
        for y in range(nh):
            sy = min(self.height - 1, y * self.height // nh)
            for x in range(nw):
                sx = min(self.width - 1, x * self.width // nw)
                out.pixels[out._idx(x, y)] = self.pixels[self._idx(sx, sy)]
        return out

    def alpha_composite(self, src, dest):
        dx, dy = dest
        for sy in range(src.height):
            ty = dy + sy
            if not (0 <= ty < self.height):
                continue
            for sx in range(src.width):
                tx = dx + sx
                if not (0 <= tx < self.width):
                    continue
                sp = src.pixels[src._idx(sx, sy)]
                if sp[3] == 0:
                    continue
                if sp[3] == 255:
                    self.pixels[self._idx(tx, ty)] = sp
                    continue
                dp = self.pixels[self._idx(tx, ty)]
                a = sp[3] / 255
                ia = 1 - a
                self.pixels[self._idx(tx, ty)] = (
                    int(sp[0] * a + dp[0] * ia),
                    int(sp[1] * a + dp[1] * ia),
                    int(sp[2] * a + dp[2] * ia),
                    min(255, int(sp[3] + dp[3] * ia)),
                )

    def save(self, path):
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        raw = bytearray()
        for y in range(self.height):
            raw.append(0)
            for x in range(self.width):
                raw.extend(self.pixels[self._idx(x, y)])
        compressed = zlib.compress(bytes(raw), 9)

        def chunk(kind, data):
            body = kind + data
            return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

        png = (
            b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", self.width, self.height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", compressed)
            + chunk(b"IEND", b"")
        )
        path.write_bytes(png)


class Image:
    Resampling = Resampling

    @staticmethod
    def new(mode, size, color):
        if mode != "RGBA":
            raise ValueError("Only RGBA canvases are supported")
        return Canvas(size, color)


class ImageDraw:
    @staticmethod
    def Draw(im):
        return im


ROOT = Path(__file__).resolve().parents[1]
PACK_ROOT = ROOT / "assets" / "tamagotchi_pixel_pet_packs"
OUT = PACK_ROOT / "orange_tabby_pixel_pet_pack"
NATIVE = OUT / "native"
UPSCALED = OUT / "upscaled_4x"

PAL = {
    "black": (31, 28, 35, 255),
    "outline": (43, 34, 39, 255),
    "orange": (238, 132, 43, 255),
    "orange_dark": (187, 82, 38, 255),
    "cream": (255, 218, 145, 255),
    "cream2": (255, 238, 187, 255),
    "pink": (255, 139, 156, 255),
    "red": (218, 55, 65, 255),
    "blue": (76, 170, 232, 255),
    "sky": (123, 210, 246, 255),
    "green": (95, 190, 83, 255),
    "dark_green": (55, 126, 68, 255),
    "yellow": (255, 221, 85, 255),
    "purple": (137, 88, 203, 255),
    "gray": (142, 151, 163, 255),
    "white": (255, 250, 235, 255),
    "shadow": (102, 78, 65, 255),
    "poop": (112, 70, 42, 255),
    "tan": (205, 137, 76, 255),
    "brown": (116, 75, 52, 255),
    "gold": (239, 176, 55, 255),
    "ice": (196, 239, 255, 255),
    "metal": (164, 181, 191, 255),
    "metal_dark": (82, 101, 117, 255),
    "ember": (255, 104, 46, 255),
    "mint": (115, 224, 155, 255),
}

BASE_PAL = dict(PAL)
SPEC = {}

SPECIES = [
    {
        "slug": "orange_tabby",
        "title": "Fluffy Orange Tabby Cat",
        "kind": "cat",
        "primary": (238, 132, 43, 255),
        "secondary": (187, 82, 38, 255),
        "belly": (255, 218, 145, 255),
        "egg": (238, 132, 43, 255),
    },
    {
        "slug": "golden_retriever_puppy",
        "title": "Playful Golden Retriever Puppy",
        "kind": "retriever",
        "primary": (239, 176, 55, 255),
        "secondary": (179, 106, 45, 255),
        "belly": (255, 231, 156, 255),
        "egg": (239, 176, 55, 255),
    },
    {
        "slug": "baby_red_dragon",
        "title": "Baby Red Dragon",
        "kind": "dragon",
        "primary": (219, 56, 48, 255),
        "secondary": (142, 39, 48, 255),
        "belly": (255, 183, 84, 255),
        "egg": (219, 56, 48, 255),
    },
    {
        "slug": "emperor_penguin",
        "title": "Chubby Emperor Penguin",
        "kind": "penguin",
        "primary": (40, 48, 66, 255),
        "secondary": (19, 25, 38, 255),
        "belly": (255, 250, 235, 255),
        "egg": (76, 170, 232, 255),
    },
    {
        "slug": "arctic_fox",
        "title": "Arctic Fox",
        "kind": "fox",
        "primary": (238, 248, 255, 255),
        "secondary": (159, 198, 219, 255),
        "belly": (255, 250, 235, 255),
        "egg": (196, 239, 255, 255),
    },
    {
        "slug": "robot_dog",
        "title": "Robot Dog",
        "kind": "robot_dog",
        "primary": (164, 181, 191, 255),
        "secondary": (82, 101, 117, 255),
        "belly": (196, 239, 255, 255),
        "egg": (164, 181, 191, 255),
    },
    {
        "slug": "boxer_dog",
        "title": "Boxer Dog",
        "kind": "boxer",
        "primary": (184, 104, 55, 255),
        "secondary": (82, 52, 42, 255),
        "belly": (255, 239, 204, 255),
        "egg": (184, 104, 55, 255),
    },
    {
        "slug": "bearded_dragon",
        "title": "Bearded Dragon",
        "kind": "bearded_dragon",
        "primary": (224, 164, 76, 255),
        "secondary": (128, 94, 54, 255),
        "belly": (255, 216, 131, 255),
        "egg": (224, 164, 76, 255),
    },
]


def apply_species(spec):
    global SPEC
    SPEC = spec
    PAL.clear()
    PAL.update(BASE_PAL)
    PAL["orange"] = spec["primary"]
    PAL["orange_dark"] = spec["secondary"]
    PAL["cream"] = spec["belly"]


def img(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def rect(d, box, c):
    d.rectangle(box, fill=PAL[c])


def pix(d, x, y, c):
    d.point((x, y), fill=PAL[c])


def save_asset(im, rel):
    native = NATIVE / rel
    native.parent.mkdir(parents=True, exist_ok=True)
    im.save(native)
    up = im.resize((im.width * 4, im.height * 4), Image.Resampling.NEAREST)
    up_path = UPSCALED / rel
    up_path.parent.mkdir(parents=True, exist_ok=True)
    up.save(up_path)


def sparkle(d, x, y, c="yellow"):
    pts = [(x, y - 2), (x, y + 2), (x - 2, y), (x + 2, y), (x, y)]
    for p in pts:
        pix(d, *p, c)


def heart(d, x, y, c="red", empty=False):
    if empty:
        for dx, dy in [(1, 0), (3, 0), (0, 1), (2, 1), (4, 1), (0, 2), (4, 2), (1, 3), (3, 3), (2, 4)]:
            pix(d, x + dx, y + dy, "outline")
    else:
        for yy, row in enumerate(["01010", "11111", "11111", "01110", "00100"]):
            for xx, v in enumerate(row):
                if v == "1":
                    pix(d, x + xx, y + yy, c)


def draw_species_features(d, x, y, teen=False, adult=False):
    kind = SPEC.get("kind", "cat")
    o, od, cr, bl = "orange", "orange_dark", "cream", "outline"
    if kind == "retriever":
        rect(d, (x + 7, y + 7, x + 12, y + 18), bl)
        rect(d, (x + 8, y + 8, x + 12, y + 18), od)
        rect(d, (x + 24, y + 7, x + 29, y + 18), bl)
        rect(d, (x + 24, y + 8, x + 28, y + 18), od)
        rect(d, (x + 14, y + 15, x + 22, y + 20), cr)
        rect(d, (x + 17, y + 15, x + 19, y + 16), bl)
    elif kind == "dragon":
        rect(d, (x + 4, y + 16, x + 10, y + 27), bl)
        rect(d, (x + 5, y + 17, x + 9, y + 25), "ember")
        rect(d, (x + 26, y + 16, x + 32, y + 27), bl)
        rect(d, (x + 27, y + 17, x + 31, y + 25), "ember")
        rect(d, (x + 11, y + 1, x + 13, y + 5), "yellow")
        rect(d, (x + 23, y + 1, x + 25, y + 5), "yellow")
        for sx in [13, 17, 21]:
            rect(d, (x + sx, y + 3, x + sx + 1, y + 5), "yellow")
        rect(d, (x + 30, y + 11, x + 36, y + 13), bl)
        rect(d, (x + 31, y + 10, x + 35, y + 12), o)
    elif kind == "penguin":
        rect(d, (x + 7, y + 18, x + 10, y + 28), bl)
        rect(d, (x + 8, y + 18, x + 10, y + 27), od)
        rect(d, (x + 26, y + 18, x + 29, y + 28), bl)
        rect(d, (x + 26, y + 18, x + 28, y + 27), od)
        rect(d, (x + 14, y + 15, x + 22, y + 18), "yellow")
        rect(d, (x + 15, y + 16, x + 21, y + 17), "ember")
        rect(d, (x + 11, y + 30, x + 16, y + 33), "yellow")
        rect(d, (x + 21, y + 30, x + 26, y + 33), "yellow")
    elif kind == "fox":
        rect(d, (x + 28, y + 17, x + 38, y + 25), bl)
        rect(d, (x + 29, y + 16, x + 37, y + 24), o)
        rect(d, (x + 34, y + 16, x + 38, y + 20), cr)
        rect(d, (x + 10, y + 3, x + 13, y + 8), cr)
        rect(d, (x + 23, y + 3, x + 26, y + 8), cr)
        rect(d, (x + 14, y + 14, x + 22, y + 20), cr)
    elif kind == "robot_dog":
        rect(d, (x + 10, y + 5, x + 27, y + 21), bl)
        rect(d, (x + 11, y + 6, x + 26, y + 20), o)
        rect(d, (x + 14, y + 8, x + 22, y + 10), "metal_dark")
        rect(d, (x + 16, y + 2, x + 20, y + 5), bl)
        rect(d, (x + 17, y + 0, x + 19, y + 2), "blue")
        rect(d, (x + 13, y + 21, x + 23, y + 28), "ice")
        rect(d, (x + 27, y + 17, x + 34, y + 22), bl)
        rect(d, (x + 28, y + 18, x + 33, y + 21), "metal")
        pix(d, x + 13, y + 12, "blue")
        pix(d, x + 23, y + 12, "blue")
    elif kind == "boxer":
        rect(d, (x + 8, y + 5, x + 13, y + 10), od)
        rect(d, (x + 23, y + 5, x + 28, y + 10), od)
        rect(d, (x + 13, y + 13, x + 23, y + 21), bl)
        rect(d, (x + 14, y + 14, x + 22, y + 20), cr)
        rect(d, (x + 15, y + 15, x + 21, y + 17), od)
        rect(d, (x + 17, y + 17, x + 19, y + 18), bl)
    elif kind == "bearded_dragon":
        for sx in [10, 13, 16, 19, 22, 25]:
            rect(d, (x + sx, y + 3, x + sx + 1, y + 5), od)
        for sy in [16, 19, 22]:
            rect(d, (x + 9, y + sy, x + 10, y + sy + 1), od)
            rect(d, (x + 26, y + sy, x + 27, y + sy + 1), od)
        rect(d, (x + 14, y + 19, x + 22, y + 22), od)
        rect(d, (x + 30, y + 14, x + 37, y + 17), bl)
        rect(d, (x + 31, y + 13, x + 36, y + 16), o)
    if teen:
        sparkle(d, x + 3, y + 15, "blue")
    if adult:
        sparkle(d, x + 32, y + 7, "yellow")


def draw_cat(d, x, y, scale=1, mood="idle", teen=False, adult=False):
    o, od, cr, bl = "orange", "orange_dark", "cream", "outline"
    # Tail
    rect(d, (x + 27, y + 17, x + 30, y + 20), bl)
    rect(d, (x + 28, y + 14, x + 31, y + 18), o)
    rect(d, (x + 30, y + 13, x + 34, y + 16), bl)
    rect(d, (x + 31, y + 12, x + 34, y + 15), o)
    rect(d, (x + 32, y + 12, x + 33, y + 13), od)
    # Body
    rect(d, (x + 9, y + 17, x + 27, y + 31), bl)
    rect(d, (x + 10, y + 16, x + 26, y + 30), o)
    rect(d, (x + 13, y + 21, x + 23, y + 29), cr)
    rect(d, (x + 12, y + 17, x + 15, y + 18), od)
    rect(d, (x + 21, y + 17, x + 24, y + 18), od)
    # Head
    rect(d, (x + 8, y + 6, x + 28, y + 22), bl)
    rect(d, (x + 9, y + 7, x + 27, y + 21), o)
    # Ears
    rect(d, (x + 9, y + 2, x + 14, y + 8), bl)
    rect(d, (x + 10, y + 3, x + 13, y + 8), o)
    rect(d, (x + 11, y + 5, x + 12, y + 7), "pink")
    rect(d, (x + 22, y + 2, x + 27, y + 8), bl)
    rect(d, (x + 23, y + 3, x + 26, y + 8), o)
    rect(d, (x + 24, y + 5, x + 25, y + 7), "pink")
    # Muzzle
    rect(d, (x + 14, y + 14, x + 22, y + 19), cr)
    rect(d, (x + 17, y + 16, x + 19, y + 17), "pink")
    draw_species_features(d, x, y, teen=teen, adult=adult)
    # Stripes
    if SPEC.get("kind") in ("cat", "fox", "bearded_dragon", "dragon"):
        rect(d, (x + 14, y + 8, x + 16, y + 10), od)
        rect(d, (x + 19, y + 8, x + 21, y + 10), od)
        rect(d, (x + 9, y + 12, x + 12, y + 13), od)
        rect(d, (x + 24, y + 12, x + 27, y + 13), od)
    # Eyes and expression
    if mood == "sad":
        rect(d, (x + 12, y + 12, x + 15, y + 13), bl)
        rect(d, (x + 21, y + 12, x + 24, y + 13), bl)
        pix(d, x + 14, y + 15, "blue")
        pix(d, x + 22, y + 15, "blue")
        rect(d, (x + 17, y + 19, x + 20, y + 19), bl)
    elif mood == "sleep":
        rect(d, (x + 12, y + 13, x + 15, y + 13), bl)
        rect(d, (x + 21, y + 13, x + 24, y + 13), bl)
    elif mood == "sick":
        rect(d, (x + 12, y + 12, x + 14, y + 14), "green")
        rect(d, (x + 22, y + 12, x + 24, y + 14), "green")
        rect(d, (x + 17, y + 19, x + 20, y + 19), bl)
    elif mood == "happy":
        rect(d, (x + 12, y + 12, x + 14, y + 14), bl)
        rect(d, (x + 22, y + 12, x + 24, y + 14), bl)
        rect(d, (x + 16, y + 18, x + 20, y + 18), bl)
        pix(d, x + 18, y + 19, "pink")
    else:
        rect(d, (x + 12, y + 11, x + 15, y + 14), bl)
        rect(d, (x + 22, y + 11, x + 25, y + 14), bl)
        pix(d, x + 13, y + 12, "white")
        pix(d, x + 23, y + 12, "white")
        rect(d, (x + 16, y + 18, x + 20, y + 18), bl)
    # Feet
    rect(d, (x + 10, y + 30, x + 15, y + 33), bl)
    rect(d, (x + 21, y + 30, x + 26, y + 33), bl)
    rect(d, (x + 11, y + 30, x + 15, y + 32), cr)
    rect(d, (x + 21, y + 30, x + 25, y + 32), cr)
    if teen:
        rect(d, (x + 5, y + 20, x + 9, y + 25), bl)
        rect(d, (x + 6, y + 20, x + 9, y + 24), o)
    if adult:
        rect(d, (x + 6, y + 4, x + 8, y + 6), "yellow")
        rect(d, (x + 28, y + 4, x + 30, y + 6), "yellow")
        rect(d, (x + 7, y + 3, x + 29, y + 3), "yellow")


def egg():
    im = img(32, 32); d = ImageDraw.Draw(im)
    rect(d, (9, 6, 22, 26), "outline")
    rect(d, (10, 5, 21, 25), "cream2")
    rect(d, (11, 17, 20, 24), "orange")
    rect(d, (12, 8, 18, 11), "white")
    rect(d, (13, 19, 15, 21), "orange_dark")
    rect(d, (18, 20, 20, 22), "orange_dark")
    return im


def baby():
    im = img(32, 32); d = ImageDraw.Draw(im)
    rect(d, (9, 11, 23, 24), "outline")
    rect(d, (10, 10, 22, 23), "orange")
    rect(d, (9, 7, 13, 12), "outline"); rect(d, (10, 8, 12, 12), "orange")
    rect(d, (19, 7, 23, 12), "outline"); rect(d, (20, 8, 22, 12), "orange")
    rect(d, (13, 17, 19, 21), "cream")
    rect(d, (12, 14, 14, 16), "outline"); pix(d, 13, 14, "white")
    rect(d, (18, 14, 20, 16), "outline"); pix(d, 19, 14, "white")
    rect(d, (15, 20, 17, 20), "outline")
    rect(d, (21, 20, 26, 23), "outline"); rect(d, (22, 19, 25, 22), "orange")
    return im


def cat_pose(mood="idle", extra=None):
    im = img(48, 48); d = ImageDraw.Draw(im)
    dy = -3 if mood == "happy" else 2 if mood in ("sad", "sick") else 0
    draw_cat(d, 6, 9 + dy, mood=mood, teen=(extra == "teen"), adult=(extra == "adult"))
    if mood == "happy":
        sparkle(d, 8, 12); sparkle(d, 39, 15)
        heart(d, 35, 5, "red")
    if mood == "sleep":
        rect(d, (32, 8, 37, 9), "blue"); rect(d, (36, 10, 41, 11), "blue"); rect(d, (32, 12, 41, 13), "blue")
    if mood == "hungry":
        rect(d, (34, 9, 43, 18), "outline"); rect(d, (35, 10, 42, 17), "white")
        rect(d, (36, 11, 41, 12), "red"); rect(d, (37, 13, 40, 15), "red")
    if mood == "eat":
        draw_fish(d, 31, 31)
    if mood == "play":
        draw_ball(d, 32, 32)
    if mood == "sick":
        draw_poop(d, 33, 31)
        rect(d, (34, 7, 42, 13), "outline"); rect(d, (35, 8, 41, 12), "green")
    return im


def draw_fish(d, x, y):
    rect(d, (x + 3, y + 5, x + 14, y + 12), "blue")
    rect(d, (x + 2, y + 6, x + 13, y + 11), "sky")
    rect(d, (x + 14, y + 7, x + 19, y + 10), "outline")
    rect(d, (x + 15, y + 6, x + 18, y + 11), "blue")
    pix(d, x + 5, y + 7, "outline")


def draw_bone(d, x, y):
    rect(d, (x + 6, y + 9, x + 17, y + 13), "outline")
    rect(d, (x + 7, y + 10, x + 16, y + 12), "white")
    for bx, by in [(3, 6), (3, 13), (17, 6), (17, 13)]:
        rect(d, (x + bx, y + by, x + bx + 5, y + by + 5), "outline")
        rect(d, (x + bx + 1, y + by + 1, x + bx + 4, y + by + 4), "cream2")


def draw_berries(d, x, y):
    for bx, by, c in [(5, 8, "red"), (11, 7, "purple"), (14, 12, "red"), (7, 14, "purple")]:
        rect(d, (x + bx, y + by, x + bx + 5, y + by + 5), "outline")
        rect(d, (x + bx + 1, y + by + 1, x + bx + 4, y + by + 4), c)
    rect(d, (x + 10, y + 4, x + 13, y + 6), "green")


def draw_cake(d, x, y):
    rect(d, (x + 4, y + 8, x + 19, y + 18), "outline")
    rect(d, (x + 5, y + 9, x + 18, y + 17), "cream2")
    rect(d, (x + 5, y + 9, x + 18, y + 12), "pink")
    rect(d, (x + 8, y + 5, x + 10, y + 8), "yellow")
    rect(d, (x + 7, y + 8, x + 11, y + 8), "outline")


def draw_ball(d, x, y):
    rect(d, (x + 5, y + 5, x + 18, y + 18), "outline")
    rect(d, (x + 6, y + 6, x + 17, y + 17), "red")
    rect(d, (x + 6, y + 6, x + 11, y + 17), "white")
    rect(d, (x + 11, y + 6, x + 12, y + 17), "outline")


def draw_yarn(d, x, y):
    rect(d, (x + 4, y + 5, x + 18, y + 18), "outline")
    rect(d, (x + 5, y + 6, x + 17, y + 17), "purple")
    rect(d, (x + 7, y + 8, x + 16, y + 9), "pink")
    rect(d, (x + 6, y + 13, x + 15, y + 14), "pink")
    rect(d, (x + 14, y + 16, x + 21, y + 17), "purple")


def draw_stick(d, x, y):
    rect(d, (x + 4, y + 13, x + 19, y + 16), "outline")
    rect(d, (x + 5, y + 14, x + 18, y + 15), "poop")
    rect(d, (x + 15, y + 9, x + 18, y + 13), "outline")
    rect(d, (x + 16, y + 10, x + 17, y + 13), "poop")


def draw_poop(d, x, y):
    rect(d, (x + 4, y + 14, x + 18, y + 19), "outline")
    rect(d, (x + 5, y + 13, x + 17, y + 18), "poop")
    rect(d, (x + 7, y + 9, x + 15, y + 13), "outline")
    rect(d, (x + 8, y + 8, x + 14, y + 12), "poop")
    rect(d, (x + 10, y + 5, x + 13, y + 8), "outline")
    rect(d, (x + 11, y + 4, x + 12, y + 7), "poop")


def item(kind):
    im = img(24, 24); d = ImageDraw.Draw(im)
    {"bone": draw_bone, "fish": draw_fish, "berries": draw_berries, "cake": draw_cake,
     "ball": draw_ball, "yarn_ball": draw_yarn, "stick": draw_stick, "poop": draw_poop}[kind](d, 0, 0)
    return im


def icon(kind):
    im = img(24, 24); d = ImageDraw.Draw(im)
    if kind == "heart_full":
        heart(d, 9, 8)
    elif kind == "heart_empty":
        heart(d, 9, 8, empty=True)
    elif kind.startswith("hunger_"):
        n = int(kind[-1])
        rect(d, (3, 8, 20, 15), "outline")
        for i in range(n):
            rect(d, (5 + i * 4, 10, 7 + i * 4, 13), "yellow")
    elif kind == "happiness_meter":
        rect(d, (3, 14, 20, 17), "outline")
        rect(d, (4, 15, 15, 16), "green")
        heart(d, 9, 5)
    elif kind == "poop_icon":
        draw_poop(d, 1, 1)
    return im


def bubble(kind):
    im = img(32, 32); d = ImageDraw.Draw(im)
    rect(d, (5, 5, 25, 22), "outline")
    rect(d, (6, 6, 24, 21), "white")
    rect(d, (10, 22, 14, 26), "outline")
    rect(d, (10, 22, 12, 24), "white")
    if kind == "love":
        heart(d, 13, 11)
    elif kind == "food":
        draw_fish(d, 8, 8)
    elif kind == "sleep":
        rect(d, (12, 10, 17, 11), "blue"); rect(d, (16, 12, 21, 13), "blue"); rect(d, (12, 14, 21, 15), "blue")
    elif kind == "level_up":
        sparkle(d, 16, 12); rect(d, (15, 17, 17, 22), "yellow")
    return im


def ghost():
    im = img(48, 48); d = ImageDraw.Draw(im)
    rect(d, (15, 8, 32, 36), "outline")
    rect(d, (16, 7, 31, 35), "white")
    rect(d, (13, 15, 34, 35), "outline")
    rect(d, (14, 14, 33, 34), "white")
    rect(d, (18, 19, 21, 23), "outline")
    rect(d, (27, 19, 30, 23), "outline")
    rect(d, (22, 27, 26, 28), "outline")
    for x in [14, 20, 26, 32]:
        rect(d, (x, 34, x + 3, 38), "outline")
        rect(d, (x + 1, 34, x + 2, 36), "white")
    sparkle(d, 9, 12, "blue")
    return im


def bg(kind):
    im = img(240, 240); d = ImageDraw.Draw(im)
    if kind == "cozy_room_day":
        rect(d, (0, 0, 239, 155), "cream2")
        rect(d, (0, 156, 239, 239), "cream")
        rect(d, (18, 24, 94, 86), "outline"); rect(d, (22, 28, 90, 82), "sky")
        rect(d, (22, 55, 90, 58), "outline"); rect(d, (55, 28, 58, 82), "outline")
        rect(d, (132, 52, 210, 86), "outline"); rect(d, (136, 56, 206, 82), "pink")
        rect(d, (40, 142, 199, 192), "outline"); rect(d, (44, 146, 195, 188), "orange")
        rect(d, (64, 121, 99, 146), "outline"); rect(d, (68, 125, 95, 145), "purple")
        for x in range(0, 240, 16):
            rect(d, (x, 196, x + 8, 200), "orange_dark")
    elif kind == "night_room":
        rect(d, (0, 0, 239, 155), "purple")
        rect(d, (0, 156, 239, 239), "gray")
        rect(d, (18, 24, 94, 86), "outline"); rect(d, (22, 28, 90, 82), "black")
        for x, y in [(40, 42), (69, 33), (78, 66)]:
            sparkle(d, x, y, "yellow")
        rect(d, (32, 140, 208, 193), "outline"); rect(d, (36, 144, 204, 189), "blue")
        rect(d, (142, 112, 194, 143), "outline"); rect(d, (146, 116, 190, 139), "cream2")
    elif kind == "outdoor_meadow":
        rect(d, (0, 0, 239, 122), "sky")
        rect(d, (0, 123, 239, 239), "green")
        rect(d, (22, 26, 54, 58), "yellow")
        rect(d, (0, 102, 239, 126), "dark_green")
        rect(d, (154, 67, 180, 126), "outline"); rect(d, (158, 70, 176, 126), "poop")
        rect(d, (133, 42, 205, 82), "outline"); rect(d, (137, 39, 201, 78), "green")
        for x in range(14, 226, 24):
            rect(d, (x, 174, x + 2, 181), "dark_green")
            rect(d, (x - 2, 171, x + 4, 173), "yellow")
    return im


def sheet():
    names = [
        ("idle", cat_pose("idle")), ("happy", cat_pose("happy")), ("sad", cat_pose("sad")),
        ("hungry", cat_pose("hungry")), ("sleeping", cat_pose("sleep")),
        ("eating", cat_pose("eat")), ("playing", cat_pose("play")), ("sick_poopy", cat_pose("sick")),
        ("egg", egg().resize((48, 48), Image.Resampling.NEAREST)),
        ("baby", baby().resize((48, 48), Image.Resampling.NEAREST)),
        ("teen", cat_pose("idle", "teen")), ("adult", cat_pose("idle", "adult")),
    ]
    im = img(48 * 4, 48 * 3); d = ImageDraw.Draw(im)
    for i, (_, spr) in enumerate(names):
        im.alpha_composite(spr, ((i % 4) * 48, (i // 4) * 48))
    return im


def build_assets():
    return {
        "stages/egg.png": egg(),
        "stages/baby.png": baby(),
        "stages/teen.png": cat_pose("idle", "teen"),
        "stages/adult.png": cat_pose("idle", "adult"),
        "poses/idle.png": cat_pose("idle"),
        "poses/happy.png": cat_pose("happy"),
        "poses/sad.png": cat_pose("sad"),
        "poses/hungry.png": cat_pose("hungry"),
        "poses/sleeping.png": cat_pose("sleep"),
        "poses/eating.png": cat_pose("eat"),
        "poses/playing.png": cat_pose("play"),
        "poses/sick_poopy.png": cat_pose("sick"),
        "effects/death_ghost.png": ghost(),
        "sprite_sheet/pet_sheet_48x48.png": sheet(),
        **{f"items/food/{name}.png": item(name) for name in ["bone", "fish", "berries", "cake"]},
        **{f"items/toys/{name}.png": item(name) for name in ["ball", "yarn_ball", "stick"]},
        **{f"ui/status/{name}.png": icon(name) for name in ["heart_full", "heart_empty", "hunger_0", "hunger_1", "hunger_2", "hunger_3", "hunger_4", "poop_icon", "happiness_meter"]},
        **{f"ui/bubbles/{name}.png": bubble(name) for name in ["love", "food", "sleep", "level_up"]},
        **{f"backgrounds/{name}.png": bg(name) for name in ["cozy_room_day", "night_room", "outdoor_meadow"]},
    }


def add_animation_assets(assets):
    for i in range(3):
        im = img(32, 32); d = ImageDraw.Draw(im)
        sparkle(d, 10 + i * 4, 10, "yellow"); sparkle(d, 20, 18 - i * 3, "blue")
        assets[f"effects/sparkle_{i}.png"] = im
    for i in range(3):
        im = img(32, 32); d = ImageDraw.Draw(im)
        heart(d, 6 + i * 3, 16 - i * 4); heart(d, 18, 12 - i * 2, "pink")
        assets[f"effects/floating_hearts_{i}.png"] = im


def write_pack_readme(spec, count):
    readme = OUT / "README.md"
    readme.write_text(
        f"# {spec['title']} Garmin Pixel Pet Pack\n\n"
        "Classic 16-bit virtual pet asset pack for small Garmin MIP/AMOLED screens.\n\n"
        f"- Character: {spec['title']}.\n"
        f"- Native transparent PNGs: `{count}` files in `native/`.\n"
        f"- 4x nearest-neighbor reference PNGs: `{count}` files in `upscaled_4x/`.\n"
        "- Pet poses are 48x48, food/toys/icons are 24x24, bubbles/effects are 32x32, backgrounds are 240x240.\n"
        "- Sprite sheet order: idle, happy, sad, hungry, sleeping, eating, playing, sick_poopy, egg, baby, teen, adult.\n",
        encoding="utf-8",
    )


def write_index_readme(total_per_pack):
    lines = [
        "# Tamagotchi Pixel Pet Packs",
        "",
        "Complete Garmin-friendly 16-bit virtual pet packs. Each folder contains native transparent PNGs and 4x nearest-neighbor reference PNGs.",
        "",
    ]
    for spec in SPECIES:
        lines.append(f"- `{spec['slug']}_pixel_pet_pack/` - {spec['title']} ({total_per_pack} native PNGs + {total_per_pack} 4x PNGs)")
    lines.append("")
    (PACK_ROOT / "README.md").write_text("\n".join(lines), encoding="utf-8")


def main():
    global OUT, NATIVE, UPSCALED
    PACK_ROOT.mkdir(parents=True, exist_ok=True)
    total_per_pack = 0
    for spec in SPECIES:
        apply_species(spec)
        OUT = PACK_ROOT / f"{spec['slug']}_pixel_pet_pack"
        NATIVE = OUT / "native"
        UPSCALED = OUT / "upscaled_4x"
        for sub in [NATIVE, UPSCALED]:
            sub.mkdir(parents=True, exist_ok=True)
        assets = build_assets()
        add_animation_assets(assets)
        for rel, im in assets.items():
            save_asset(im, rel)
        write_pack_readme(spec, len(assets))
        total_per_pack = len(assets)
        print(f"Wrote {len(assets)} native assets and 4x references to {OUT}")
    write_index_readme(total_per_pack)


def old_single_pack_main():
    for sub in [NATIVE, UPSCALED]:
        sub.mkdir(parents=True, exist_ok=True)
    assets = {
        "stages/egg.png": egg(),
        "stages/baby.png": baby(),
        "stages/teen.png": cat_pose("idle", "teen"),
        "stages/adult.png": cat_pose("idle", "adult"),
        "poses/idle.png": cat_pose("idle"),
        "poses/happy.png": cat_pose("happy"),
        "poses/sad.png": cat_pose("sad"),
        "poses/hungry.png": cat_pose("hungry"),
        "poses/sleeping.png": cat_pose("sleep"),
        "poses/eating.png": cat_pose("eat"),
        "poses/playing.png": cat_pose("play"),
        "poses/sick_poopy.png": cat_pose("sick"),
        "effects/death_ghost.png": ghost(),
        "sprite_sheet/pet_sheet_48x48.png": sheet(),
    }
    for name in ["bone", "fish", "berries", "cake"]:
        assets[f"items/food/{name}.png"] = item(name)
    for name in ["ball", "yarn_ball", "stick"]:
        assets[f"items/toys/{name}.png"] = item(name)
    for name in ["heart_full", "heart_empty", "hunger_0", "hunger_1", "hunger_2", "hunger_3", "hunger_4", "poop_icon", "happiness_meter"]:
        assets[f"ui/status/{name}.png"] = icon(name)
    for name in ["love", "food", "sleep", "level_up"]:
        assets[f"ui/bubbles/{name}.png"] = bubble(name)
    for name in ["cozy_room_day", "night_room", "outdoor_meadow"]:
        assets[f"backgrounds/{name}.png"] = bg(name)
    for i in range(3):
        im = img(32, 32); d = ImageDraw.Draw(im)
        sparkle(d, 10 + i * 4, 10, "yellow"); sparkle(d, 20, 18 - i * 3, "blue")
        assets[f"effects/sparkle_{i}.png"] = im
    for i in range(3):
        im = img(32, 32); d = ImageDraw.Draw(im)
        heart(d, 6 + i * 3, 16 - i * 4); heart(d, 18, 12 - i * 2, "pink")
        assets[f"effects/floating_hearts_{i}.png"] = im
    for rel, im in assets.items():
        save_asset(im, rel)
    readme = OUT / "README.md"
    readme.write_text(
        "# Orange Tabby Garmin Pixel Pet Pack\n\n"
        "Classic 16-bit virtual pet asset pack for small Garmin MIP/AMOLED screens.\n\n"
        "- Native transparent PNGs are in `native/`.\n"
        "- 4x nearest-neighbor reference PNGs are in `upscaled_4x/`.\n"
        "- Pet poses are 48x48, food/toys/icons are 24x24, bubbles/effects are 32x32, backgrounds are 240x240.\n"
        "- Sprite sheet order: idle, happy, sad, hungry, sleeping, eating, playing, sick_poopy, egg, baby, teen, adult.\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(assets)} native assets and 4x references to {OUT}")


if __name__ == "__main__":
    main()
