# There's probably a way to do this when creating the assets in aseprite, but I don't know how.

# This documentation has become a little messy, but meh
# First, we execute an initial pass which re-combine the layers in the export. Because we want to create multiple variants of each belt
# with various layers toggled on and off, we export the file in aseprite with layers split.

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
from typing import Optional, TypedDict, cast

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
    'color': Optional[str]
})

class AsepriteLayer(TypedDict):
    name: str
    opacity: int
    blendMode: str
    color: Optional[str]

class AsepriteMeta(TypedDict):
    app: str
    version: str
    image: str
    format: str
    size: Size
    scale: str # str? huh.
    frameTags: list[AsepriteFrameTags]
    layers: list[AsepriteLayer]

class AsepriteData(TypedDict):
    frames: list[AsepriteFrame]
    meta: AsepriteMeta

@dataclass
class ProcessedFrameTags:
    start: int
    end: int
    color: str
    frames: list[Image.Image]

def get_animation_frame_count(frame_tags: list[AsepriteFrameTags]) -> int:
    "Get the number of frames in each animation frame set. All sets must be the same length."
    first_tag: AsepriteFrameTags | None = None
    for tag in frame_tags:
        if not tag["name"].startswith("_Belt"):
            continue
        
        if first_tag is None:
            first_tag = tag
        else:
            if (tag["to"] - tag["from"]) != (first_tag["to"] - first_tag["from"]):
                raise ValueError("All animation frame sets must be the same length")
    
    if first_tag is None:
        raise ValueError("No animation tags found")
    
    return first_tag["to"] - first_tag["from"] + 1

def get_animation_frames(frames: list[AsepriteFrame], img: Image.Image, frame_tags: list[AsepriteFrameTags]) -> dict[str, ProcessedFrameTags]:
    "Map from color to frame tags, where the color is formatted as #rrggbbaa with alpha as ff in all the tags used."
    
    animation_frame_set: dict[str, ProcessedFrameTags] = {}
    
    for tag in frame_tags:
        if not tag["name"].startswith("_Belt"):
            continue
        
        color = tag["color"]
        if not color:
            raise ValueError(f"Tag {tag['name']} is missing a color")
        
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
    
    return animation_frame_set


def get_normal_tags(frame_tags: list[AsepriteFrameTags]) -> list[AsepriteFrameTags]:
    "Get all tags that don't start with _Belt"
    return [tag for tag in frame_tags if not tag["name"].startswith("_Belt")]

def get_normal_frame_count(frame_tags: list[AsepriteFrameTags]) -> int:
    "Get the number of normal frames under non-background tags."
    
    normal_tags = get_normal_tags(frame_tags)
    if len(normal_tags) == 0:
        raise ValueError("No normal tags found")
    
    count = 0
    for tag in normal_tags:
        count += tag["to"] - tag["from"] + 1
    return count
    
def get_normal_frames(frames: list[AsepriteFrame], img: Image.Image, frame_tags: list[AsepriteFrameTags]) -> list[Image.Image]:
    "Get all the normal frames under the tag NORMAL_FRAMES_TAG"
    
    normal_frames: list[Image.Image] = []
    
    normal_tags = get_normal_tags(frame_tags)
    if len(normal_tags) == 0:
        raise ValueError(f"No normal tags found")

    for tag in normal_tags:
        for i in range(tag["from"], tag["to"] + 1):
            normal_frames.append(img.crop((
                frames[i]["frame"]["x"],
                frames[i]["frame"]["y"],
                frames[i]["frame"]["x"] + frames[i]["frame"]["w"],
                frames[i]["frame"]["y"] + frames[i]["frame"]["h"],
            )))
    
    return normal_frames

