#!/bin/bash

# Create simple icon SVGs for the fan control tray
# These will be installed to the system icon theme directories

ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$ICON_DIR"

# Fan Quiet (blue, slow)
cat > "$ICON_DIR/fan-quiet.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="none" stroke="#3498db" stroke-width="2"/>
  <path d="M12,6 L12,10 M12,14 L12,18 M6,12 L10,12 M14,12 L18,12" stroke="#3498db" stroke-width="2" stroke-linecap="round"/>
  <circle cx="12" cy="12" r="2" fill="#3498db"/>
</svg>
EOF

# Fan Balanced (green, moderate)
cat > "$ICON_DIR/fan-balanced.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="none" stroke="#27ae60" stroke-width="2"/>
  <path d="M12,4 Q16,8 12,12 Q8,16 12,20 M4,12 Q8,8 12,12 Q16,16 20,12" fill="none" stroke="#27ae60" stroke-width="2" stroke-linecap="round"/>
  <circle cx="12" cy="12" r="2" fill="#27ae60"/>
</svg>
EOF

# Fan Performance (orange/yellow, fast)
cat > "$ICON_DIR/fan-performance.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="none" stroke="#f39c12" stroke-width="2"/>
  <path d="M12,3 L12,8 M12,16 L12,21 M3,12 L8,12 M16,12 L21,12 M5,5 L8,8 M16,16 L19,19 M19,5 L16,8 M8,16 L5,19" stroke="#f39c12" stroke-width="2" stroke-linecap="round"/>
  <circle cx="12" cy="12" r="2.5" fill="#f39c12"/>
</svg>
EOF

# Fan G-Mode (red, maximum performance)
cat > "$ICON_DIR/fan-gmode.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="none" stroke="#e74c3c" stroke-width="2.5"/>
  <path d="M12,2 L12,7 M12,17 L12,22 M2,12 L7,12 M17,12 L22,12 M4,4 L7.5,7.5 M16.5,16.5 L20,20 M20,4 L16.5,7.5 M7.5,16.5 L4,20" stroke="#e74c3c" stroke-width="2.5" stroke-linecap="round"/>
  <circle cx="12" cy="12" r="3" fill="#e74c3c"/>
  <text x="12" y="15" font-family="sans-serif" font-size="8" font-weight="bold" text-anchor="middle" fill="white">G</text>
</svg>
EOF

echo "Icons created in $ICON_DIR"
echo "Updating icon cache..."
gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo "✓ Icons installed successfully!"
echo ""
echo "Icon mapping:"
echo "  • fan-quiet: Blue (Quiet mode)"
echo "  • fan-balanced: Green (Balanced mode)"
echo "  • fan-performance: Orange (Performance mode)"
echo "  • fan-gmode: Red with 'G' (G-Mode)"
