import math
from PIL import Image, ImageDraw

def cubic_bezier(p0, p1, p2, p3, t):
    """Calculate point on cubic bezier curve at parameter t (0 <= t <= 1)."""
    u = 1.0 - t
    tt = t * t
    uu = u * u
    uuu = uu * u
    ttt = tt * t
    
    x = uuu * p0[0] + 3 * uu * t * p1[0] + 3 * u * tt * p2[0] + ttt * p3[0]
    y = uuu * p0[1] + 3 * uu * t * p1[1] + 3 * u * tt * p2[1] + ttt * p3[1]
    return (x, y)

def sample_cubic_path(p0, p1, p2, p3, num_samples=100):
    return [cubic_bezier(p0, p1, p2, p3, i / (num_samples - 1)) for i in range(num_samples)]

def draw_thick_polyline(draw, points, width, color):
    # Draw segments with circle caps at joints for perfect smoothness
    radius = width / 2.0
    for pt in points:
        draw.ellipse([pt[0] - radius, pt[1] - radius, pt[0] + radius, pt[1] + radius], fill=color)
    for i in range(len(points) - 1):
        p_a = points[i]
        p_b = points[i + 1]
        draw.line([p_a, p_b], fill=color, width=int(width))

def draw_dashes_along_points(draw, points, dash_len, gap_len, width, color):
    radius = width / 2.0
    # Compute cumulative distances
    dist = 0.0
    dists = [0.0]
    for i in range(len(points) - 1):
        dx = points[i+1][0] - points[i][0]
        dy = points[i+1][1] - points[i][1]
        dist += math.hypot(dx, dy)
        dists.append(dist)
    
    total_len = dists[-1]
    cycle = dash_len + gap_len
    
    curr = 0.0
    while curr < total_len:
        d_start = curr
        d_end = min(curr + dash_len, total_len)
        
        # Find points for this dash
        dash_pts = []
        for i in range(len(points)):
            if dists[i] >= d_start and dists[i] <= d_end:
                dash_pts.append(points[i])
        if len(dash_pts) >= 2:
            for pt in dash_pts:
                draw.ellipse([pt[0] - radius, pt[1] - radius, pt[0] + radius, pt[1] + radius], fill=color)
            for i in range(len(dash_pts) - 1):
                draw.line([dash_pts[i], dash_pts[i+1]], fill=color, width=int(width))
        curr += cycle