def preprocess_combine_layers(img: Image.Image, layers: list[AsepriteLayer], frames: list[AsepriteFrame], layer_combination: set[str]) -> Image.Image:
    out_img = Image.new("RGBA", (img.size[0], img.size[1] // len(layers)), (0, 0, 0, 0))
    
    # For every frame, combine the visible layers. Put the result at the same position as the first occurance of each layer
    # There's a bit of custom logic here, then, too: pixels of exactly (255, 0, 0, 128) are used to indicate a "mask" which
    # makes that pixel fully transparent regardless of what layers are below it. Aseprite doesn't support masks yet, sadly.
    
    for frame in frames:
        # We put custom data in the filename to include its layer
        layer = frame["filename"].split("|")[1]
        if layer not in layer_combination:
            continue
        
        layer_info = next((l for l in layers if l["name"] == layer), None)
        
        if layer_info is None:
            raise ValueError(f"Layer {layer} not found in layers")
        
        if layer_info["opacity"] == 0:
            continue
        
        frame_img = img.crop((
            frame["frame"]["x"],
            frame["frame"]["y"],
            frame["frame"]["x"] + frame["frame"]["w"],
            frame["frame"]["y"] + frame["frame"]["h"],
        ))
        
        for x in range(frame_img.size[0]):
            for y in range(frame_img.size[1]):
                pixel = cast(tuple[int, int, int, int], frame_img.getpixel((x, y)))
                
                new_x = frame["frame"]["x"] + x
                new_y = frame["frame"]["y"] % out_img.size[1] + y
                if pixel == (255, 0, 0, 128):
                    out_img.putpixel((new_x, new_y), (0, 0, 0, 0))
                elif pixel[3] > 0:
                    # This doesn't do alpha blending, but whatever
                    out_img.putpixel((new_x, new_y), pixel)
    
    return out_img

def postprocess_conveyor_sprite(input_image_path: str, input_json_path: str, output_path: str, frame_width=16, frame_height=16):
    img = Image.open(input_image_path).convert("RGBA")
    with open(input_json_path, "r") as json_data:
        data: AsepriteData = json.loads(json_data.read())
    
    layers = data["meta"]["layers"]
    layer_combinations: list[set[str]] = [
        # All layers except those with color
        set([layer["name"] for layer in layers if ("color" not in layer) or (layer["color"] is None)]),
        # All layers
        set([layer["name"] for layer in layers]),
    ]
    
    # Remove all frames that aren't in the first layer and remove the layer data from their filenames
    filtered_frames = [f for f in data["frames"] if f["filename"].endswith(f"|{layers[0]['name']}")]
    
    animation_frames_count = get_animation_frame_count(data["meta"]["frameTags"])
    normal_frames_count = get_normal_frame_count(data["meta"]["frameTags"])
    print(f"Animation frames count: {animation_frames_count}, normal frames count: {normal_frames_count}")
    
    out_img = Image.new("RGBA", (animation_frames_count * frame_width * len(layer_combinations), normal_frames_count * frame_height))
    
    for (i, combination) in enumerate(layer_combinations):
        combination_x = animation_frames_count * frame_width * i
        
        layer_combination_img = preprocess_combine_layers(img, layers, data["frames"], combination)
        
        animation_frame_set = get_animation_frames(filtered_frames, layer_combination_img, data["meta"]["frameTags"])
        print(f"Extracted {len(animation_frame_set)} animation frame types")
        
        normal_frame_set = get_normal_frames(filtered_frames, layer_combination_img, data["meta"]["frameTags"])
        print(f"Extracted {len(normal_frame_set)} normal frames")
        
        for (row, normal_frame) in enumerate(normal_frame_set):
            for x in range(frame_width):
                for y in range(frame_height):
                    pixel = cast(tuple[int, int, int], normal_frame.getpixel((x, y)))
                    hex_color = f"#{pixel[0]:02x}{pixel[1]:02x}{pixel[2]:02x}ff"
                    
                    if hex_color in animation_frame_set:
                        anim_frames = animation_frame_set[hex_color].frames
                        for anim_frame_index in range(animation_frames_count):
                            anim_pixel = cast(tuple[int, int, int], anim_frames[anim_frame_index].getpixel((x, y)))
                            out_img.putpixel((combination_x + anim_frame_index * frame_width + x, row * frame_height + y), anim_pixel)
                    else:
                        for anim_frame_index in range(animation_frames_count):
                            out_img.putpixel((combination_x + anim_frame_index * frame_width + x, row * frame_height + y), pixel)

    out_img.save(output_path)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python conveyor_postprocess.py <input.png> <input.json> <output.png>")
        sys.exit(1)
    input_image_path = sys.argv[1]
    input_json_path = sys.argv[2]
    output_path = sys.argv[3]
    postprocess_conveyor_sprite(input_image_path, input_json_path, output_path)