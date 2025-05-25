#!/bin/bash

# Wyoming Satellite Setup Script - LITE Version for Pi Zero 2 W
# This version is optimized for low-resource devices

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Wyoming Satellite LITE Setup - Optimized for Pi Zero 2 W${NC}"
echo -e "${YELLOW}This version avoids resource-intensive operations${NC}"
echo ""

# Simple logging
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as regular user
if [ "$EUID" -eq 0 ]; then 
   error "Please run as regular user, not root!"
   exit 1
fi

# Step 1: System preparation
log "📦 Preparing system (minimal updates)..."
sudo apt update
# Skip full upgrade to avoid crashes
sudo apt install -y git python3 python3-pip python3-venv curl wget build-essential portaudio19-dev

# Step 2: Create virtual environment
log "🐍 Creating Python virtual environment..."
python3 -m venv ~/wyoming-env
source ~/wyoming-env/bin/activate

# Step 3: Install minimal dependencies first
log "📦 Installing core dependencies..."
pip install --upgrade pip wheel setuptools

# Step 4: Install Wyoming without heavy dependencies
log "🛰️ Installing Wyoming Satellite (minimal)..."

# Install numpy from wheel (no compilation)
pip install --only-binary :all: numpy

# Skip scipy for now - it's optional and resource-intensive
log "⚠️ Skipping scipy installation (optional, resource-intensive)"

# Install core Wyoming packages
pip install --no-deps wyoming-satellite
pip install --no-deps wyoming

# Install lightweight dependencies
pip install async-timeout ifaddr pyring-buffer

# Install zeroconf with timeout
log "📦 Installing zeroconf (with safety timeout)..."
timeout 300 pip install --only-binary :all: zeroconf || {
    log "⚠️ Zeroconf binary not available, skipping..."
}

# Step 5: Install OpenWakeWord separately
log "🎤 Installing OpenWakeWord..."
pip install --extra-index-url https://google-coral.github.io/py-repo/ tflite_runtime
pip install --no-deps wyoming-openwakeword

# Step 6: Create simple test script
cat > ~/test_wyoming.py << 'EOF'
#!/usr/bin/env python3
import sys
try:
    import wyoming
    print("✅ Wyoming core: OK")
except:
    print("❌ Wyoming core: FAILED")
    
try:
    import wyoming_satellite
    print("✅ Wyoming satellite: OK")
except:
    print("❌ Wyoming satellite: FAILED")
    
try:
    import tflite_runtime
    print("✅ TFLite runtime: OK")
except:
    print("❌ TFLite runtime: FAILED")
EOF

chmod +x ~/test_wyoming.py

# Step 7: Create activation helper
cat > ~/activate_wyoming.sh << 'EOF'
#!/bin/bash
source ~/wyoming-env/bin/activate
echo "✅ Wyoming environment activated"
echo "Test with: python ~/test_wyoming.py"
EOF
chmod +x ~/activate_wyoming.sh

# Step 8: Create minimal systemd service
log "⚙️ Creating systemd services..."

sudo tee /etc/systemd/system/wyoming-satellite.service > /dev/null << EOF
[Unit]
Description=Wyoming Satellite
After=network.target

[Service]
Type=simple
User=$USER
Environment=PATH=/home/$USER/wyoming-env/bin
ExecStart=/home/$USER/wyoming-env/bin/python -m wyoming_satellite \
    --name "$(hostname)" \
    --uri tcp://0.0.0.0:10700 \
    --mic-command "arecord -D plughw:0,0 -r 16000 -c 1 -f S16_LE -t raw" \
    --snd-command "aplay -D plughw:0,0 -r 22050 -c 1 -f S16_LE -t raw"
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable wyoming-satellite

log "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Wait for Pi to stabilize (1-2 minutes)"
echo "2. Test installation: source ~/activate_wyoming.sh && python ~/test_wyoming.py"
echo "3. Install ReSpeaker drivers separately (when Pi is stable)"
echo "4. Start service: sudo systemctl start wyoming-satellite"
echo ""
echo "⚠️ Note: This LITE version skips some optional dependencies to prevent crashes" 