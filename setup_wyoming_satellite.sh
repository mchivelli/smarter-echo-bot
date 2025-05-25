#!/usr/bin/env bash
#
# Wyoming Satellite Auto-Setup Script
# This script automatically configures a Raspberry Pi as a Wyoming Satellite
# with ReSpeaker 2Mic HAT, wake word detection, and LED support
#
# Usage: 
#   1. Clone this to your Pi: git clone YOUR_REPO
#   2. Make executable: chmod +x setup_wyoming_satellite.sh
#   3. Run: sudo ./setup_wyoming_satellite.sh
#

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Load configuration file if it exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/wyoming.conf"

if [[ -f "$CONFIG_FILE" ]]; then
    echo -e "${GREEN}Loading configuration from ${CONFIG_FILE}${NC}"
    source "$CONFIG_FILE"
else
    echo -e "${YELLOW}No configuration file found at ${CONFIG_FILE}${NC}"
    echo -e "${YELLOW}Using default values or environment variables${NC}"
fi

# Configuration variables (modify these as needed)
SATELLITE_NAME="${WYOMING_SATELLITE_NAME:-${SATELLITE_NAME:-my-satellite}}"
MIC_DEVICE="${WYOMING_MIC_DEVICE:-${MIC_DEVICE:-plughw:CARD=seeed2micvoicec,DEV=0}}"
SND_DEVICE="${WYOMING_SND_DEVICE:-${SND_DEVICE:-plughw:CARD=seeed2micvoicec,DEV=0}}"
WAKE_WORD="${WYOMING_WAKE_WORD:-${WAKE_WORD:-ok_nabu}}"

# Auto-detect user home directory
CURRENT_USER=$(logname 2>/dev/null || echo "${SUDO_USER:-$(whoami)}")
DEFAULT_USER_HOME="/home/${CURRENT_USER}"
USER_HOME="${WYOMING_USER_HOME:-${USER_HOME:-$DEFAULT_USER_HOME}}"

# Validate USER_HOME exists
if [[ ! -d "$USER_HOME" ]]; then
    print_error "User home directory '$USER_HOME' does not exist!"
    print_error "Please set USER_HOME in wyoming.conf or as environment variable"
    exit 1
fi

MIC_AUTO_GAIN="${WYOMING_MIC_AUTO_GAIN:-${MIC_AUTO_GAIN:-5}}"
MIC_NOISE_SUPPRESSION="${WYOMING_MIC_NOISE_SUPPRESSION:-${MIC_NOISE_SUPPRESSION:-2}}"
LED_BRIGHTNESS="${WYOMING_LED_BRIGHTNESS:-${LED_BRIGHTNESS:-10}}"
MIC_VOLUME_MULTIPLIER="${WYOMING_MIC_VOLUME_MULTIPLIER:-${MIC_VOLUME_MULTIPLIER:-}}"
SND_VOLUME_MULTIPLIER="${WYOMING_SND_VOLUME_MULTIPLIER:-${SND_VOLUME_MULTIPLIER:-}}"

print_status "Using configuration:"
print_status "  User: $CURRENT_USER"
print_status "  Home: $USER_HOME"
print_status "  Satellite: $SATELLITE_NAME"
print_status "  Wake word: $WAKE_WORD"

# Create marker file to track installation progress
MARKER_DIR="/var/lib/wyoming-satellite-setup"
mkdir -p "$MARKER_DIR"

# Function to check if a step is already completed
is_step_completed() {
    [[ -f "$MARKER_DIR/$1.done" ]]
}

# Function to mark a step as completed
mark_step_completed() {
    touch "$MARKER_DIR/$1.done"
}

# Step 1: Install system dependencies
if ! is_step_completed "system_deps"; then
    print_status "Installing system dependencies..."
    apt-get update
    apt-get install -y --no-install-recommends \
        git \
        python3-venv \
        python3-spidev \
        python3-gpiozero \
        libopenblas-dev \
        alsa-utils
    mark_step_completed "system_deps"
