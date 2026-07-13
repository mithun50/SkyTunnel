#!/usr/bin/env python3
"""Generate SkyTunnel app icons in all required sizes."""

from PIL import Image, ImageDraw, ImageFont
import math
import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# Brand colors
PRIMARY = (108, 92, 231)       # #6C5CE7
ACCENT = (0, 206, 201)         # #00CEC9
SUCCESS = (0, 184, 148)        # #00B894
WHITE = (255, 255, 255)
DARK_BG = (22, 22, 42)         # #16162A


def lerp_color(c1, c2, t):
    """Linearly interpolate between two RGB colors."""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def draw_rounded_rect(draw, bbox, radius, fill):
    """Draw a rounded rectangle."""
    x0, y0, x1, y1 = bbox
    draw.rectangle([x0 + radius, y0, x1 - radius, y1], fill=fill)
    draw.rectangle([x0, y0 + radius, x1, y1 - radius], fill=fill)
    draw.pieslice([x0, y0, x0 + 2 * radius, y0 + 2 * radius], 180, 270, fill=fill)
    draw.pieslice([x1 - 2 * radius, y0, x1, y0 + 2 * radius], 270, 360, fill=fill)
    draw.pieslice([x0, y1 - 2 * radius, x0 + 2 * radius, y1], 90, 180, fill=fill)
    draw.pieslice([x1 - 2 * radius, y1 - 2 * radius, x1, y1], 0, 90, fill=fill)


def draw_lightning_bolt(img, cx, cy, size, color=WHITE):
    """Draw a stylized lightning bolt."""
    draw = ImageDraw.Draw(img)
    s = size
    # Lightning bolt polygon
    bolt = [
        (cx + s * 0.05, cy - s * 0.45),   # top
        (cx - s * 0.22, cy - s * 0.02),   # left middle
        (cx - s * 0.02, cy - s * 0.02),   # inner notch
        (cx - s * 0.28, cy + s * 0.45),   # bottom
        (cx + s * 0.22, cy + s * 0.02),   # right middle
        (cx + s * 0.02, cy + s * 0.02),   # inner notch right
    ]
    draw.polygon(bolt, fill=color)


def draw_signal_waves(img, cx, cy, size, color=PRIMARY):
    """Draw signal/broadcast waves to the right."""
    draw = ImageDraw.Draw(img)
    for i, (radius, alpha) in enumerate([(0.28, 180), (0.40, 120), (0.52, 60)]):
        r = int(size * radius)
        wave_color = (*color, alpha) if img.mode == 'RGBA' else color
        # Draw arc using ellipse
        bbox = [cx - r, cy - r, cx + r, cy + r]
        # We'll draw a semicircle on the right
        for deg_start, deg_end in [(300, 360), (0, 60)]:
            pass
        # Simple approach: draw arcs
        line_w = max(2, int(size * 0.02))
        draw.arc(bbox, -60, 60, fill=wave_color[:3], width=line_w)


def draw_connection_dots(draw, cx, cy, size, color=WHITE):
    """Draw connection endpoint dots."""
    dot_r = int(size * 0.035)
    # Left dot
    draw.ellipse([cx - size * 0.35 - dot_r, cy + size * 0.12 - dot_r,
                   cx - size * 0.35 + dot_r, cy + size * 0.12 + dot_r], fill=color)
    # Right dot
    draw.ellipse([cx + size * 0.35 - dot_r, cy + size * 0.12 - dot_r,
                   cx + size * 0.35 + dot_r, cy + size * 0.12 + dot_r], fill=color)


