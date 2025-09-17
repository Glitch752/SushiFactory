# There's probably a way to do this when creating the assets in aesprite, but I don't know how.

# Essentially, we want to create animated belts but reuse the same N-frame animations for each direction no matter where on the belt they are.
# E.g. both the "straight up" belt and the "up-right corner" belt should use the "up" animation frames.
# To do this, we use Aseprite's convenient JSON export capabilities to export the direction animation tags separately from the belt frames. Then,
# we use the color assigned to each animation tag and replace occurances of that color in the belt frames with the corresponding animation frames.
# The process essentially looks like this:
# - Extract animation frame sets and colors
#   - Ensure all animation frame sets are the same length since it just creates weird edge cases I don't want to deal with otherwise
# - Extract belt frames
# - For each belt frame, create a row in the final image by replacing pixels of the animation tag colors with the corresponding animation frames
# - Save the final image

from dataclasses import dataclass
from PIL import Image
import sys
import json
from typing import TypedDict, cast

class Size(TypedDict):
    w: int
    h: int

class Bounds(TypedDict):
    x: int
    y: int
    w: int
    h: int

class AsepriteFrame(TypedDict):
    filename: str
    frame: Bounds
    rotated: bool
    trimmed: bool
    spriteSourceSize: Bounds
    sourceSize: Size
    duration: float

# We need to used the functional syntax for this since "from" is a keyword
AsepriteFrameTags = TypedDict("AsepriteFrameTags", {
    'name': str,
    'from': int,
    'to': int,
    'direction': str,
    'color': str
})

class AsepriteMeta(TypedDict):
    app: str
    version: str
    image: str
    format: str
    size: Size
    scale: str # str? huh.
    frameTags: list[AsepriteFrameTags]

class AsepriteData(TypedDict):
    frames: list[AsepriteFrame]
    meta: AsepriteMeta

# The tag of the "normal" frames (which have animations added to them, with one per output row)
NORMAL_FRAMES_TAG = "Belts"

@dataclass
class ProcessedFrameTags:
    start: int
    end: int
    color: str
    frames: list[Image.Image]

def get_animation_frames(frames: list[AsepriteFrame], img: Image.Image, frame_tags: list[AsepriteFrameTags]) -> tuple[dict[str, ProcessedFrameTags], int]:
    "Map from color to frame tags, where the color is formatted as #rrggbbaa with alpha as ff in all the tags used."
    
    animation_frame_set: dict[str, ProcessedFrameTags] = {}
    first_tag: AsepriteFrameTags | None = None
    
    for tag in frame_tags:
        if tag["name"] == NORMAL_FRAMES_TAG:
            continue
        
        if first_tag is None:
            first_tag = tag
        else:
            if (tag["to"] - tag["from"]) != (first_tag["to"] - first_tag["from"]):
                raise ValueError("All animation frame sets must be the same length")

        color = tag["color"]
        
        animation_frame_set[color] = ProcessedFrameTags(
            start=tag["from"],
            end=tag["to"],
            color=color,
            frames=[
                img.crop((
                    frames[i]["frame"]["x"],
                    frames[i]["frame"]["y"],
                    frames[i]["frame"]["x"] + frames[i]["frame"]["w"],
                    frames[i]["frame"]["y"] + frames[i]["frame"]["h"],
                )) for i in range(tag["from"], tag["to"] + 1)
            ]
        )
    
    if first_tag is None:
        raise ValueError("No animation tags found")
    
    return (animation_frame_set, first_tag["to"] - first_tag["from"] + 1)


def get_normal_frames(frames: list[AsepriteFrame], img: Image.Image, frame_tags: list[AsepriteFrameTags]) -> list[Image.Image]:
    "Get all the normal frames under the tag NORMAL_FRAMES_TAG"
    
    normal_frames: list[Image.Image] = []
    normal_tag: AsepriteFrameTags | None = None
    for tag in frame_tags:
        if tag["name"] == NORMAL_FRAMES_TAG:
            normal_tag = tag
            break
    
    if normal_tag is None:
        raise ValueError(f"No tag named {NORMAL_FRAMES_TAG} found")

    for i in range(normal_tag["from"], normal_tag["to"] + 1):
        normal_frames.append(img.crop((
            frames[i]["frame"]["x"],
            frames[i]["frame"]["y"],
            frames[i]["frame"]["x"] + frames[i]["frame"]["w"],
            frames[i]["frame"]["y"] + frames[i]["frame"]["h"],
        )))
    
    return normal_frames

def postprocess_conveyor_sprite(input_image_path: str, input_json_path: str, output_path: str, frame_width=16, frame_height=16):
    img = Image.open(input_image_path).convert("RGBA")
    with open(input_json_path, "r") as json_data:
        data: AsepriteData = json.loads(json_data.read())
    
    (animation_frame_set, animation_frames) = get_animation_frames(data["frames"], img, data["meta"]["frameTags"])
    print(f"Extracted {len(animation_frame_set)} animation frame types")
    
    normal_frame_set = get_normal_frames(data["frames"], img, data["meta"]["frameTags"])
    print(f"Extracted {len(normal_frame_set)} normal frames")
    
    out_img = Image.new("RGBA", (animation_frames * frame_width, len(normal_frame_set) * frame_height))
    
    for (row, normal_frame) in enumerate(normal_frame_set):
        for x in range(frame_width):
            for y in range(frame_height):
                pixel = cast(tuple[int, int, int], normal_frame.getpixel((x, y)))
                hex_color = f"#{pixel[0]:02x}{pixel[1]:02x}{pixel[2]:02x}ff"
                
                if hex_color in animation_frame_set:
                    anim_frames = animation_frame_set[hex_color].frames
                    for anim_frame_index in range(animation_frames):
                        anim_pixel = cast(tuple[int, int, int], anim_frames[anim_frame_index].getpixel((x, y)))
                        out_img.putpixel((anim_frame_index * frame_width + x, row * frame_height + y), anim_pixel)
                else:
                    for anim_frame_index in range(animation_frames):
                        out_img.putpixel((anim_frame_index * frame_width + x, row * frame_height + y), pixel)

    out_img.save(output_path)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python conveyor_postprocess.py <input.png> <input.json> <output.png>")
        sys.exit(1)
    input_image_path = sys.argv[1]
    input_json_path = sys.argv[2]
    output_path = sys.argv[3]
    postprocess_conveyor_sprite(input_image_path, input_json_path, output_path)