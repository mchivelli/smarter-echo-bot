# SSH Recovery Guide for ReSpeaker Driver Issue

## Problem
After installing ReSpeaker drivers, SSH connection fails with:
```
kex_exchange_identification: read: Connection reset
Connection reset by 192.168.0.40 port 22
```

## Recovery Methods (Try in Order)

### Method 1: Power Cycle + Wait ⚡
**Easiest method - try this first!**

1. **Unplug the Pi's power cable**
2. **Wait 30 seconds**
3. **Plug power back in**
4. **Wait 5 minutes** for full boot and recovery services
5. **Try SSH again**: `ssh prototype@192.168.0.40`

The setup script installed automatic recovery services that should restore SSH on boot.

### Method 2: Direct Console Access 🖥️
**If you have monitor + keyboard:**

1. **Connect monitor and keyboard to Pi**
2. **Login as `prototype`**
3. **Run recovery commands**:
```bash
# Restore SSH configuration from backup
sudo cp /home/prototype/ssh_backup/sshd_config /etc/ssh/sshd_config
sudo systemctl restart ssh

# Or reset to defaults
sudo rm /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server
sudo systemctl restart ssh

# Check SSH status
sudo systemctl status ssh
```

### Method 3: SD Card Direct Edit 💾
**If no monitor available:**

1. **Power off Pi and remove SD card**
2. **Insert SD card into Windows PC**
3. **Open the `rootfs` partition** (may need Linux file system support)
4. **Navigate to**: `rootfs/etc/ssh/`
5. **Replace `sshd_config` with backup**:
   - Copy from: `rootfs/home/prototype/ssh_backup/sshd_config`
   - To: `rootfs/etc/ssh/sshd_config`
6. **Safely eject SD card and reinsert into Pi**
7. **Power on and try SSH**

### Method 4: Fresh SSH Installation 🔄
**If console access available:**

```bash
# Completely reinstall SSH
sudo apt remove --purge openssh-server
sudo apt update
sudo apt install openssh-server

# Enable and start SSH
sudo systemctl enable ssh
sudo systemctl start ssh

# Check status
sudo systemctl status ssh
```

### Method 5: Alternative Access Methods 🌐

**Try different connection approaches:**
```bash
# Try with different SSH options
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null prototype@192.168.0.40

# Try with legacy algorithms
ssh -o KexAlgorithms=+diffie-hellman-group1-sha1 prototype@192.168.0.40

# Try with hostname instead of IP
ssh prototype@prototype.local
```

## Prevention for Future
When installing ReSpeaker drivers again:

1. **Backup SSH config first**:
```bash
sudo cp /etc/ssh/sshd_config /home/prototype/ssh_backup/
```

2. **Use our enhanced setup script** which includes automatic recovery

3. **Test SSH immediately after driver installation**

## Verification Commands
Once SSH is working:

```bash
# Check SSH service
sudo systemctl status ssh

# Check SSH configuration
sudo sshd -T

# Test connection from another terminal
ssh prototype@192.168.0.40 "echo 'SSH is working!'"
```

## Emergency Contact
If all methods fail, you may need to:
1. **Flash a fresh Raspberry Pi OS image**
2. **Re-run the setup script**
3. **Restore your project files from backup**

The Wyoming satellite setup is preserved in systemd services, so only SSH needs fixing. 