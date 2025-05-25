# Wyoming Satellite for Home Assistant

Official Wyoming Satellite setup for Raspberry Pi with ReSpeaker 2Mic HAT, following the [official tutorial](https://www.home-assistant.io/voice_control/install_wake_word_add_on/).

## 🎯 **Quick Start**

### **Prerequisites**
- Raspberry Pi Zero 2 W (or any Raspberry Pi)
- ReSpeaker 2Mic HAT (or USB microphone)
- Raspberry Pi OS 64-bit Lite (freshly flashed)
- SSH enabled with username/password configured

### **Installation**

```bash
# 1. SSH into your Pi
ssh username@raspberrypi.local

# 2. Clone this repository
git clone https://github.com/mchivelli/wyoming-satellite.git
cd wyoming-satellite

# 3. Run the setup script
chmod +x setup_wyoming_official.sh
./setup_wyoming_official.sh
```

**Note:** The script will install ReSpeaker drivers and reboot. After reboot, run the script again to complete setup.

## 📋 **What Gets Installed**

1. **Wyoming Satellite** - Voice satellite service
2. **OpenWakeWord** - Local wake word detection ("Ok Nabu")
3. **LED Service** - Visual feedback on ReSpeaker HAT
4. **System Services** - Auto-start on boot

## 🏗️ **Architecture**

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  ReSpeaker HAT  │────▶│ Wyoming         │────▶│ Home Assistant  │
│  Microphone     │     │ Satellite       │     │ Assist Pipeline │
│  + Speaker      │◀────│ + OpenWakeWord  │◀────│                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │
         │                       │
         ▼                       ▼
    ┌─────────┐          ┌─────────────┐
    │  LEDs   │          │ TCP:10700   │
    │ Status  │          │ Wyoming     │
    └─────────┘          │ Protocol    │
                         └─────────────┘
```

## 🔧 **Manual Setup Steps**

If you prefer manual installation, follow the [official tutorial](https://www.home-assistant.io/voice_control/install_wake_word_add_on/) or these steps:

### 1. Install Dependencies
```bash
sudo apt-get update
sudo apt-get install --no-install-recommends git python3-venv
```

### 2. Clone and Install Wyoming
```bash
git clone https://github.com/rhasspy/wyoming-satellite.git
cd wyoming-satellite/

# Install ReSpeaker drivers (requires reboot)
sudo bash etc/install-respeaker-drivers.sh
sudo reboot

# After reboot, continue:
cd wyoming-satellite/
python3 -m venv .venv
.venv/bin/pip3 install --upgrade pip wheel setuptools
.venv/bin/pip3 install -f 'https://synesthesiam.github.io/prebuilt-apps/' -e '.[all]'
```

### 3. Test Audio Devices
```bash
# Find microphone
arecord -L

# Test recording
arecord -D plughw:CARD=seeed2micvoicec,DEV=0 -r 16000 -c 1 -f S16_LE -t wav -d 5 test.wav

# Test playback
aplay -D plughw:CARD=seeed2micvoicec,DEV=0 test.wav
```

### 4. Run Satellite
```bash
script/run \
  --name 'my satellite' \
  --uri 'tcp://0.0.0.0:10700' \
  --mic-command 'arecord -D plughw:CARD=seeed2micvoicec,DEV=0 -r 16000 -c 1 -f S16_LE -t raw' \
  --snd-command 'aplay -D plughw:CARD=seeed2micvoicec,DEV=0 -r 22050 -c 1 -f S16_LE -t raw'
```

## 🚀 **Service Management**

```bash
# View logs
journalctl -u wyoming-satellite.service -f

# Restart services
sudo systemctl restart wyoming-satellite.service

# Check status
sudo systemctl status wyoming-satellite.service wyoming-openwakeword.service 2mic_leds.service

# Stop services
sudo systemctl stop wyoming-satellite.service
```

## 🏠 **Home Assistant Integration**

1. Go to **Settings** → **Devices & Services**
2. Look for **"Discovered"** Wyoming Protocol device
3. Click **"Configure"** and submit
4. Select the area for your satellite
5. Test with **"Ok Nabu"** followed by a command

## 🎤 **Audio Enhancements**

Add these flags to improve audio quality:

```bash
--mic-auto-gain 5      # Automatic gain control (0-31)
--mic-noise-suppression 2  # Noise suppression (0-4)
--mic-volume-multiplier 2  # Double microphone volume
```

## 💡 **LED Indicators**

The ReSpeaker 2Mic HAT LEDs show:
- **Blue** - Listening for wake word
- **Green** - Wake word detected
- **Yellow** - Processing command
- **Red** - Error state

## 📋 **Troubleshooting**

### No Audio
```bash
# Check audio devices
arecord -L
aplay -L

# Test microphone
arecord -D default -r 16000 -c 1 -f S16_LE test.wav

# Check service logs
journalctl -u wyoming-satellite.service -n 50
```

### Wake Word Not Working
```bash
# Check openWakeWord service
sudo systemctl status wyoming-openwakeword.service

# View wake word logs
journalctl -u wyoming-openwakeword.service -f
```

### Pi Crashes During Setup
- Use a good power supply (5V 2.5A minimum)
- Ensure adequate cooling
- Try the lightweight setup: `setup_wyoming_lite.sh`

## 🔗 **Resources**

- [Official Tutorial](https://www.home-assistant.io/voice_control/install_wake_word_add_on/)
- [Wyoming Protocol](https://github.com/rhasspy/wyoming)
- [OpenWakeWord](https://github.com/rhasspy/wyoming-openwakeword)
- [ReSpeaker Drivers](https://github.com/respeaker/seeed-voicecard)

## 📝 **License**

MIT License - See LICENSE file 