def generate_app_icon(size, output_path):
    """Generate a complete app icon at the given size."""
    # Create RGBA image for transparency support
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    padding = int(size * 0.03)
    corner_radius = int(size * 0.19)

    # Background gradient (approximate with bands)
    for y in range(padding, size - padding):
        t = (y - padding) / (size - 2 * padding)
        color = lerp_color(PRIMARY, ACCENT, t)
        draw.line([(padding, y), (size - padding, y)], fill=color)

    # Rounded corners mask - draw the background as rounded rect
    bg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)

    # Gradient rounded rect
    for y in range(size):
        t = y / size
        color = lerp_color(PRIMARY, ACCENT, t)
        bg_draw.line([(0, y), (size, y)], fill=(*color, 255))

    # Create rounded corner mask
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    draw_rounded_rect(mask_draw, (0, 0, size - 1, size - 1), corner_radius, 255)

    img.paste(bg, mask=mask)

    # Draw cable arc
    draw = ImageDraw.Draw(img)
    arc_cx = size // 2
    arc_cy = int(size * 0.6)
    arc_rx = int(size * 0.28)
    arc_ry = int(size * 0.32)
    line_w = max(2, int(size * 0.018))

    # Arc
    draw.arc(
        [arc_cx - arc_rx, arc_cy - arc_ry, arc_cx + arc_rx, arc_cy + arc_ry],
        180, 360, fill=(255, 255, 255, 50), width=line_w
    )

    # Lightning bolt
    bolt_size = size * 0.85
    draw_lightning_bolt(img, int(size * 0.48), int(size * 0.52), bolt_size, WHITE)

    # Signal waves
    draw_signal_waves(img, int(size * 0.62), int(size * 0.5), bolt_size, WHITE)

    # Connection dots
    draw = ImageDraw.Draw(img)
    draw_connection_dots(draw, size // 2, size // 2, bolt_size, WHITE)

    img.save(output_path, 'PNG')
    return img


def generate_favicon(size, output_path):
    """Generate a simpler favicon at small sizes."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Rounded background
    corner_radius = int(size * 0.22)
    for y in range(size):
        t = y / size
        color = lerp_color(PRIMARY, ACCENT, t)
        draw.line([(0, y), (size, y)], fill=(*color, 255))

    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    draw_rounded_rect(mask_draw, (0, 0, size - 1, size - 1), corner_radius, 255)

    bg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    for y in range(size):
        t = y / size
        color = lerp_color(PRIMARY, ACCENT, t)
        bg_draw.line([(0, y), (size, y)], fill=(*color, 255))

    img.paste(bg, mask=mask)

    # Simple lightning bolt
    draw_lightning_bolt(img, size // 2, int(size * 0.52), size * 0.9, WHITE)

    img.save(output_path, 'PNG')
    return img


def generate_store_icon(size, output_path):
    """Generate Play Store / Microsoft Store style icon (no rounded corners)."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Full bleed gradient
    for y in range(size):
        t = y / size
        color = lerp_color(PRIMARY, ACCENT, t)
        draw.line([(0, y), (size, y)], fill=(*color, 255))

    # Lightning bolt
    draw_lightning_bolt(img, size // 2, int(size * 0.5), size * 0.9, WHITE)

    img.save(output_path, 'PNG')
    return img


def main():
    print("Generating SkyTunnel icons...")

    # App icons for Flutter
    flutter_icon_sizes = {
        'app_icon.png': 1024,           # Main app icon
    }
    for name, size in flutter_icon_sizes.items():
        path = os.path.join(OUTPUT_DIR, name)
        generate_app_icon(size, path)
        print(f"  Generated {name} ({size}x{size})")

    # Windows icon sizes
    windows_sizes = [16, 24, 32, 48, 64, 128, 256]
    for s in windows_sizes:
        path = os.path.join(OUTPUT_DIR, f'windows_{s}.png')
        generate_app_icon(s, path)
        print(f"  Generated windows_{s}.png ({s}x{s})")

    # macOS icon sizes
    macos_sizes = [16, 32, 64, 128, 256, 512, 1024]
    for s in macos_sizes:
        path = os.path.join(OUTPUT_DIR, f'macos_{s}.png')
        generate_app_icon(s, path)
        print(f"  Generated macos_{s}.png ({s}x{s})")

    # Linux icon sizes
    linux_sizes = [16, 24, 32, 48, 64, 128, 256, 512]
    for s in linux_sizes:
        path = os.path.join(OUTPUT_DIR, f'linux_{s}.png')
        generate_app_icon(s, path)
        print(f"  Generated linux_{s}.png ({s}x{s})")

    # Favicons
    favicon_sizes = [16, 32, 48, 64, 128, 180, 192, 512]
    for s in favicon_sizes:
        path = os.path.join(OUTPUT_DIR, f'favicon_{s}.png')
        generate_favicon(s, path)
        print(f"  Generated favicon_{s}.png ({s}x{s})")

    # Store icons (no rounded corners)
    store_sizes = [500, 1024]
    for s in store_sizes:
        path = os.path.join(OUTPUT_DIR, f'store_{s}.png')
        generate_store_icon(s, path)
        print(f"  Generated store_{s}.png ({s}x{s})")

    # Watermark / banner images
    banner_w, banner_h = 1200, 630
    banner = Image.new('RGBA', (banner_w, banner_h), (0, 0, 0, 0))
    banner_draw = ImageDraw.Draw(banner)

    # Dark background
    for y in range(banner_h):
        t = y / banner_h
        c = lerp_color(DARK_BG, (30, 30, 60), t)
        banner_draw.line([(0, y), (banner_w, y)], fill=c)

    # Gradient accent line at bottom
    for y in range(banner_h - 6, banner_h):
        t = (y - (banner_h - 6)) / 6
        c = lerp_color(PRIMARY, ACCENT, t)
        banner_draw.line([(0, y), (banner_w, y)], fill=c)

    # Place icon on left
    icon = generate_app_icon(200, os.path.join(OUTPUT_DIR, '_temp_icon.png'))
    banner.paste(icon, (80, (banner_h - 200) // 2), icon)

    # Text area
    try:
        font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 64)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 24)
    except (OSError, IOError):
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()

    # "Sky" in gradient (approximate with primary)
    banner_draw.text((320, banner_h // 2 - 70), "Sky", fill=PRIMARY, font=font_large)
    banner_draw.text((448, banner_h // 2 - 70), "Tunnel", fill=(224, 224, 255), font=font_large)
    banner_draw.text((320, banner_h // 2 + 10), "ONE-CLICK GAME SERVER HOSTING", fill=(136, 136, 136), font=font_small)

    banner_path = os.path.join(OUTPUT_DIR, 'banner.png')
    banner.convert('RGB').save(banner_path, 'PNG')
    print(f"  Generated banner.png ({banner_w}x{banner_h})")

    # OG image (social media share)
    og_w, og_h = 1200, 630
    og = Image.new('RGB', (og_w, og_h), DARK_BG)
    og_draw = ImageDraw.Draw(og)

    # Subtle gradient overlay
    for y in range(og_h):
        t = y / og_h
        c = lerp_color((18, 18, 38), (28, 28, 55), t)
        og_draw.line([(0, y), (og_w, y)], fill=c)

    # Large centered icon
    icon_large = generate_app_icon(300, os.path.join(OUTPUT_DIR, '_temp_icon_large.png'))
    og.paste(icon_large, ((og_w - 300) // 2, 60), icon_large)

    # Title
    try:
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 56)
        font_sub = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 22)
    except (OSError, IOError):
        font_title = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    og_draw.text((og_w // 2 - 190, 400), "SkyTunnel", fill=WHITE, font=font_title)
    og_draw.text((og_w // 2 - 210, 470), "One-click game server hosting via ngrok", fill=(160, 160, 160), font=font_sub)

    og_path = os.path.join(OUTPUT_DIR, 'og_image.png')
    og.save(og_path, 'PNG')
    print(f"  Generated og_image.png ({og_w}x{og_h})")

    # Clean up temp files
    for f in ['_temp_icon.png', '_temp_icon_large.png']:
        p = os.path.join(OUTPUT_DIR, f)
        if os.path.exists(p):
            os.remove(p)

    # Create ICO file for Windows
    ico_images = []
    for s in [16, 24, 32, 48, 64, 128, 256]:
        ico_images.append(generate_app_icon(s, os.path.join(OUTPUT_DIR, f'_ico_{s}.png')))

    ico_path = os.path.join(OUTPUT_DIR, 'app_icon.ico')
    ico_images[-1].save(ico_path, format='ICO',
                        sizes=[(s, s) for s in [16, 24, 32, 48, 64, 128, 256]])
    print(f"  Generated app_icon.ico")

    # Clean up temp ICO files
    for s in [16, 24, 32, 48, 64, 128, 256]:
        p = os.path.join(OUTPUT_DIR, f'_ico_{s}.png')
        if os.path.exists(p):
            os.remove(p)

    print("\nAll icons generated successfully!")


if __name__ == '__main__':
    main()