else
    print_status "System dependencies already installed, skipping..."
fi

# Step 2: Clone Wyoming Satellite
if ! is_step_completed "wyoming_clone"; then
    print_status "Cloning Wyoming Satellite repository..."
    cd "$USER_HOME"
    if [[ ! -d "wyoming-satellite" ]]; then
        git clone https://github.com/rhasspy/wyoming-satellite.git
    fi
    mark_step_completed "wyoming_clone"
else
    print_status "Wyoming Satellite already cloned, skipping..."
fi

# Step 3: Install ReSpeaker drivers (if needed)
if ! is_step_completed "respeaker_drivers"; then
    if [[ "$MIC_DEVICE" == *"seeed"* ]]; then
        print_status "Installing ReSpeaker drivers (this will take a while)..."
        print_warning "Backing up SSH configuration to prevent connection issues..."
        
        # Backup SSH configuration
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        cp /etc/systemd/system/ssh.service /etc/systemd/system/ssh.service.backup 2>/dev/null || true
        
        # Create SSH recovery script
        cat > /tmp/restore_ssh.sh << 'SSH_RECOVERY_EOF'
#!/bin/bash
echo "Restoring SSH after driver installation..."
systemctl enable ssh
systemctl start ssh
# Force SSH to accept connections
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
systemctl restart ssh
echo "SSH recovery complete"
SSH_RECOVERY_EOF
        chmod +x /tmp/restore_ssh.sh
        
        # Create systemd service to run SSH recovery on boot
        cat > /etc/systemd/system/ssh-recovery.service << 'SSH_SERVICE_EOF'
[Unit]
Description=SSH Recovery After Driver Installation
After=network.target
Before=ssh.service

[Service]
Type=oneshot
ExecStart=/tmp/restore_ssh.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SSH_SERVICE_EOF
        
        systemctl enable ssh-recovery.service
        
        cd "$USER_HOME/wyoming-satellite"
        bash etc/install-respeaker-drivers.sh || true
        mark_step_completed "respeaker_drivers"
        
        print_warning "Drivers installed. System will reboot in 15 seconds..."
        print_warning "SSH recovery service has been installed to restore SSH after reboot."
        print_warning "After reboot, wait 3-5 minutes then try SSH again."
        print_warning "If SSH still fails, the Pi will auto-recover in 10 minutes."
        
        # Create a cron job for additional SSH recovery
        echo "*/2 * * * * root /tmp/restore_ssh.sh >/dev/null 2>&1" >> /etc/crontab
        
        sleep 15
        reboot
    else
        print_status "Non-ReSpeaker device detected, skipping driver installation..."
        mark_step_completed "respeaker_drivers"
    fi
fi

# Step 4: Install Wyoming Satellite Python packages
if ! is_step_completed "wyoming_packages"; then
    print_status "Installing Wyoming Satellite Python packages..."
    cd "$USER_HOME/wyoming-satellite"
    python3 -m venv .venv
    .venv/bin/pip3 install --upgrade pip wheel setuptools
    .venv/bin/pip3 install \
        -f 'https://synesthesiam.github.io/prebuilt-apps/' \
        -e '.[all]'
    mark_step_completed "wyoming_packages"
else
    print_status "Wyoming Satellite packages already installed, skipping..."
fi

# Step 5: Test audio devices
if ! is_step_completed "audio_test"; then
    print_status "Testing audio devices..."
    print_status "Available recording devices:"
    arecord -L | grep -E "^(default|plughw|hw):" || true
    
    print_status "Available playback devices:"
    aplay -L | grep -E "^(default|plughw|hw):" || true
    
    # Test recording
    print_status "Testing microphone (speak now for 3 seconds)..."
    if arecord -D "$MIC_DEVICE" -r 16000 -c 1 -f S16_LE -t wav -d 3 /tmp/test_audio.wav 2>/dev/null; then
        print_status "Microphone test successful"
        
        # Test playback
        print_status "Testing speaker playback..."
        if aplay -D "$SND_DEVICE" /tmp/test_audio.wav 2>/dev/null; then
            print_status "Speaker test successful"
        else
            print_warning "Speaker test failed, but continuing..."
        fi
    else
        print_warning "Microphone test failed, but continuing..."
    fi
    
    rm -f /tmp/test_audio.wav
    mark_step_completed "audio_test"
