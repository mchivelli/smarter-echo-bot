#!/usr/bin/env bash
#
# Wyoming Satellite Test Script
# Tests all components of the Wyoming Satellite setup
#

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/wyoming.conf"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo -e "${YELLOW}Config file not found, using defaults${NC}"
    MIC_DEVICE="plughw:CARD=seeed2micvoicec,DEV=0"
    SND_DEVICE="plughw:CARD=seeed2micvoicec,DEV=0"
    SATELLITE_NAME="my-satellite"
    WAKE_WORD="ok_nabu"
fi

echo -e "${GREEN}Wyoming Satellite Test Suite${NC}"
echo "=============================="
echo ""

# Test 1: Check services
echo -e "${YELLOW}Test 1: Checking Services${NC}"
SERVICES="wyoming-satellite.service wyoming-openwakeword.service"
[[ "$MIC_DEVICE" == *"seeed"* ]] && SERVICES="$SERVICES 2mic_leds.service"

ALL_GOOD=true
for service in $SERVICES; do
    if systemctl is-active --quiet "$service"; then
        echo -e "  ✅ $service is ${GREEN}active${NC}"
    else
        echo -e "  ❌ $service is ${RED}not running${NC}"
        ALL_GOOD=false
    fi
done

if ! $ALL_GOOD; then
    echo -e "${RED}Some services are not running. Check logs with:${NC}"
    echo "  journalctl -u SERVICE_NAME -n 50"
    exit 1
fi

# Test 2: Audio devices
echo ""
echo -e "${YELLOW}Test 2: Audio Devices${NC}"
echo "  Microphone: $MIC_DEVICE"
echo "  Speaker: $SND_DEVICE"

# Test 3: Network connectivity
echo ""
echo -e "${YELLOW}Test 3: Network Connectivity${NC}"
if timeout 2 bash -c "</dev/tcp/127.0.0.1/10700"; then
    echo -e "  ✅ Wyoming Satellite port ${GREEN}10700 is open${NC}"
else
    echo -e "  ❌ Wyoming Satellite port ${RED}10700 is not accessible${NC}"
fi

if timeout 2 bash -c "</dev/tcp/127.0.0.1/10400"; then
    echo -e "  ✅ OpenWakeWord port ${GREEN}10400 is open${NC}"
else
    echo -e "  ❌ OpenWakeWord port ${RED}10400 is not accessible${NC}"
fi

# Test 4: Audio recording
echo ""
echo -e "${YELLOW}Test 4: Audio Recording (3 seconds)${NC}"
echo "  Speak into the microphone now..."

if arecord -D "$MIC_DEVICE" -r 16000 -c 1 -f S16_LE -t wav -d 3 /tmp/wyoming_test.wav 2>/dev/null; then
    echo -e "  ✅ Recording ${GREEN}successful${NC}"
    FILE_SIZE=$(stat -c%s "/tmp/wyoming_test.wav")
    if [[ $FILE_SIZE -gt 1000 ]]; then
        echo -e "  ✅ Audio data ${GREEN}captured${NC} (${FILE_SIZE} bytes)"
    else
        echo -e "  ❌ Audio file ${RED}too small${NC} (${FILE_SIZE} bytes)"
    fi
else
    echo -e "  ❌ Recording ${RED}failed${NC}"
fi

# Test 5: Audio playback
echo ""
echo -e "${YELLOW}Test 5: Audio Playback${NC}"
echo "  Playing back your recording..."

if [[ -f /tmp/wyoming_test.wav ]]; then
    if aplay -D "$SND_DEVICE" /tmp/wyoming_test.wav 2>/dev/null; then
        echo -e "  ✅ Playback ${GREEN}successful${NC}"
    else
        echo -e "  ❌ Playback ${RED}failed${NC}"
    fi
    rm -f /tmp/wyoming_test.wav
fi

# Test 6: Wake word
echo ""
echo -e "${YELLOW}Test 6: Wake Word Detection${NC}"
echo "  Configured wake word: ${GREEN}${WAKE_WORD}${NC}"
echo "  Say '${WAKE_WORD}' now and watch the logs..."
echo ""
echo "  To monitor wake word detection:"
echo "    journalctl -u wyoming-openwakeword.service -f"

# Test 7: Home Assistant connection
echo ""
echo -e "${YELLOW}Test 7: Home Assistant Discovery${NC}"
echo "  Satellite name: ${GREEN}${SATELLITE_NAME}${NC}"
echo "  Wyoming port: ${GREEN}10700${NC}"
echo ""
echo "  In Home Assistant:"
echo "  1. Go to Settings > Devices & Services"
echo "  2. Look for 'Wyoming Protocol' in discovered section"
echo "  3. Click 'Configure' to add the satellite"

# Summary
echo ""
echo "=============================="
echo -e "${GREEN}Test Summary${NC}"
echo "=============================="
echo ""
echo "If all tests passed:"
echo "  1. Your Wyoming Satellite is ready!"
echo "  2. Configure it in Home Assistant"
echo "  3. Test by saying '${WAKE_WORD}' followed by a command"
echo ""
echo "Monitor all services with:"
echo "  watch 'systemctl status wyoming-*.service 2mic_leds.service'"
echo ""
echo "View combined logs with:"
echo "  journalctl -u 'wyoming-*' -u '2mic_leds' -f" 