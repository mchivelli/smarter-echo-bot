# Wyoming Satellite Auto-Setup

Automated setup script for Wyoming Satellite on Raspberry Pi with Home Assistant integration.

## Features

- 🎤 **Complete Audio Setup** - Automatic microphone and speaker configuration
- 🔊 **ReSpeaker Support** - Full support for 2Mic/4Mic HATs with LED indicators
- 🗣️ **Wake Word Detection** - Local wake word processing with openWakeWord
- 🏠 **Home Assistant Ready** - Instant discovery via Wyoming Protocol
- 🔄 **Resume After Reboot** - Handles driver installation reboots gracefully
- 🎯 **Smart Defaults** - Works out-of-the-box with common hardware
- 🛠️ **Easy Customization** - Simple configuration file for tweaking settings

## Quick Start

### 1. Flash Raspberry Pi OS

Use Raspberry Pi Imager to flash **Raspberry Pi OS Lite (64-bit)** with:
- Username/password set
- WiFi configured
- SSH enabled

### 2. Install Git and Clone Repository

```bash
# SSH into your Pi
ssh pi@raspberrypi.local

# Install Git (required for Raspberry Pi OS Lite)
sudo apt update && sudo apt install -y git

# Clone this repository
git clone https://github.com/mchivelli/smarter-echo-bot.git
cd smarter-echo-bot

# Make script executable
chmod +x setup_wyoming_satellite.sh

# Run the setup (will reboot once for drivers)
sudo ./setup_wyoming_satellite.sh
```

### 3. Configure Home Assistant

After setup completes:
1. Go to Home Assistant → Settings → Devices & Services
2. Look for "Discovered" Wyoming Protocol device
3. Click "Configure" and assign to an area

## Configuration

Edit `wyoming.conf` before running the script to customize:

```bash
# Satellite name (appears in Home Assistant)
SATELLITE_NAME="living-room"

# Audio devices
MIC_DEVICE="plughw:CARD=seeed2micvoicec,DEV=0"
SND_DEVICE="plughw:CARD=seeed2micvoicec,DEV=0"

# Wake word (ok_nabu, hey_jarvis, alexa, etc.)
WAKE_WORD="ok_nabu"

# Audio enhancements
MIC_AUTO_GAIN="5"         # 0-31 (louder)
MIC_NOISE_SUPPRESSION="2"  # 0-4 (more suppression)
LED_BRIGHTNESS="10"        # 1-31 (brighter)
```

## Supported Hardware

### Microphones
- ✅ ReSpeaker 2Mic HAT
- ✅ ReSpeaker 4Mic HAT
- ✅ USB microphones
- ✅ Generic ALSA devices

### Raspberry Pi Models
- ✅ Raspberry Pi Zero 2 W
- ✅ Raspberry Pi 3B/3B+
- ✅ Raspberry Pi 4B
- ✅ Raspberry Pi 5

## Environment Variables

You can also configure via environment variables:

```bash
export WYOMING_SATELLITE_NAME="kitchen"
export WYOMING_MIC_DEVICE="default"
export WYOMING_WAKE_WORD="hey_jarvis"
sudo -E ./setup_wyoming_satellite.sh
```

## Finding Audio Devices

To list available devices:

```bash
# Microphones
arecord -L

# Speakers
aplay -L
```

Look for devices starting with `plughw:` or use `default`.

## Services Created

The script creates three systemd services:

- `wyoming-satellite.service` - Main satellite service
- `wyoming-openwakeword.service` - Wake word detection
- `2mic_leds.service` - LED indicators (ReSpeaker only)

### Useful Commands

```bash
# View logs
journalctl -u wyoming-satellite.service -f

# Restart services
sudo systemctl restart wyoming-satellite.service

# Check status
sudo systemctl status wyoming-satellite.service

# Stop all services
sudo systemctl stop wyoming-satellite.service
```

## Troubleshooting

### No Audio Response

1. Check audio devices are correct:
   ```bash
   arecord -L
   aplay -L
   ```

2. Test recording:
   ```bash
   arecord -D YOUR_DEVICE -d 5 test.wav
   aplay -D YOUR_DEVICE test.wav
   ```

### Service Won't Start

Check logs for errors:
```bash
journalctl -u wyoming-satellite.service -n 50
```

### Wake Word Not Working

1. Check openWakeWord is running:
   ```bash
   sudo systemctl status wyoming-openwakeword.service
   ```

2. Try different wake words in `wyoming.conf`

### LED Not Working

Ensure SPI is enabled:
```bash
sudo raspi-config
# Interface Options → SPI → Enable
```

## Uninstalling

An uninstall script is created at `~/uninstall_wyoming.sh`:

```bash
sudo ~/uninstall_wyoming.sh
```

This removes all services but keeps the code directories.

## Manual Installation Progress

If the script is interrupted, it tracks progress in `/var/lib/wyoming-satellite-setup/`. 
Delete this directory to start fresh:

```bash
sudo rm -rf /var/lib/wyoming-satellite-setup/
```

## Advanced Configuration

### Custom Wake Words

Add more wake words by editing the openWakeWord service or using custom models.

### Audio Processing

Adjust in `wyoming.conf`:
- `MIC_AUTO_GAIN`: 0-31 dBFS
- `MIC_NOISE_SUPPRESSION`: 0-4
- `MIC_VOLUME_MULTIPLIER`: e.g., 1.5 for 50% louder
- `SND_VOLUME_MULTIPLIER`: e.g., 0.8 for 20% quieter

### Multiple Satellites

Run the script with different names:
```bash
WYOMING_SATELLITE_NAME="bedroom" sudo -E ./setup_wyoming_satellite.sh
WYOMING_SATELLITE_NAME="kitchen" sudo -E ./setup_wyoming_satellite.sh
```

## Integration with Home Assistant

Once connected, you can:
- Use in Assist pipelines
- Create automations triggered by wake words
- Send TTS messages to specific satellites
- Monitor satellite status

Example automation:
```yaml
automation:
  - alias: "Satellite LED Feedback"
    trigger:
      - platform: event
        event_type: wyoming_satellite_active
    action:
      - service: light.turn_on
        target:
          entity_id: light.room_led
```

## Contributing

Pull requests welcome! Please test on your hardware and update the compatibility list.

## License

MIT License - See LICENSE file

## Credits

Based on the official [Wyoming Satellite](https://github.com/rhasspy/wyoming-satellite) tutorial. 