import sys
from PIL import Image, ImageDraw

def remove_white_background(input_path, output_path, threshold=10):
    try:
        img = Image.open(input_path)
        img = img.convert("RGBA")
        
        # Flood fill from corners with transparency
        # Target color is (255, 255, 255, 0) -> Transparent
        
        width, height = img.size
        corners = [(0, 0), (width-1, 0), (0, height-1), (width-1, height-1)]
        
        for corner in corners:
            # Check if the corner is already transparent
            if img.getpixel(corner)[3] == 0:
                continue
                
            # Check if the corner is "white-ish" or "creme-ish" before filling
            # We'll be more permissive with what we consider "background" to start with,
            # but the floodfill threshold will limit how far it spreads.
            pixel = img.getpixel(corner)
            print(f"Processing corner {corner} with color {pixel}")
            
            # If it's not dark, we assume it's background
            if pixel[0] > 200 and pixel[1] > 200 and pixel[2] > 200:
                 ImageDraw.floodfill(img, corner, (255, 255, 255, 0), thresh=threshold)

        img.save(output_path, "PNG")
        print(f"Successfully processed {input_path} to {output_path}")
    except Exception as e:
        print(f"Error processing image: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python process_icon.py <input_file> <output_file>")
        sys.exit(1)
    
    remove_white_background(sys.argv[1], sys.argv[2])
