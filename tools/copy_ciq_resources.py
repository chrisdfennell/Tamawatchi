from pathlib import Path

from generate_pixel_pet_pack import (
    SPECIES,
    apply_species,
    baby,
    cat_pose,
    egg,
    ghost,
    icon,
)

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "resources" / "images"


FILES = {
    "cat": "orange_tabby",
    "dog": "golden_retriever_puppy",
    "dragon": "baby_red_dragon",
    "penguin": "emperor_penguin",
    "fox": "arctic_fox",
}


def species(slug):
    return next(s for s in SPECIES if s["slug"] == slug)


def save_scaled(canvas, dest_name, factor):
    out = canvas.resize((canvas.width * factor, canvas.height * factor))
    out.save(DEST / dest_name)


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    # Keep the hand-tuned 500px store icon.
    icon_src = ROOT / "assets" / "tamagotchi_pixel_pet_packs" / "orange_tabby_pixel_pet_pack" / "app_icon_500.png"
    (DEST / "app_icon_500.png").write_bytes(icon_src.read_bytes())

    for prefix, slug in FILES.items():
        apply_species(species(slug))
        save_scaled(cat_pose("idle"), f"{prefix}_idle.png", 3)
        save_scaled(cat_pose("happy"), f"{prefix}_happy.png", 3)
        save_scaled(cat_pose("sad"), f"{prefix}_sad.png", 3)
        save_scaled(cat_pose("sleep"), f"{prefix}_sleeping.png", 3)
        save_scaled(cat_pose("sick"), f"{prefix}_sick_poopy.png", 3)

    apply_species(species("orange_tabby"))
    save_scaled(egg(), "egg.png", 2)
    save_scaled(baby(), "baby.png", 3)
    save_scaled(ghost(), "death_ghost.png", 3)
    save_scaled(icon("heart_full"), "heart_full.png", 3)
    save_scaled(icon("poop_icon"), "poop_icon.png", 3)
    print(f"Wrote app-scaled images to {DEST}")


if __name__ == "__main__":
    main()
