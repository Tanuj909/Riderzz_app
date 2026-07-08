import os

color_map = {
    # Primary & Dark Reds
    "0xFF7E22CE": "0xFFE31C2E",
    "0xFF9D4EDD": "0xFFE31C2E",
    "0xFF7C3AED": "0xFFE31C2E",
    "0xFF1A3D6B": "0xFFE31C2E",
    "0xFF581C87": "0xFFAE1220",
    "0xFF2563A8": "0xFFAE1220",
    
    # Red Tints (replacing purple/blue tints)
    "0xFFF3E8FF": "0xFFFDEBEC",
    "0xFFF5F3FF": "0xFFFDEBEC",
    "0xFFE8F0FB": "0xFFFDEBEC",
    
    # Texts and Blacks
    "0xFF1A2233": "0xFF121214", # Black
    "0xFF6B7785": "0xFF6C6F79", # Ink Dim
    "0xFFA2A5AE": "0xFFA2A5AE", # Ink Faint
    
    # Borders & Surfaces
    "0xFFE9ECF0": "0xFFE7E7EB", # Border
    "0xFFE2E8F0": "0xFFE7E7EB",
    "0xFFF1F5F9": "0xFFF1F1F4", # Surface-2
    "0xFFF7F8FA": "0xFFF6F6F8", # Bg
    
    # Status Colors (Good)
    "0xFF0F9B6E": "0xFF1C9A5B",
    "0xFFE6F7F2": "0xFFE7F7EF",
    
    # Status Colors (Warn)
    "0xFFF97316": "0xFFB9700A",
    "0xFFFFF3E8": "0xFFFCF0DC",
    
    # Status Colors (Bad)
    "0xFFFEF2F2": "0xFFFDEBEC", # Bad Tint (Wait, Bad is Red, Bad tint is Red Tint)
}

def replace_in_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    new_content = content
    for old_color, new_color in color_map.items():
        new_content = new_content.replace(old_color, new_color)
        
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            replace_in_file(os.path.join(root, file))
