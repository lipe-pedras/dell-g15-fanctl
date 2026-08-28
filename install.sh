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
"$(dirname "$(readlink -f "$0")")/install_icons.sh" > /dev/null
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
