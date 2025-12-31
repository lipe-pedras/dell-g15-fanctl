# Dell G15 Fan Control 🌀

Fan controller for Dell G15 laptops on Linux (KDE/Ubuntu). Supports command-line interface and system tray integration.

## Features

### Four Fan Modes
- **🔵 Quiet** - Low noise fan profile, and CPU Governor on powersave
- **🟢 Balanced** - Medium noise fan profile, and CPU Governor on powersave
- **🟠 Performance** - Medium noise fan profile, and CPU Governor on performance
- **🔴 G-Mode** - Fans at maximum speed and CPU Governor on performance

### Dual Interface
- **CLI**: Quick control via terminal
- **System Tray**: KDE taskbar icon with interactive menu

### Features
- ✅ Mode switching without password (via polkit)
- ✅ Color-coded icons indicating current mode
- ✅ Optional auto-start
- ✅ Integrated CPU governor control

### Prerequisites
- Dell G15 (tested on Ubuntu 24/KDE Neon)
- Rust (install at [rustup.rs](https://rustup.rs))
- sudo access
- acpi_call kernel module

Install acpi_call:
```bash
sudo apt install acpi-call-dkms
sudo modprobe acpi_call
# To load on boot:
echo 'acpi_call' | sudo tee -a /etc/modules
```

### Automatic Installation

```bash
# Clone the repository
git clone <your-repo>
cd dell-g15-fanctl

# Run the installer (does everything automatically)
./install.sh
```

The script will:
1. ✓ Check for Rust
2. ✓ Check for acpi_call module
3. ✓ Check/install system dependencies
4. ✓ Compile the project
5. ✓ Install binary to `/usr/local/bin/`
6. ✓ Install SVG icons
7. ✓ Configure polkit (no password)
8. ✓ Configure auto-start (optional)

### Manual Installation

<details>
<summary>Click to see manual steps</summary>

```bash
# 1. Install acpi_call module
sudo apt install acpi-call-dkms
sudo modprobe acpi_call
# To load on boot:
echo 'acpi_call' | sudo tee -a /etc/modules

# 2. Install dependencies
sudo apt install libgtk-3-dev libglib2.0-dev libpango1.0-dev \
                 libcairo2-dev libgdk-pixbuf-2.0-dev libatk1.0-dev

# 3. Compile
cd fanctl
cargo build --release

# 4. Install binary
sudo install -m 755 target/release/fanctl /usr/local/bin/fanctl

# 5. Configure polkit
sudo tee /etc/polkit-1/rules.d/50-fanctl.rules > /dev/null << 'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" &&
        action.lookup("program") == "/usr/local/bin/fanctl" &&
        subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
EOF

# 6. Install icons (run script in icons/ folder)
cd ../icons
./install_icons.sh

# 7. Auto-start (optional)
cp dell-g15-fanctl.desktop ~/.config/autostart/
```
</details>

## 🚀 Usage

### Command Line

```bash
pkexec fanctl quiet         # Set Quiet mode
pkexec fanctl balanced      # Set Balanced mode
pkexec fanctl performance   # Set Performance mode
pkexec fanctl gmode         # Toggle G-Mode (on/off)
pkexec fanctl status        # Show if G-Mode is active
```

### System Tray

```bash
fanctl tray                 # Start tray icon
```

**How to use:**
1. Run `fanctl tray` (or let it auto-start)
2. Look for the colored icon in the system tray (near the clock)
3. Right-Click on the icon to open the menu
4. Select the desired mode
5. Icon changes color based on mode:
   - 🔵 Blue = Quiet
   - 🟢 Green = Balanced
   - 🟠 Orange = Performance
   - 🔴 Red = G-Mode

### How It Works

1. **ACPI Commands**: Sends specific payloads to `/proc/acpi/call`
2. **CPU Governor**: Adjusts governor (`powersave`/`performance`) in `/sys/devices/system/cpu/cpufreq`
3. **Polkit**: Allows privileged execution without password
4. **System Tray**: Uses `ksni` (KDE StatusNotifierItem) for KDE Plasma integration

### Modes and Effects

| Mode | ACPI Payload | CPU Governor |
|------|--------------|--------------|
| Quiet | `0xa3` | `powersave` |
| Balanced | `0xa0` | `powersave` |
| Performance | `0xa1` | `performance` |
| G-Mode | `0xab` | `performance` |

## 🗑️ Uninstallation

```bash
# Remove binary
sudo rm /usr/local/bin/fanctl

# Remove icons
rm -rf ~/.local/share/icons/hicolor/scalable/apps/fan-*.svg
gtk-update-icon-cache -f ~/.local/share/icons/hicolor

# Remove polkit
sudo rm /etc/polkit-1/rules.d/50-fanctl.rules

# Remove autostart
rm ~/.config/autostart/dell-g15-fanctl.desktop

# Stop process
pkill fanctl
```

## Dependencies

### Runtime
- Linux kernel with ACPI support
- Polkit
- KDE Plasma (for system tray)

### Build
- Rust 1.70+
- GTK 3 development libraries
- GLib development libraries

### Rust Crates
- `ksni` - KDE StatusNotifierItem protocol
- `gtk/glib` - GTK bindings
- `ctrlc` - Signal handling

## 🤝 Contributing

Feel free to open issues or pull requests!

## ⚠️ Warning

This software directly interacts with ACPI and hardware settings. Use at your own risk. Tested only on Dell G15 5525 with Ubuntu 24/KDE Neon.

## 📄 License

Provided "as is" for Dell G15 Linux users.