fi

# Step 6: Install openWakeWord
if ! is_step_completed "openwakeword"; then
    print_status "Installing openWakeWord..."
    cd "$USER_HOME"
    if [[ ! -d "wyoming-openwakeword" ]]; then
        git clone https://github.com/rhasspy/wyoming-openwakeword.git
    fi
    cd wyoming-openwakeword
    ./script/setup
    mark_step_completed "openwakeword"
else
    print_status "openWakeWord already installed, skipping..."
fi

# Step 7: Set up LED service
if ! is_step_completed "led_service" && [[ "$MIC_DEVICE" == *"seeed"* ]]; then
    print_status "Setting up LED service..."
    cd "$USER_HOME/wyoming-satellite/examples"
    python3 -m venv --system-site-packages .venv
    .venv/bin/pip3 install --upgrade pip wheel setuptools
    .venv/bin/pip3 install 'wyoming==1.5.2'
    
    # Also install pixel-ring for USB devices
    .venv/bin/pip3 install 'pixel-ring' || true
    mark_step_completed "led_service"
else
    print_status "LED service setup skipped..."
fi

# Step 8: Create systemd services
print_status "Creating systemd services..."

# OpenWakeWord service
cat > /etc/systemd/system/wyoming-openwakeword.service << EOF
[Unit]
Description=Wyoming openWakeWord
After=network-online.target

[Service]
Type=simple
ExecStart=${USER_HOME}/wyoming-openwakeword/script/run --uri 'tcp://127.0.0.1:10400'
WorkingDirectory=${USER_HOME}/wyoming-openwakeword
Restart=always
RestartSec=1
User=$(stat -c '%U' "$USER_HOME")

[Install]
WantedBy=default.target
EOF

# LED service (if ReSpeaker)
if [[ "$MIC_DEVICE" == *"seeed"* ]]; then
    cat > /etc/systemd/system/2mic_leds.service << EOF
[Unit]
Description=2Mic LEDs
After=wyoming-satellite.service

[Service]
Type=simple
ExecStart=${USER_HOME}/wyoming-satellite/examples/.venv/bin/python3 2mic_service.py --uri 'tcp://127.0.0.1:10500' --led-brightness ${LED_BRIGHTNESS}
WorkingDirectory=${USER_HOME}/wyoming-satellite/examples
Restart=always
RestartSec=1
User=$(stat -c '%U' "$USER_HOME")

[Install]
WantedBy=default.target
EOF
fi

# Wyoming Satellite service
if [[ "$MIC_DEVICE" == *"seeed"* ]]; then
    REQUIRES_LINE="Requires=wyoming-openwakeword.service 2mic_leds.service"
    EVENT_URI="--event-uri 'tcp://127.0.0.1:10500'"
else
    REQUIRES_LINE="Requires=wyoming-openwakeword.service"
    EVENT_URI=""
fi

# Add volume multipliers if set
VOLUME_ARGS=""
if [[ -n "$MIC_VOLUME_MULTIPLIER" ]]; then
    VOLUME_ARGS="${VOLUME_ARGS} --mic-volume-multiplier ${MIC_VOLUME_MULTIPLIER}"
fi
if [[ -n "$SND_VOLUME_MULTIPLIER" ]]; then
    VOLUME_ARGS="${VOLUME_ARGS} --snd-volume-multiplier ${SND_VOLUME_MULTIPLIER}"
fi

cat > /etc/systemd/system/wyoming-satellite.service << EOF
[Unit]
Description=Wyoming Satellite
Wants=network-online.target
After=network-online.target wyoming-openwakeword.service
${REQUIRES_LINE}

