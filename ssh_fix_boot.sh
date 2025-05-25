#!/bin/bash
# SSH Recovery Script for Boot Partition
# Place this file on the boot partition (Windows accessible)
# It will run automatically on boot to fix SSH

echo "🔧 SSH Recovery Script Starting..."

# Restore SSH configuration from backup
if [ -f /home/prototype/ssh_backup/sshd_config ]; then
    echo "📁 Restoring SSH config from backup..."
    sudo cp /home/prototype/ssh_backup/sshd_config /etc/ssh/sshd_config
    echo "✅ SSH config restored from backup"
else
    echo "⚠️ No backup found, resetting SSH to defaults..."
    # Reset SSH to defaults
    sudo rm -f /etc/ssh/ssh_host_*
    sudo dpkg-reconfigure -f noninteractive openssh-server
    echo "✅ SSH reset to defaults"
fi

# Ensure SSH is enabled and started
echo "🚀 Starting SSH service..."
sudo systemctl enable ssh
sudo systemctl restart ssh

# Wait a moment for service to start
sleep 5

# Check SSH status
if sudo systemctl is-active --quiet ssh; then
    echo "✅ SSH service is running"
    echo "🌐 You can now connect with: ssh prototype@192.168.0.40"
else
    echo "❌ SSH service failed to start"
    echo "📋 SSH status:"
    sudo systemctl status ssh
fi

# Remove this script so it doesn't run again
echo "🧹 Cleaning up recovery script..."
rm -f /boot/ssh_fix_boot.sh

echo "🎉 SSH Recovery Complete!" 