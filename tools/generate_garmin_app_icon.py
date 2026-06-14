from generate_pixel_pet_pack import Canvas, PAL, apply_species, SPECIES


def rect(d, box, color):
    d.rectangle(box, fill=PAL[color])


def pix(d, x, y, color):
    d.point((x, y), fill=PAL[color])


def sparkle(d, x, y, color="yellow"):
    for px, py in [(x, y - 2), (x, y + 2), (x - 2, y), (x + 2, y), (x, y)]:
        pix(d, px, py, color)


def circle_fill(d, cx, cy, r, color):
    rr = r * r
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= rr:
                pix(d, x, y, color)


def draw_face_icon():
    src = Canvas((125, 125), (0, 0, 0, 0))
    d = src

    circle_fill(d, 62, 62, 58, "outline")
    circle_fill(d, 62, 62, 54, "sky")
    circle_fill(d, 62, 66, 47, "cream2")

    # Ears
    rect(d, (25, 18, 44, 47), "outline")
    rect(d, (29, 20, 43, 49), "orange")
    rect(d, (34, 29, 40, 43), "pink")
    rect(d, (80, 18, 99, 47), "outline")
    rect(d, (81, 20, 95, 49), "orange")
    rect(d, (85, 29, 91, 43), "pink")

    # Head
    rect(d, (25, 36, 99, 96), "outline")
    rect(d, (28, 34, 96, 94), "orange")
    rect(d, (32, 89, 92, 101), "outline")
    rect(d, (35, 88, 89, 98), "orange")

    # Cheeks and muzzle
    rect(d, (38, 66, 86, 91), "cream")
    rect(d, (43, 71, 81, 95), "cream2")
    rect(d, (58, 73, 66, 79), "pink")
    rect(d, (61, 79, 63, 84), "outline")
    rect(d, (51, 85, 73, 88), "outline")
    rect(d, (54, 88, 70, 91), "pink")

    # Eyes
    rect(d, (39, 52, 53, 68), "outline")
    rect(d, (72, 52, 86, 68), "outline")
    rect(d, (43, 55, 48, 61), "white")
    rect(d, (76, 55, 81, 61), "white")
    pix(d, 50, 65, "blue")
    pix(d, 83, 65, "blue")

    # Tabby markings
    rect(d, (47, 38, 54, 46), "orange_dark")
    rect(d, (59, 36, 66, 48), "orange_dark")
    rect(d, (71, 38, 78, 46), "orange_dark")
    rect(d, (28, 58, 40, 62), "orange_dark")
    rect(d, (84, 58, 96, 62), "orange_dark")

    # Round icon detail and highlights
    rect(d, (20, 101, 104, 105), "outline")
    rect(d, (25, 103, 99, 107), "orange_dark")
    sparkle(d, 24, 28)
    sparkle(d, 101, 31)
    sparkle(d, 19, 83, "white")
    sparkle(d, 105, 84, "white")

    return src.resize((500, 500))


def main():
    spec = next(s for s in SPECIES if s["slug"] == "orange_tabby")
    apply_species(spec)
    out = "assets/tamagotchi_pixel_pet_packs/orange_tabby_pixel_pet_pack/app_icon_500.png"
    draw_face_icon().save(out)
    print(out)


if __name__ == "__main__":
    main()
