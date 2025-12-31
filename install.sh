#!/bin/bash
# Dell G15 Fan Control - Complete Installation Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║  Dell G15 Fan Control - Installation  ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}❌ Do not run as root/sudo${NC}"
   echo "The script will ask for sudo when needed"
   exit 1
fi

# Check for Rust
echo -e "${BLUE}[1/8]${NC} Checking for Rust/Cargo..."
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}❌ Rust not found${NC}"
    echo "Install at: https://rustup.rs/"
    exit 1
fi
echo -e "${GREEN}✓${NC} Rust found"

# Check for acpi_call module
echo -e "\n${BLUE}[2/8]${NC} Checking for acpi_call module..."
if [ ! -e /proc/acpi/call ]; then
    echo -e "${RED}❌ acpi_call module not found${NC}"
    echo ""
    echo "The acpi_call kernel module is required for fan control."
    echo "Install it with:"
    echo ""
    echo "  sudo apt install acpi-call-dkms"
    echo ""
    echo "After installation, load the module:"
    echo "  sudo modprobe acpi_call"
    echo ""
    echo "To load automatically on boot, add to /etc/modules:"
    echo "  echo 'acpi_call' | sudo tee -a /etc/modules"
    exit 1
fi
echo -e "${GREEN}✓${NC} acpi_call module found"

# Check and install system dependencies
echo -e "\n${BLUE}[3/8]${NC} Checking system dependencies..."
DEPS_TO_INSTALL=""
for pkg in libgtk-3-dev libglib2.0-dev libpango1.0-dev libcairo2-dev libgdk-pixbuf-2.0-dev libatk1.0-dev; do
    if ! dpkg -l 2>/dev/null | grep -q "^ii  $pkg"; then
        DEPS_TO_INSTALL="$DEPS_TO_INSTALL $pkg"
    fi
done

if [ -n "$DEPS_TO_INSTALL" ]; then
    echo -e "${YELLOW}→${NC} Installing:$DEPS_TO_INSTALL"
    sudo apt install -y $DEPS_TO_INSTALL
fi
echo -e "${GREEN}✓${NC} Dependencies OK"

# Build
echo -e "\n${BLUE}[4/8]${NC} Compiling fanctl..."
cd fanctl
cargo build --release --quiet
cd ..
echo -e "${GREEN}✓${NC} Build complete"

# Install binary
echo -e "\n${BLUE}[5/8]${NC} Installing binary..."
sudo install -m 755 fanctl/target/release/fanctl /usr/local/bin/fanctl
echo -e "${GREEN}✓${NC} Binary installed at /usr/local/bin/fanctl"

# Install icons
echo -e "\n${BLUE}[6/8]${NC} Installing icons..."
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$ICON_DIR"

# Fan Quiet (blue)
cat > "$ICON_DIR/fan-quiet.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="none" stroke="#3498db" stroke-width="2"/>
  <path d="M12,6 L12,10 M12,14 L12,18 M6,12 L10,12 M14,12 L18,12" stroke="#3498db" stroke-width="2" stroke-linecap="round"/>
  <circle cx="12" cy="12" r="2" fill="#3498db"/>
</svg>
EOF

# Fan Balanced (green)
cat > "$ICON_DIR/fan-balanced.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="none" stroke="#27ae60" stroke-width="2"/>
  <path d="M12,4 Q16,8 12,12 Q8,16 12,20 M4,12 Q8,8 12,12 Q16,16 20,12" fill="none" stroke="#27ae60" stroke-width="2" stroke-linecap="round"/>
  <circle cx="12" cy="12" r="2" fill="#27ae60"/>
</svg>
EOF

# Fan Performance (orange)
cat > "$ICON_DIR/fan-performance.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="none" stroke="#f39c12" stroke-width="2"/>
  <path d="M12,3 L12,8 M12,16 L12,21 M3,12 L8,12 M16,12 L21,12 M5,5 L8,8 M16,16 L19,19 M19,5 L16,8 M8,16 L5,19" stroke="#f39c12" stroke-width="2" stroke-linecap="round"/>
  <circle cx="12" cy="12" r="2.5" fill="#f39c12"/>
</svg>
EOF

# Fan G-Mode (red)
cat > "$ICON_DIR/fan-gmode.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="none" stroke="#e74c3c" stroke-width="2.5"/>
  <path d="M12,2 L12,7 M12,17 L12,22 M2,12 L7,12 M17,12 L22,12 M4,4 L7.5,7.5 M16.5,16.5 L20,20 M20,4 L16.5,7.5 M7.5,16.5 L4,20" stroke="#e74c3c" stroke-width="2.5" stroke-linecap="round"/>
  <circle cx="12" cy="12" r="3" fill="#e74c3c"/>
  <text x="12" y="15" font-family="sans-serif" font-size="8" font-weight="bold" text-anchor="middle" fill="white">G</text>
</svg>
EOF

gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
echo -e "${GREEN}✓${NC} Icons installed"

# Configure polkit
echo -e "\n${BLUE}[7/8]${NC} Configuring polkit (passwordless permissions)..."
POLKIT_RULE="/etc/polkit-1/rules.d/50-fanctl.rules"

if [ -f "$POLKIT_RULE" ]; then
    echo -e "${YELLOW}→${NC} Polkit rule already exists"
else
    echo -e "${YELLOW}→${NC} Creating polkit rule..."
    sudo tee "$POLKIT_RULE" > /dev/null << 'EOF'
/* Allow fanctl to run without password prompt */
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" &&
        action.lookup("program") == "/usr/local/bin/fanctl" &&
        subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
EOF
    sudo chmod 644 "$POLKIT_RULE"
    echo -e "${GREEN}✓${NC} Polkit rule created"
fi

# Test polkit
echo -e "${YELLOW}→${NC} Testing polkit..."
if pkexec fanctl status &>/dev/null; then
    echo -e "${GREEN}✓${NC} Polkit working"
else
    echo -e "${YELLOW}⚠${NC}  May need to restart for polkit to work"
fi

# Setup autostart
echo -e "\n${BLUE}[8/8]${NC} Configure auto-start?"
read -p "Start tray automatically on login? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[SsYy]$ ]]; then
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/dell-g15-fanctl.desktop << EOF
[Desktop Entry]
Type=Application
Name=Dell G15 Fan Control
Comment=System tray application for Dell G15 fan control
Exec=/usr/local/bin/fanctl tray
Icon=fan-balanced
Terminal=false
Categories=System;Utility;
StartupNotify=false
X-KDE-autostart-after=panel
EOF
    echo -e "${GREEN}✓${NC} Auto-start configured"
else
    echo -e "${YELLOW}⊘${NC} Auto-start skipped"
fi

# Done
echo -e "\n${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║     ✓ Installation Complete!            ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"
echo "Available commands:"
echo -e "  ${BLUE}pkexec fanctl quiet${NC}       - Quiet mode"
echo -e "  ${BLUE}pkexec fanctl balanced${NC}    - Balanced mode"
echo -e "  ${BLUE}pkexec fanctl performance${NC} - Performance mode"
echo -e "  ${BLUE}pkexec fanctl gmode${NC}       - Toggle G-Mode"
echo -e "  ${BLUE}pkexec fanctl status${NC}      - View status"
echo -e "  ${BLUE}fanctl tray${NC}               - Open system tray"
echo ""
echo "To start the tray now:"
echo -e "  ${YELLOW}fanctl tray &${NC}"
