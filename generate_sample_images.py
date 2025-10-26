#!/usr/bin/env python3
"""
Style Examples Sample Image Generator
Creates placeholder sample images for VividAI style examples
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFont
import random

# Style definitions with colors and characteristics
STYLES = {
    "professional_headshot": {
        "name": "Professional Headshot",
        "bg_color": (240, 240, 240),
        "text_color": (50, 50, 50),
        "accent_color": (0, 100, 200),
        "description": "Clean corporate style"
    },
    "executive_portrait": {
        "name": "Executive Portrait",
        "bg_color": (220, 220, 220),
        "text_color": (30, 30, 30),
        "accent_color": (100, 50, 0),
        "description": "Premium executive style"
    },
    "renaissance_art": {
        "name": "Renaissance Art",
        "bg_color": (200, 180, 160),
        "text_color": (80, 60, 40),
        "accent_color": (150, 100, 50),
        "description": "Classical painting style"
    },
    "oil_painting": {
        "name": "Oil Painting",
        "bg_color": (180, 160, 140),
        "text_color": (60, 40, 20),
        "accent_color": (120, 80, 40),
        "description": "Traditional oil painting"
    },
    "anime_cartoon": {
        "name": "Anime/Cartoon",
        "bg_color": (255, 240, 240),
        "text_color": (100, 50, 150),
        "accent_color": (255, 100, 150),
        "description": "Japanese anime style"
    },
    "disney_pixar": {
        "name": "Disney/Pixar",
        "bg_color": (255, 250, 240),
        "text_color": (50, 100, 200),
        "accent_color": (255, 200, 100),
        "description": "Disney animation style"
    },
    "comic_book": {
        "name": "Comic Book",
        "bg_color": (255, 255, 255),
        "text_color": (0, 0, 0),
        "accent_color": (255, 0, 0),
        "description": "Bold comic style"
    },
    "cyberpunk_future": {
        "name": "Cyberpunk Future",
        "bg_color": (20, 20, 40),
        "text_color": (0, 255, 255),
        "accent_color": (255, 0, 255),
        "description": "Futuristic cyberpunk"
    },
    "fantasy_warrior": {
        "name": "Fantasy Warrior",
        "bg_color": (40, 20, 20),
        "text_color": (255, 200, 100),
        "accent_color": (200, 100, 50),
        "description": "Epic fantasy style"
    },
    "vintage_portrait": {
        "name": "Vintage Portrait",
        "bg_color": (200, 180, 160),
        "text_color": (100, 80, 60),
        "accent_color": (150, 120, 90),
        "description": "Classic vintage style"
    },
    "film_noir": {
        "name": "Film Noir",
        "bg_color": (20, 20, 20),
        "text_color": (200, 200, 200),
        "accent_color": (255, 255, 255),
        "description": "Dramatic film noir"
    },
    "minimalist": {
        "name": "Minimalist",
        "bg_color": (250, 250, 250),
        "text_color": (100, 100, 100),
        "accent_color": (0, 0, 0),
        "description": "Clean minimalist style"
    },
    "abstract_art": {
        "name": "Abstract Art",
        "bg_color": (240, 240, 255),
        "text_color": (100, 50, 200),
        "accent_color": (255, 100, 200),
        "description": "Modern abstract art"
    },
    "watercolor": {
        "name": "Watercolor",
        "bg_color": (255, 255, 240),
        "text_color": (100, 150, 200),
        "accent_color": (200, 150, 100),
        "description": "Soft watercolor style"
    },
    "sketch_drawing": {
        "name": "Sketch Drawing",
        "bg_color": (255, 255, 255),
        "text_color": (50, 50, 50),
        "accent_color": (0, 0, 0),
        "description": "Hand-drawn sketch"
    },
    "pop_art": {
        "name": "Pop Art",
        "bg_color": (255, 255, 0),
        "text_color": (255, 0, 0),
        "accent_color": (0, 0, 255),
        "description": "Vibrant pop art"
    }
}

def create_sample_image(style_key, style_info, size=(360, 360)):
    """Create a sample image for a given style"""
    
    # Create image with background color
    img = Image.new('RGB', size, style_info['bg_color'])
    draw = ImageDraw.Draw(img)
    
    # Try to load a font, fallback to default
    try:
        font_large = ImageFont.truetype("Arial.ttf", 24)
        font_medium = ImageFont.truetype("Arial.ttf", 18)
        font_small = ImageFont.truetype("Arial.ttf", 14)
    except:
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    # Draw style-specific elements
    if "professional" in style_key or "executive" in style_key:
        # Professional: Clean lines and geometric shapes
        draw.rectangle([50, 50, size[0]-50, size[1]-50], outline=style_info['accent_color'], width=3)
        draw.rectangle([80, 80, size[0]-80, size[1]-80], outline=style_info['text_color'], width=2)
        
    elif "renaissance" in style_key or "oil" in style_key:
        # Artistic: Curved lines and organic shapes
        for i in range(5):
            x1 = random.randint(20, size[0]-40)
            y1 = random.randint(20, size[1]-40)
            x2 = x1 + random.randint(20, 60)
            y2 = y1 + random.randint(20, 60)
            draw.arc([x1, y1, x2, y2], 0, 180, fill=style_info['accent_color'], width=3)
            
    elif "anime" in style_key or "disney" in style_key:
        # Cartoon: Rounded shapes and bright colors
        draw.ellipse([50, 50, size[0]-50, size[1]-50], outline=style_info['accent_color'], width=4)
        draw.ellipse([80, 80, size[0]-80, size[1]-80], outline=style_info['text_color'], width=2)
        
    elif "comic" in style_key:
        # Comic: Bold lines and sharp angles
        draw.line([(20, 20), (size[0]-20, 20)], fill=style_info['accent_color'], width=5)
        draw.line([(20, size[1]-20), (size[0]-20, size[1]-20)], fill=style_info['accent_color'], width=5)
        draw.line([(20, 20), (20, size[1]-20)], fill=style_info['accent_color'], width=5)
        draw.line([(size[0]-20, 20), (size[0]-20, size[1]-20)], fill=style_info['accent_color'], width=5)
        
    elif "cyberpunk" in style_key:
        # Cyberpunk: Neon lines and futuristic elements
        for i in range(8):
            x1 = random.randint(10, size[0]-10)
            y1 = random.randint(10, size[1]-10)
            x2 = random.randint(10, size[0]-10)
            y2 = random.randint(10, size[1]-10)
            draw.line([(x1, y1), (x2, y2)], fill=style_info['accent_color'], width=2)
            
    elif "fantasy" in style_key:
        # Fantasy: Ornate patterns and mystical elements
        center_x, center_y = size[0]//2, size[1]//2
        for i in range(6):
            angle = i * 60
            x2 = center_x + int(100 * math.cos(math.radians(angle)))
            y2 = center_y + int(100 * math.sin(math.radians(angle)))
            draw.line([(center_x, center_y), (x2, y2)], fill=style_info['accent_color'], width=3)
            
    elif "vintage" in style_key or "film" in style_key:
        # Vintage: Sepia tones and classic elements
        draw.rectangle([30, 30, size[0]-30, size[1]-30], outline=style_info['text_color'], width=2)
        draw.rectangle([60, 60, size[0]-60, size[1]-60], outline=style_info['accent_color'], width=1)
        
    elif "minimalist" in style_key:
        # Minimalist: Simple lines and clean spaces
        draw.line([(size[0]//4, size[1]//4), (3*size[0]//4, 3*size[1]//4)], fill=style_info['text_color'], width=2)
        draw.line([(3*size[0]//4, size[1]//4), (size[0]//4, 3*size[1]//4)], fill=style_info['text_color'], width=2)
        
    elif "abstract" in style_key:
        # Abstract: Random shapes and colors
        for i in range(10):
            x1 = random.randint(20, size[0]-40)
            y1 = random.randint(20, size[1]-40)
            x2 = x1 + random.randint(10, 30)
            y2 = y1 + random.randint(10, 30)
            draw.ellipse([x1, y1, x2, y2], outline=style_info['accent_color'], width=2)
            
    elif "watercolor" in style_key:
        # Watercolor: Soft, flowing shapes
        for i in range(6):
            x = random.randint(50, size[0]-50)
            y = random.randint(50, size[1]-50)
            radius = random.randint(20, 60)
            draw.ellipse([x-radius, y-radius, x+radius, y+radius], outline=style_info['accent_color'], width=1)
            
    elif "sketch" in style_key:
        # Sketch: Hand-drawn lines and shading
        for i in range(15):
            x1 = random.randint(10, size[0]-10)
            y1 = random.randint(10, size[1]-10)
            x2 = random.randint(10, size[0]-10)
            y2 = random.randint(10, size[1]-10)
            draw.line([(x1, y1), (x2, y2)], fill=style_info['text_color'], width=1)
            
    elif "pop" in style_key:
        # Pop Art: Bold colors and patterns
        for i in range(4):
            x = i * size[0] // 4
            y = i * size[1] // 4
            draw.rectangle([x, y, x + size[0]//4, y + size[1]//4], outline=style_info['accent_color'], width=3)
    
    # Add style name text
    text_bbox = draw.textbbox((0, 0), style_info['name'], font=font_medium)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]
    
    text_x = (size[0] - text_width) // 2
    text_y = size[1] - 60
    
    # Draw text background
    draw.rectangle([text_x-10, text_y-5, text_x+text_width+10, text_y+text_height+5], 
                   fill=style_info['bg_color'], outline=style_info['text_color'])
    
    # Draw text
    draw.text((text_x, text_y), style_info['name'], fill=style_info['text_color'], font=font_medium)
    
    # Add description
    desc_bbox = draw.textbbox((0, 0), style_info['description'], font=font_small)
    desc_width = desc_bbox[2] - desc_bbox[0]
    desc_x = (size[0] - desc_width) // 2
    desc_y = text_y + text_height + 10
    
    draw.text((desc_x, desc_y), style_info['description'], fill=style_info['text_color'], font=font_small)
    
    return img

def main():
    """Generate all sample images"""
    
    # Create output directory
    output_dir = "sample_images"
    os.makedirs(output_dir, exist_ok=True)
    
    print("Generating sample images for VividAI style examples...")
    
    # Generate images for each style
    for style_key, style_info in STYLES.items():
        print(f"Generating {style_key}...")
        
        # Create the image
        img = create_sample_image(style_key, style_info)
        
        # Save the image
        filename = f"sample_{style_key}.jpg"
        filepath = os.path.join(output_dir, filename)
        img.save(filepath, "JPEG", quality=85)
        
        print(f"  Saved: {filepath}")
    
    print(f"\nGenerated {len(STYLES)} sample images in '{output_dir}' directory")
    print("\nNext steps:")
    print("1. Add these images to your Xcode project")
    print("2. Place them in Assets.xcassets")
    print("3. Update image names in StyleExample.swift if needed")
    print("4. Test the implementation")

if __name__ == "__main__":
    import math
    main()
