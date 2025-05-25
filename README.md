# SmarterAlexa - Home Assistant Echo Bot

A complete voice assistant system using Wyoming Satellite Protocol on Raspberry Pi, integrated with n8n and AI for conversation-style home control.

## 🚨 **SSH-SAFE SETUP v3.0** 🚨

**This version PREVENTS SSH corruption during ReSpeaker driver installation!**

### ✅ **What's New in v3.0:**
- **🔒 Automatic SSH backup** before any driver installation
- **🛡️ SSH recovery service** that runs on every boot
- **🔍 Continuous SSH monitoring** during setup
- **🔄 Automatic restoration** if SSH breaks
- **📋 Comprehensive logging** of all operations

## 🎯 **Quick Start (SSH-Safe)**

### **Step 1: Fresh Raspberry Pi Setup**
1. **Flash Raspberry Pi OS** (64-bit Lite recommended)
2. **Enable SSH** in Raspberry Pi Imager or add `ssh` file to boot partition
3. **Boot Pi and connect via SSH**

### **Step 2: Install Git and Clone Repository**
```bash
# Install Git (required for Raspberry Pi OS Lite)
sudo apt update && sudo apt install -y git

# Clone repository
git clone https://github.com/mchivelli/smarter-echo-bot.git
cd smarter-echo-bot
```

### **Step 3: Run SSH-Safe Setup**
```bash
# Run SSH-safe setup
chmod +x setup_wyoming_satellite_v3.sh
./setup_wyoming_satellite_v3.sh
```

### **Step 4: Verify Everything Works**
```bash
# Check SSH is still working (should be!)
ssh prototype@your-pi-ip

# Check services
sudo systemctl status wyoming-satellite
sudo systemctl status wyoming-openwakeword
sudo systemctl status ssh-recovery
```

## 🛡️ **SSH Protection Features**

### **Before ReSpeaker Installation:**
- ✅ Complete SSH configuration backup
- ✅ SSH host keys backup  
- ✅ Recovery service installation
- ✅ SSH functionality verification

### **During ReSpeaker Installation:**
- ✅ Real-time SSH monitoring
- ✅ Immediate recovery if issues detected
- ✅ Automatic restoration from backup

### **After Installation:**
- ✅ SSH functionality verification
- ✅ Recovery service enabled for future boots
- ✅ Backup available for manual recovery

## 📁 **Project Structure**

```
smarter-echo-bot/
├── setup_wyoming_satellite_v3.sh    # SSH-Safe setup script
├── ssh_fix_boot_v2.sh               # Emergency SSH recovery
├── fix_ssh_automated.bat            # Windows recovery tool
├── wyoming.conf                     # Wyoming configuration
├── n8n_workflow_steps.md            # n8n setup guide
├── implementation_checklist.md      # Phase-by-phase guide
├── local_llm_setup.md              # Local AI setup
└── README.md                       # This file
```

## 🏗️ **System Architecture**

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Raspberry Pi  │    │   n8n.cloud  │    │ Home Assistant │
│                 │    │              │    │                │
│ Wyoming         │◄──►│ Ollama Shim  │◄──►│ Assist API     │
│ Satellite       │    │ + OpenAI     │    │                │
│                 │    │              │    │                │
│ Wake: "Ok Nabu" │    │ Conversation │    │ Device Control │
└─────────────────┘    └──────────────┘    └─────────────────┘
```

## 🔧 **Hardware Requirements**

- **Raspberry Pi Zero 2 W** (or Pi 4/5)
- **ReSpeaker 2Mic HAT** (or compatible microphone)
- **MicroSD Card** (32GB+ recommended)
- **Stable internet connection**

## 🌐 **Network Setup**

The system works with:
- ✅ **Home WiFi networks**
- ✅ **Mobile hotspots** 
- ✅ **Dynamic IP addresses**
- ✅ **Remote access** via port forwarding/VPN

## 🚀 **Service Management**

```bash
# Start services
sudo systemctl start wyoming-satellite wyoming-openwakeword

# Stop services  
sudo systemctl stop wyoming-satellite wyoming-openwakeword

# Check status
sudo systemctl status wyoming-satellite
sudo systemctl status wyoming-openwakeword
sudo systemctl status ssh-recovery

# View logs
journalctl -u wyoming-satellite -f
journalctl -u wyoming-openwakeword -f
```

## 🔄 **SSH Recovery (If Needed)**

### **Automatic Recovery:**
The system includes automatic SSH recovery that runs on every boot.

### **Manual Recovery:**
If SSH still fails, use the emergency recovery tools:

1. **Windows Users:** Run `fix_ssh_automated.bat`
2. **SD Card Method:** Use `ssh_fix_boot_v2.sh` on boot partition
3. **Console Access:** Connect monitor/keyboard and run recovery

### **Recovery Locations:**
- SSH backups: `/home/username/ssh_backup_*`
- Recovery logs: `/var/log/ssh_recovery.log`
- Setup logs: `/home/username/setup.log`

## 📋 **Troubleshooting**

### **SSH Issues:**
```bash
# Check SSH recovery service
sudo systemctl status ssh-recovery

# Manual SSH recovery
sudo /usr/local/bin/ssh_recovery.sh

# View recovery logs
sudo tail -f /var/log/ssh_recovery.log
```

### **Audio Issues:**
```bash
# Test microphone
arecord -D plughw:CARD=seeed2micvoicec,DEV=0 -r 16000 -c 1 -f S16_LE -d 5 test.wav

# Test speaker
aplay -D plughw:CARD=seeed2micvoicec,DEV=0 test.wav

# List audio devices
aplay -l
arecord -l
```

### **Service Issues:**
```bash
# Restart Wyoming services
sudo systemctl restart wyoming-satellite wyoming-openwakeword

# Check service logs
journalctl -u wyoming-satellite --since "1 hour ago"
```

## 🔗 **Integration Guides**

- **[n8n Workflow Setup](n8n_workflow_steps.md)** - Complete n8n configuration
- **[Device Control](n8n_device_control_workflow.md)** - Home Assistant integration  
- **[Local LLM Setup](local_llm_setup.md)** - Self-hosted AI models
- **[Implementation Checklist](implementation_checklist.md)** - Step-by-step guide

## 🆘 **Emergency Contacts**

If you encounter issues:

1. **Check logs first:** `/home/username/setup.log`
2. **SSH recovery:** Use automated recovery tools
3. **Service issues:** Restart Wyoming services
4. **Hardware issues:** Verify ReSpeaker HAT connection

## 📝 **Version History**

- **v3.0** - SSH-Safe Edition with automatic recovery
- **v2.0** - Enhanced recovery tools and automation
- **v1.0** - Initial Wyoming Satellite setup

## 🎉 **Success Indicators**

After successful setup, you should have:

- ✅ **SSH working** and protected by recovery service
- ✅ **Wyoming services running** and auto-starting
- ✅ **Audio devices detected** and configured
- ✅ **Wake word detection** responding to "Ok Nabu"
- ✅ **Home Assistant discovery** showing Wyoming satellite

**Your voice assistant is ready for n8n integration!** 🚀 