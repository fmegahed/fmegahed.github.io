# type: ignore
# flake8: noqa
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#| echo: false

from PIL import Image, ImageDraw, ImageFont

# Load original image
image_path = "figs/microstructure_001.png"  # Update if needed
original_img = Image.open(image_path).convert("RGB")

# Step 1: Resize to 250x250
resized_img = original_img.resize((250, 250))
resized_gray = resized_img.convert("L")

# Step 2: Save resized original image
resized_img.save("figs/microstructure_original_250.png")

# Step 3: Save grayscale image
resized_gray.save("figs/microstructure_grayscale_250.png")

# Step 4: Create grayscale image with pixel overlays
overlay_img = resized_gray.convert("RGB")
draw = ImageDraw.Draw(overlay_img)

# Load a readable font (fallback to default if unavailable)
try:
    font = ImageFont.truetype("DejaVuSansMono.ttf", 8)
except:
    font = ImageFont.load_default()

width, height = overlay_img.size
counter = 0

for y in range(height):
    for x in range(width):
        # Draw a 1×1 border (effectively coloring each pixel border)
        draw.rectangle([x, y, x + 1, y + 1], outline="black")

        # Every 20th pixel: draw grayscale value in red
        if counter % 20 == 0:
            pixel_val = resized_gray.getpixel((x, y))
            draw.text((x, y), str(pixel_val), fill="red", font=font)
        counter += 1

# Save the overlay image
overlay_img.save("figs/microstructure_matrix_overlay_250.png")




#
#
#
#
#