[Service]
Type=simple
ExecStart=${USER_HOME}/wyoming-satellite/script/run \\
  --debug \\
  --name '${SATELLITE_NAME}' \\
  --uri 'tcp://0.0.0.0:10700' \\
  --mic-command 'arecord -D ${MIC_DEVICE} -r 16000 -c 1 -f S16_LE -t raw' \\
  --snd-command 'aplay -D ${SND_DEVICE} -r 22050 -c 1 -f S16_LE -t raw' \\
  --wake-uri 'tcp://127.0.0.1:10400' \\
  --wake-word-name '${WAKE_WORD}' \\
  --mic-auto-gain ${MIC_AUTO_GAIN} \\
  --mic-noise-suppression ${MIC_NOISE_SUPPRESSION} \\
  ${EVENT_URI}${VOLUME_ARGS}
WorkingDirectory=${USER_HOME}/wyoming-satellite
Restart=always
RestartSec=1
User=$(stat -c '%U' "$USER_HOME")

[Install]
WantedBy=default.target
EOF

# Step 9: Enable and start services
print_status "Enabling and starting services..."
systemctl daemon-reload

# Enable services
systemctl enable wyoming-openwakeword.service
systemctl enable wyoming-satellite.service
[[ "$MIC_DEVICE" == *"seeed"* ]] && systemctl enable 2mic_leds.service

# Start services
systemctl start wyoming-openwakeword.service
sleep 2
[[ "$MIC_DEVICE" == *"seeed"* ]] && systemctl start 2mic_leds.service
sleep 2
systemctl start wyoming-satellite.service

# Step 10: Verify services are running
print_status "Verifying services..."
sleep 5

SERVICES="wyoming-satellite.service wyoming-openwakeword.service"
[[ "$MIC_DEVICE" == *"seeed"* ]] && SERVICES="$SERVICES 2mic_leds.service"

for service in $SERVICES; do
    if systemctl is-active --quiet "$service"; then
        print_status "$service is running ✓"
    else
        print_error "$service failed to start!"
        journalctl -u "$service" -n 20 --no-pager
    fi
done

# Step 11: Show completion message
print_status "Setup complete! 🎉"
echo ""
echo "========================================="
echo "Wyoming Satellite is now configured with:"
echo "  - Name: ${SATELLITE_NAME}"
echo "  - Wake word: ${WAKE_WORD}"
echo "  - Microphone: ${MIC_DEVICE}"
echo "  - Speaker: ${SND_DEVICE}"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. In Home Assistant, go to Settings > Devices & Services"
echo "2. Look for 'Discovered' Wyoming Protocol device"
echo "3. Click 'Configure' and follow the setup"
echo ""
echo "Useful commands:"
echo "  - View logs: journalctl -u wyoming-satellite.service -f"
echo "  - Restart service: sudo systemctl restart wyoming-satellite.service"
echo "  - Test wake word: Say '${WAKE_WORD}' followed by a command"
echo ""

# Create uninstall script
cat > "$USER_HOME/uninstall_wyoming.sh" << 'UNINSTALL_EOF'
#!/bin/bash
echo "Stopping and disabling services..."
sudo systemctl stop wyoming-satellite.service wyoming-openwakeword.service 2mic_leds.service 2>/dev/null
sudo systemctl disable wyoming-satellite.service wyoming-openwakeword.service 2mic_leds.service 2>/dev/null
sudo rm -f /etc/systemd/system/wyoming-satellite.service
sudo rm -f /etc/systemd/system/wyoming-openwakeword.service
sudo rm -f /etc/systemd/system/2mic_leds.service
sudo systemctl daemon-reload
echo "Removing marker files..."
sudo rm -rf /var/lib/wyoming-satellite-setup
echo "Wyoming Satellite services uninstalled!"
echo "To remove the code, manually delete:"
echo "  - $USER_HOME/wyoming-satellite"
echo "  - $USER_HOME/wyoming-openwakeword"
UNINSTALL_EOF

chmod +x "$USER_HOME/uninstall_wyoming.sh"
print_status "Uninstall script created at: $USER_HOME/uninstall_wyoming.sh" 