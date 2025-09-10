# There's probably a way to do this when creating the assets in aesprite, but I don't know how.

# Essentially, we use "frames" for the different conveyor types and "layers" for the different animation frames.
# This is the opposite of what aesprite expects, but meh. It's the only thing that worked for my workflow.

# To fix layering, we extract the final layer (lowest 16x16 image in each 16-pixel column) and layer it on top of every other layer in the frame.

# Because Godot wants animation frames in rows, we also transpose the frames and layers.
# To keep the animation moving forward, this also means flipping the order of the layers.

# Essentially:
# 1. Break the sprite into frames (16-pixel columns) which correspond to conveyor types
# 2. For each frame, extract the bottom layer (final 16x16 image in each column)
# 3. For each layer in the frame, composite the bottom layer on top of it
# 4. Save the modified sprite with transposed frames and layers

from PIL import Image
import sys
import os

def postprocess_conveyor_sprite(input_path, output_path, frame_width=16, frame_height=16):
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size

    num_frames = width // frame_width
    num_layers = height // frame_height - 1 # Exclude the bottom layer used for compositing

    # Create a new image to store the processed sprite
    out_img = Image.new("RGBA", (frame_height * num_layers, width))

    for frame_idx in range(num_frames):
        # Extract the bottom layer (final 16x16 image in the column)
        bottom_layer_y = num_layers * frame_height
        box = (
            frame_idx * frame_width,
            bottom_layer_y,
            (frame_idx + 1) * frame_width,
            bottom_layer_y + frame_height
        )
        bottom_layer = img.crop(box)

        # For each layer in the frame, composite the bottom layer on top
        for layer_idx in range(num_layers):
            layer_y = layer_idx * frame_height
            box = (
                frame_idx * frame_width,
                layer_y,
                (frame_idx + 1) * frame_width,
                layer_y + frame_height
            )
            layer = img.crop(box)
            composited = layer.copy()
            composited.alpha_composite(bottom_layer)
            
            frame_position = num_layers - 1 - layer_idx # Flip the order of layers
            out_img.paste(composited, (frame_position * frame_height, frame_idx * frame_width))

    out_img.save(output_path)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python conveyor_postprocess.py <input.png> <output.png>")
        sys.exit(1)
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    postprocess_conveyor_sprite(input_path, output_path)