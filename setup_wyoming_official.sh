#!/bin/bash

# Wyoming Satellite Setup - Following Official Tutorial
# For Raspberry Pi Zero 2 W with ReSpeaker 2Mic HAT

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Wyoming Satellite Setup - Official Tutorial${NC}"
echo -e "${YELLOW}For Raspberry Pi Zero 2 W with ReSpeaker 2Mic HAT${NC}"
echo ""

# Check if running as regular user
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please run as regular user, not root!${NC}"
   exit 1
fi

USER_HOME=$HOME
CURRENT_USER=$(whoami)

# Step 1: Install system dependencies
echo -e "${GREEN}Step 1: Installing system dependencies...${NC}"
sudo apt-get update
sudo apt-get install --no-install-recommends git python3-venv

# Step 2: Clone wyoming-satellite repository
echo -e "${GREEN}Step 2: Cloning wyoming-satellite repository...${NC}"
cd $USER_HOME
if [ ! -d "wyoming-satellite" ]; then
    git clone https://github.com/rhasspy/wyoming-satellite.git
fi

# Step 3: Install ReSpeaker drivers
echo -e "${GREEN}Step 3: Installing ReSpeaker drivers...${NC}"
echo -e "${YELLOW}This will take a long time and require a reboot${NC}"
cd wyoming-satellite/

# Check if drivers are already installed
if ! lsmod | grep -q "snd_soc_wm8960"; then
    sudo bash etc/install-respeaker-drivers.sh
    echo -e "${RED}Drivers installed! System will reboot in 10 seconds...${NC}"
    echo -e "${YELLOW}After reboot, run this script again to continue setup${NC}"
    sleep 10
    sudo reboot
else
    echo -e "${GREEN}ReSpeaker drivers already installed, continuing...${NC}"
fi

# Step 4: Create virtual environment and install Wyoming
echo -e "${GREEN}Step 4: Setting up Python environment...${NC}"
cd $USER_HOME/wyoming-satellite/
python3 -m venv .venv
.venv/bin/pip3 install --upgrade pip
.venv/bin/pip3 install --upgrade wheel setuptools
.venv/bin/pip3 install -f 'https://synesthesiam.github.io/prebuilt-apps/' -e '.[all]'

# Step 5: Test installation
echo -e "${GREEN}Step 5: Testing installation...${NC}"
if script/run --help > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Wyoming satellite installed successfully${NC}"
else
    echo -e "${RED}✗ Installation failed${NC}"
    exit 1
fi

# Step 6: Audio device detection
echo -e "${GREEN}Step 6: Detecting audio devices...${NC}"
echo -e "${YELLOW}Available microphones:${NC}"
arecord -L | grep -E "^(default|plughw|hw):"

echo ""
echo -e "${YELLOW}Available speakers:${NC}"
aplay -L | grep -E "^(default|plughw|hw):"

# For ReSpeaker 2Mic HAT, the device should be:
MIC_DEVICE="plughw:CARD=seeed2micvoicec,DEV=0"
SPK_DEVICE="plughw:CARD=seeed2micvoicec,DEV=0"

echo ""
echo -e "${GREEN}Using ReSpeaker 2Mic HAT devices:${NC}"
echo "Microphone: $MIC_DEVICE"
echo "Speaker: $SPK_DEVICE"

# Step 7: Test audio
echo -e "${GREEN}Step 7: Testing audio recording and playback...${NC}"
echo -e "${YELLOW}Recording 5 seconds - please say something...${NC}"
arecord -D $MIC_DEVICE -r 16000 -c 1 -f S16_LE -t wav -d 5 test.wav

echo -e "${YELLOW}Playing back recording...${NC}"
aplay -D $SPK_DEVICE test.wav

# Step 8: Create systemd service
echo -e "${GREEN}Step 8: Creating systemd service...${NC}"
sudo tee /etc/systemd/system/wyoming-satellite.service > /dev/null << EOF
[Unit]
Description=Wyoming Satellite
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=$USER_HOME/wyoming-satellite/script/run --name '$(hostname)' --uri 'tcp://0.0.0.0:10700' --mic-command 'arecord -D $MIC_DEVICE -r 16000 -c 1 -f S16_LE -t raw' --snd-command 'aplay -D $SPK_DEVICE -r 22050 -c 1 -f S16_LE -t raw'
WorkingDirectory=$USER_HOME/wyoming-satellite
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
EOF

