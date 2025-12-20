
import os
from PIL import Image, ImageDraw, ImageFont

def create_gradient(width, height, start_color, end_color):
    base = Image.new('RGB', (width, height), start_color)
    top = Image.new('RGB', (width, height), end_color)
    mask = Image.new('L', (width, height))
    mask_data = []
    for y in range(height):
        for x in range(width):
            # Diagonal gradient
            p = (x + y) / (width + height)
            mask_data.append(int(255 * p))
    mask.putdata(mask_data)
    base.paste(top, (0, 0), mask)
    return base

def draw_icon():
    size = 1024
    # Colors: #4FACFE (79, 172, 254) to #00F2FE (0, 242, 254)
    # Let's try a slightly deeper blue/purple for better contrast?
    # iOS Blue: #007AFF to #5AC8FA
    c1 = (0, 122, 255)
    c2 = (90, 200, 250)
    
    # Or the SVG colors:
    # #4FACFE -> (79, 172, 254)
    # #00F2FE -> (0, 242, 254)
    c1 = (79, 172, 254)
    c2 = (0, 242, 254)

    img = create_gradient(size, size, c1, c2)
    
    # Create mask for rounded corners (Squircle-ish)
    mask = Image.new('L', (size, size), 0)
    draw_mask = ImageDraw.Draw(mask)
    draw_mask.rounded_rectangle([(0,0), (size, size)], radius=240, fill=255)
    
    # Apply rounded mask
    # Actually, for the PNG file used in flutter_launcher_icons involving Android/iOS,
    # the tool often wants a square image and handles rounding itself (especially Android adaptive).
    # But for Web and Windows (ico), we often want the transparency.
    # Let's make it rounded with transparent background.
    
    final_img = Image.new('RGBA', (size, size), (0,0,0,0))
    final_img.paste(img, (0,0), mask)
    
    draw = ImageDraw.Draw(final_img)
    
    
    # Helper to draw rounded lines
    def draw_rounded_line(draw, points, width, color):
        for i in range(len(points) - 1):
            draw.line([points[i], points[i+1]], fill=color, width=width)
        
        # Draw circles at all points for rounded caps/joints
        radius = width // 2
        for point in points:
            x, y = point
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)

    # Thickness 80
    w = 80
    color = (255, 255, 255)
    
    # <
    # (350, 312) -> (150, 512) -> (350, 712)
    draw_rounded_line(draw, [(350, 312), (150, 512), (350, 712)], w, color)
    
    # >
    # (674, 312) -> (874, 512) -> (674, 712)
    draw_rounded_line(draw, [(674, 312), (874, 512), (674, 712)], w, color)
    
    # /
    # (560, 260) -> (464, 764)
    draw_rounded_line(draw, [(560, 260), (464, 764)], w, color)

    if not os.path.exists('assets'):
        os.makedirs('assets')
        
    final_img.save('assets/icon.png')
    print("Icon generated at assets/icon.png")

if __name__ == "__main__":
    draw_icon()
