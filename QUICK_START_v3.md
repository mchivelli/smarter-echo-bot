# 🚀 Quick Start Guide - SSH-Safe v3.0

## ✅ **GUARANTEED SSH-SAFE SETUP**

This version **PREVENTS** SSH corruption during ReSpeaker driver installation!

## 📋 **Prerequisites**

- Fresh Raspberry Pi OS (64-bit Lite recommended)
- SSH enabled and working
- Internet connection

## 🎯 **4-Step Setup**

### **Step 1: Install Git**
```bash
# Install Git (required for Raspberry Pi OS Lite)
sudo apt update && sudo apt install -y git
```

### **Step 2: Clone Repository**
```bash
git clone https://github.com/mchivelli/smarter-echo-bot.git
cd smarter-echo-bot
```

### **Step 3: Run SSH-Safe Setup**
```bash
chmod +x setup_wyoming_satellite_v3.sh
./setup_wyoming_satellite_v3.sh
```

### **Step 4: Verify Success**
```bash
# SSH should still work (this was the problem before!)
ssh prototype@your-pi-ip

# Check services are running
sudo systemctl status wyoming-satellite
sudo systemctl status wyoming-openwakeword
sudo systemctl status ssh-recovery
```

## 🛡️ **What v3.0 Does Differently**

### **Before ReSpeaker Installation:**
- ✅ **Backs up SSH completely** (config + keys)
- ✅ **Creates recovery service** for automatic fixing
- ✅ **Tests SSH is working** before proceeding

### **During Installation:**
- ✅ **Monitors SSH in real-time**
- ✅ **Immediately recovers** if issues detected
- ✅ **Logs everything** for debugging

### **After Installation:**
- ✅ **Verifies SSH still works**
- ✅ **Enables recovery service** for future boots
- ✅ **Provides backup location** for manual recovery

## 🎉 **Success Indicators**

After setup completes, you should have:

- ✅ **SSH working** (no more connection resets!)
- ✅ **Wyoming services running**
- ✅ **Audio devices configured**
- ✅ **Wake word "Ok Nabu" active**
- ✅ **Recovery service enabled**

## 🔄 **If Something Goes Wrong**

### **SSH Issues (Unlikely with v3.0):**
```bash
# Check recovery service
sudo systemctl status ssh-recovery

# Manual recovery
sudo /usr/local/bin/ssh_recovery.sh

# View logs
sudo tail -f /var/log/ssh_recovery.log
```

### **Service Issues:**
```bash
# Restart services
sudo systemctl restart wyoming-satellite wyoming-openwakeword

# Check logs
journalctl -u wyoming-satellite -f
```

## 📁 **Important Files Created**

- **Setup log:** `/home/username/setup.log`
- **SSH backup:** `/home/username/ssh_backup_*/`
- **Recovery service:** `/usr/local/bin/ssh_recovery.sh`
- **Recovery logs:** `/var/log/ssh_recovery.log`

## 🌐 **Next Steps**

1. **Test wake word:** Say "Ok Nabu" near the Pi
2. **Add to Home Assistant:** Settings → Devices & Services → Look for Wyoming discovery
3. **Configure n8n:** Follow `n8n_workflow_steps.md`
4. **Set up AI:** Follow `local_llm_setup.md` or use OpenAI

## 🆘 **Emergency Recovery**

If SSH somehow still breaks (very unlikely):

1. **Windows users:** Run `fix_ssh_automated.bat`
2. **SD card method:** Use `ssh_fix_boot_v2.sh`
3. **Console access:** Connect monitor/keyboard

## ✨ **Why This Version Works**

Previous versions had SSH corruption because:
- ❌ ReSpeaker drivers modified SSH configuration
- ❌ No backup before installation
- ❌ No automatic recovery
- ❌ No monitoring during installation

**v3.0 fixes ALL of these issues!** 🎉

Your SSH will remain working throughout the entire process. 