# Step 9: Install openWakeWord (optional but recommended)
echo -e "${GREEN}Step 9: Installing openWakeWord for local wake word detection...${NC}"
sudo apt-get install --no-install-recommends libopenblas-dev

cd $USER_HOME
if [ ! -d "wyoming-openwakeword" ]; then
    git clone https://github.com/rhasspy/wyoming-openwakeword.git
fi

cd wyoming-openwakeword
script/setup

# Create openWakeWord service
sudo tee /etc/systemd/system/wyoming-openwakeword.service > /dev/null << EOF
[Unit]
Description=Wyoming openWakeWord

[Service]
Type=simple
ExecStart=$USER_HOME/wyoming-openwakeword/script/run --uri 'tcp://127.0.0.1:10400'
WorkingDirectory=$USER_HOME/wyoming-openwakeword
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
EOF

# Update satellite service to use wake word
sudo tee /etc/systemd/system/wyoming-satellite.service > /dev/null << EOF
[Unit]
Description=Wyoming Satellite
Wants=network-online.target
After=network-online.target
Requires=wyoming-openwakeword.service

[Service]
Type=simple
ExecStart=$USER_HOME/wyoming-satellite/script/run --name '$(hostname)' --uri 'tcp://0.0.0.0:10700' --mic-command 'arecord -D $MIC_DEVICE -r 16000 -c 1 -f S16_LE -t raw' --snd-command 'aplay -D $SPK_DEVICE -r 22050 -c 1 -f S16_LE -t raw' --wake-uri 'tcp://127.0.0.1:10400' --wake-word-name 'ok_nabu'
WorkingDirectory=$USER_HOME/wyoming-satellite
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
EOF

# Step 10: Install LED service for 2Mic HAT
echo -e "${GREEN}Step 10: Installing LED service for visual feedback...${NC}"
cd $USER_HOME/wyoming-satellite/examples
python3 -m venv --system-site-packages .venv
.venv/bin/pip3 install --upgrade pip
.venv/bin/pip3 install --upgrade wheel setuptools
.venv/bin/pip3 install 'wyoming==1.5.2'

# Install GPIO packages if needed
sudo apt-get install -y python3-spidev python3-gpiozero

# Create LED service
sudo tee /etc/systemd/system/2mic_leds.service > /dev/null << EOF
[Unit]
Description=2Mic LEDs

[Service]
Type=simple
ExecStart=$USER_HOME/wyoming-satellite/examples/.venv/bin/python3 2mic_service.py --uri 'tcp://127.0.0.1:10500'
WorkingDirectory=$USER_HOME/wyoming-satellite/examples
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
EOF

# Final satellite service with LED support
sudo tee /etc/systemd/system/wyoming-satellite.service > /dev/null << EOF
[Unit]
Description=Wyoming Satellite
Wants=network-online.target
After=network-online.target
Requires=wyoming-openwakeword.service
Requires=2mic_leds.service

[Service]
Type=simple
ExecStart=$USER_HOME/wyoming-satellite/script/run --name '$(hostname)' --uri 'tcp://0.0.0.0:10700' --mic-command 'arecord -D $MIC_DEVICE -r 16000 -c 1 -f S16_LE -t raw' --snd-command 'aplay -D $SPK_DEVICE -r 22050 -c 1 -f S16_LE -t raw' --wake-uri 'tcp://127.0.0.1:10400' --wake-word-name 'ok_nabu' --event-uri 'tcp://127.0.0.1:10500'
WorkingDirectory=$USER_HOME/wyoming-satellite
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
EOF

# Enable and start services
echo -e "${GREEN}Step 11: Enabling and starting services...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable --now wyoming-openwakeword.service
sudo systemctl enable --now 2mic_leds.service
sudo systemctl enable --now wyoming-satellite.service

# Check status
echo -e "${GREEN}Checking service status...${NC}"
sleep 3
sudo systemctl status wyoming-satellite.service wyoming-openwakeword.service 2mic_leds.service --no-pager

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. In Home Assistant, go to Settings > Devices & Services"
echo "2. Look for 'Discovered' Wyoming Protocol device"
echo "3. Click 'Configure' and follow the prompts"
echo "4. Test by saying 'Ok Nabu' followed by a command"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "View logs: journalctl -u wyoming-satellite.service -f"
echo "Restart: sudo systemctl restart wyoming-satellite.service"
echo "Stop: sudo systemctl stop wyoming-satellite.service" 