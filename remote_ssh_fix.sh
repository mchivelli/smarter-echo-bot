#!/usr/bin/env bash
#
# Remote SSH Recovery Script
# Attempts to fix SSH connection issues remotely
#

PI_IP="192.168.0.40"
USERNAME="prototype"

echo "🔧 Attempting to fix SSH on $PI_IP..."
echo "This script will try multiple approaches to restore SSH connectivity."
echo ""

# Method 1: Try to wake up SSH with different connection attempts
echo "Method 1: Attempting connection variations..."
for i in {1..5}; do
    echo "  Attempt $i: Basic connection test..."
    timeout 5 ssh -o ConnectTimeout=3 -o BatchMode=yes $USERNAME@$PI_IP "echo 'SSH working'" 2>/dev/null && {
        echo "✅ SSH is working!"
        exit 0
    }
    sleep 2
done

# Method 2: Try to trigger SSH restart via network
echo ""
echo "Method 2: Attempting to trigger SSH restart..."
for port in 22 2222 2200; do
    echo "  Trying port $port..."
    timeout 3 nc -z $PI_IP $port 2>/dev/null && echo "  Port $port is open"
done

# Method 3: Try different SSH protocols and options
echo ""
echo "Method 3: Trying different SSH configurations..."
SSH_OPTIONS=(
    "-o Protocol=2 -o Ciphers=aes128-ctr"
    "-o KexAlgorithms=diffie-hellman-group1-sha1"
    "-o HostKeyAlgorithms=+ssh-rsa"
    "-o PubkeyAcceptedKeyTypes=+ssh-rsa"
    "-1"
    "-2"
)

for opts in "${SSH_OPTIONS[@]}"; do
    echo "  Trying: ssh $opts $USERNAME@$PI_IP"
    timeout 10 ssh $opts -o ConnectTimeout=5 -o BatchMode=yes $USERNAME@$PI_IP "echo 'Connected with: $opts'" 2>/dev/null && {
        echo "✅ SSH working with options: $opts"
        echo "Use this command: ssh $opts $USERNAME@$PI_IP"
        exit 0
    }
done

# Method 4: Check if Pi is responding to other services
echo ""
echo "Method 4: Checking Pi responsiveness..."
ping -c 3 $PI_IP >/dev/null 2>&1 && {
    echo "✅ Pi is responding to ping"
} || {
    echo "❌ Pi is not responding to ping - may need power cycle"
    exit 1
}

# Method 5: Try to connect via different methods
echo ""
echo "Method 5: Alternative connection methods..."

# Check if VNC is available
timeout 3 nc -z $PI_IP 5900 2>/dev/null && echo "✅ VNC port 5900 is open - try VNC viewer"

# Check if HTTP is available
timeout 3 nc -z $PI_IP 80 2>/dev/null && echo "✅ HTTP port 80 is open"

# Method 6: Wait and retry (sometimes SSH recovers on its own)
echo ""
echo "Method 6: Waiting for automatic recovery..."
echo "The Pi may have auto-recovery mechanisms. Waiting 2 minutes..."

for i in {1..24}; do
    printf "  Waiting... %d/120 seconds\r" $((i*5))
    sleep 5
    
    # Try SSH every 30 seconds
    if [ $((i % 6)) -eq 0 ]; then
        timeout 5 ssh -o ConnectTimeout=3 -o BatchMode=yes $USERNAME@$PI_IP "echo 'SSH recovered'" 2>/dev/null && {
            echo ""
            echo "✅ SSH has recovered automatically!"
            exit 0
        }
    fi
done

echo ""
echo "❌ All remote recovery methods failed."
echo ""
echo "🔧 Next steps:"
echo "1. Power cycle the Pi (unplug for 30 seconds)"
echo "2. Wait 5 minutes after power on"
echo "3. Try SSH again"
echo "4. If still failing, you'll need physical access (monitor + keyboard)"
echo ""
echo "💡 The updated setup script now includes SSH recovery mechanisms"
echo "   to prevent this issue in future installations." 