def render_symbol(image, center_x, center_y, width, is_adaptive=False):
    """
    Renders the Sahyān route convergence mark into the given PIL image.
    scale is determined by width / 300.0
    """
    draw = ImageDraw.Draw(image)
    scale = width / 300.0
    
    # Base canonical coordinates relative to center (150, 100)
    # Origin top: (45, 45) -> delta (-105, -55)
    # Origin bottom: (45, 155) -> delta (-105, +55)
    # Hub: (150, 100) -> delta (0, 0)
    # Exit: (252, 100) -> delta (+102, 0)
    
    hub = (center_x, center_y)
    orig_top = (center_x - 105 * scale, center_y - 55 * scale)
    orig_bot = (center_x - 105 * scale, center_y + 55 * scale)
    exit_pt = (center_x + 98 * scale, center_y)
    
    # Cubic control points
    # top: 45, 45 -> c1 (95, 45) -> c2 (120, 78) -> hub (150, 100)
    top_c1 = (center_x - 55 * scale, center_y - 55 * scale)
    top_c2 = (center_x - 30 * scale, center_y - 22 * scale)
    
    # bot: 45, 155 -> c1 (95, 155) -> c2 (120, 122) -> hub (150, 100)
    bot_c1 = (center_x - 55 * scale, center_y + 55 * scale)
    bot_c2 = (center_x - 30 * scale, center_y + 22 * scale)
    
    top_pts = sample_cubic_path(orig_top, top_c1, top_c2, hub, num_samples=120)
    bot_pts = sample_cubic_path(orig_bot, bot_c1, bot_c2, hub, num_samples=120)
    
    # Right highway points
    num_right = 60
    right_pts = [(hub[0] + (exit_pt[0] - hub[0]) * (i / (num_right - 1)), hub[1]) for i in range(num_right)]
    
    # Colors
    c_mint = (167, 232, 210, 255)       # Soft Mint (#A7E8D2)
    c_emerald = (8, 76, 58, 255)         # Dark Emerald (#084C3A)
    c_deep = (11, 93, 75, 255)           # Deep Emerald (#0B5D4B)
    c_white = (255, 255, 255, 255)
    
    border_w = 26.0 * scale
    road_w = 19.5 * scale
    dash_w = 3.2 * scale
    
    # 1. Road Borders (Mint)
    draw_thick_polyline(draw, top_pts, border_w, c_mint)
    draw_thick_polyline(draw, bot_pts, border_w, c_mint)
    draw_thick_polyline(draw, right_pts, border_w, c_mint)
    
    # Arrow border
    arrow_tip_x = exit_pt[0] + 24 * scale
    arrow_back_x = exit_pt[0] - 8 * scale
    arrow_half_h = 22 * scale
    arrow_border_poly = [
        (arrow_back_x, hub[1] - arrow_half_h),
        (arrow_tip_x, hub[1]),
        (arrow_back_x, hub[1] + arrow_half_h),
    ]
    draw.polygon(arrow_border_poly, fill=c_mint)
    
    # 2. Road Surface (Dark Emerald)
    draw_thick_polyline(draw, top_pts, road_w, c_emerald)
    draw_thick_polyline(draw, bot_pts, road_w, c_emerald)
    draw_thick_polyline(draw, right_pts, road_w, c_emerald)
    
    arrow_inner_poly = [
        (arrow_back_x + 3 * scale, hub[1] - (arrow_half_h - 4 * scale)),
        (arrow_tip_x - 5 * scale, hub[1]),
        (arrow_back_x + 3 * scale, hub[1] + (arrow_half_h - 4 * scale)),
    ]
    draw.polygon(arrow_inner_poly, fill=c_emerald)
    
    # 3. Dashed lines (White)
    dash_len = 7.0 * scale
    gap_len = 8.0 * scale
    draw_dashes_along_points(draw, top_pts, dash_len, gap_len, dash_w, c_white)
    draw_dashes_along_points(draw, bot_pts, dash_len, gap_len, dash_w, c_white)
    draw_dashes_along_points(draw, right_pts, dash_len, gap_len, dash_w, c_white)
    
    # 4. Origin circular nodes
    orig_radius = 15.0 * scale
    for opt in [orig_top, orig_bot]:
        # outer mint
        draw.ellipse([opt[0] - orig_radius, opt[1] - orig_radius, opt[0] + orig_radius, opt[1] + orig_radius], fill=c_mint)
        # dark emerald rim
        inner_r = orig_radius * 0.75
        draw.ellipse([opt[0] - inner_r, opt[1] - inner_r, opt[0] + inner_r, opt[1] + inner_r], fill=c_emerald)
        # white center
        core_r = orig_radius * 0.40
        draw.ellipse([opt[0] - core_r, opt[1] - core_r, opt[0] + core_r, opt[1] + core_r], fill=c_white)
        
    # 5. Central Hub ring
    hub_radius = 23.0 * scale
    # Outer mint hub
    draw.ellipse([hub[0] - hub_radius, hub[1] - hub_radius, hub[0] + hub_radius, hub[1] + hub_radius], fill=c_mint)
    # Dark rim
    rim_r = hub_radius * 0.82
    draw.ellipse([hub[0] - rim_r, hub[1] - rim_r, hub[0] + rim_r, hub[1] + rim_r], fill=c_deep)
    # Emerald well
    well_r = hub_radius * 0.58
    draw.ellipse([hub[0] - well_r, hub[1] - well_r, hub[0] + well_r, hub[1] + well_r], fill=c_emerald)
    # White core
    core_hub_r = hub_radius * 0.30
    draw.ellipse([hub[0] - core_hub_r, hub[1] - core_hub_r, hub[0] + core_hub_r, hub[1] + core_hub_r], fill=c_white)

def generate_icons():
    # 1. Full 1024x1024 App Icon (Solid Deep Emerald background, RGB without alpha for iOS App Store)
    app_icon = Image.new('RGB', (1024, 1024), (11, 93, 75))
    render_symbol(app_icon, center_x=500, center_y=512, width=580, is_adaptive=False)
    app_icon.save('frontend/assets/branding/sahyan_app_icon.png', 'PNG')
    print('Generated sahyan_app_icon.png')
    
    # 2. 1024x1024 Android Adaptive Foreground (Transparent background)
    # Android safe area circle has radius 330px around (512, 512).
    # Width ~ 500px keeps entire symbol well within safe zone!
    adaptive = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    render_symbol(adaptive, center_x=505, center_y=512, width=510, is_adaptive=True)
    adaptive.save('frontend/assets/branding/sahyan_adaptive_foreground.png', 'PNG')
    print('Generated sahyan_adaptive_foreground.png')

if __name__ == '__main__':
    generate_icons()
