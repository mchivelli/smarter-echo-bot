#!/bin/bash

# Wyoming Satellite Setup Script v3.0 - SSH-Safe Edition
# This version prevents SSH corruption and includes automatic recovery

set -e  # Exit on any error

# Check if running as root and warn
if [ "$EUID" -eq 0 ]; then 
   echo "⚠️  WARNING: Running as root. It's recommended to run this script as a regular user."
   echo "The script will use 'sudo' where needed for system operations."
   echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
   sleep 5
fi

# Determine the actual user (even if running with sudo)
if [ -n "$SUDO_USER" ]; then
    ACTUAL_USER="$SUDO_USER"
    USER_HOME="/home/$SUDO_USER"
else
    ACTUAL_USER="$(whoami)"
    USER_HOME="$HOME"
fi

# Create log directory if it doesn't exist
mkdir -p "$USER_HOME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$USER_HOME/setup.log"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$USER_HOME/setup.log"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$USER_HOME/setup.log"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$USER_HOME/setup.log"
}

# Function to run commands as the actual user
run_as_user() {
    if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
        sudo -u "$SUDO_USER" -H bash -c "$1"
    else
        bash -c "$1"
    fi
}

# Function to backup SSH configuration
backup_ssh() {
    log "🔒 Creating comprehensive SSH backup..."
    
    local backup_dir="$USER_HOME/ssh_backup_$(date +%Y%m%d_%H%M%S)"
    run_as_user "mkdir -p '$backup_dir'"
    
    # Backup SSH daemon configuration
    if [ -f /etc/ssh/sshd_config ]; then
        sudo cp /etc/ssh/sshd_config "$backup_dir/"
        sudo chown "$ACTUAL_USER:$ACTUAL_USER" "$backup_dir/sshd_config"
        log "✅ SSH daemon config backed up"
    fi
    
    # Backup SSH host keys
    sudo cp /etc/ssh/ssh_host_* "$backup_dir/" 2>/dev/null || true
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" "$backup_dir"/ssh_host_* 2>/dev/null || true
    log "✅ SSH host keys backed up"
    
    # Backup SSH client config
    if [ -f /etc/ssh/ssh_config ]; then
        sudo cp /etc/ssh/ssh_config "$backup_dir/"
        sudo chown "$ACTUAL_USER:$ACTUAL_USER" "$backup_dir/ssh_config"
    fi
    
    # Create a restore script
    cat > "$backup_dir/restore_ssh.sh" << 'EOF'
#!/bin/bash
# SSH Restore Script - Auto-generated

echo "🔧 Restoring SSH configuration..."

# Stop SSH service
sudo systemctl stop ssh

# Restore SSH daemon config
if [ -f sshd_config ]; then
    sudo cp sshd_config /etc/ssh/sshd_config
    echo "✅ SSH daemon config restored"
fi

# Restore host keys
sudo cp ssh_host_* /etc/ssh/ 2>/dev/null || true
echo "✅ SSH host keys restored"

# Set correct permissions
sudo chmod 600 /etc/ssh/ssh_host_*_key
sudo chmod 644 /etc/ssh/ssh_host_*_key.pub
sudo chmod 644 /etc/ssh/sshd_config

# Restart SSH
sudo systemctl start ssh
sudo systemctl enable ssh

echo "🎉 SSH restoration complete!"
EOF
    
    chmod +x "$backup_dir/restore_ssh.sh"
    
    # Create symlink to latest backup
    run_as_user "ln -sfn '$backup_dir' '$USER_HOME/ssh_backup_latest'"
    
    log "✅ SSH backup created at: $backup_dir"
    echo "$backup_dir" > "$USER_HOME/.ssh_backup_path"
    chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.ssh_backup_path"
}

# Function to create SSH recovery service
create_ssh_recovery_service() {
    log "🛡️ Creating SSH recovery service..."
    
    # Create recovery script
    sudo tee /usr/local/bin/ssh_recovery.sh > /dev/null << 'EOF'
#!/bin/bash
# SSH Recovery Service - Runs on boot to ensure SSH is working

LOG_FILE="/var/log/ssh_recovery.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_message "SSH Recovery Service Starting..."

# Check if SSH is running
if ! systemctl is-active --quiet ssh; then
    log_message "SSH service not running, attempting recovery..."
    
    # Try to start SSH
    systemctl start ssh
    sleep 2
    
    if systemctl is-active --quiet ssh; then
        log_message "SSH service started successfully"
    else
        log_message "SSH service failed to start, attempting full recovery..."
        
        # Find the latest SSH backup
        BACKUP_PATH=$(find /home/*/ssh_backup_* -type d -name "ssh_backup_*" | sort | tail -1)
        
        if [ -n "$BACKUP_PATH" ] && [ -d "$BACKUP_PATH" ]; then
            log_message "Found SSH backup at: $BACKUP_PATH"
            
            # Restore from backup
            if [ -f "$BACKUP_PATH/restore_ssh.sh" ]; then
                cd "$BACKUP_PATH"
                bash restore_ssh.sh >> "$LOG_FILE" 2>&1
                log_message "SSH backup restoration attempted"
            fi
        else
            log_message "No SSH backup found, creating minimal config..."
            
            # Create minimal working SSH config
            cat > /etc/ssh/sshd_config << 'SSHEOF'
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
UsePAM yes
X11Forwarding yes
Subsystem sftp /usr/lib/openssh/sftp-server
SSHEOF
            
            # Generate new host keys if missing
            ssh-keygen -A
            
            # Set permissions
            chmod 600 /etc/ssh/ssh_host_*_key
            chmod 644 /etc/ssh/ssh_host_*_key.pub
            chmod 644 /etc/ssh/sshd_config
            
            # Start SSH
            systemctl enable ssh
            systemctl start ssh
            
            log_message "Minimal SSH configuration created and started"
        fi
    fi
else
    log_message "SSH service is running normally"
fi

log_message "SSH Recovery Service Complete"
EOF

    sudo chmod +x /usr/local/bin/ssh_recovery.sh
    
    # Create systemd service
    sudo tee /etc/systemd/system/ssh-recovery.service > /dev/null << 'EOF'
[Unit]
Description=SSH Recovery Service
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ssh_recovery.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ssh-recovery.service
    
    log "✅ SSH recovery service created and enabled"
}

# Function to test SSH before proceeding
test_ssh_working() {
    log "🔍 Testing SSH connectivity..."
    
    if systemctl is-active --quiet ssh; then
        log "✅ SSH service is active"
        
        # Test SSH configuration
        if sudo sshd -t 2>/dev/null; then
            log "✅ SSH configuration is valid"
            return 0
        else
            warning "⚠️ SSH configuration has issues"
            return 1
        fi
    else
        error "❌ SSH service is not running"
        return 1
    fi
}

# Function to install ReSpeaker drivers safely
install_respeaker_safe() {
    log "🎤 Installing ReSpeaker drivers with SSH protection..."
    
    # Backup SSH before driver installation
    backup_ssh
    
    # Create recovery service
    create_ssh_recovery_service
    
    # Test SSH is working before proceeding
    if ! test_ssh_working; then
        error "SSH is not working properly before ReSpeaker installation. Aborting."
        exit 1
    fi
    
    log "📋 SSH is working, proceeding with ReSpeaker driver installation..."
    
    # Clone ReSpeaker repository
    cd "$USER_HOME"
    if [ ! -d "seeed-voicecard" ]; then
        run_as_user "git clone https://github.com/respeaker/seeed-voicecard.git"
    fi
    
    cd seeed-voicecard
    
    # Install drivers
    log "🔧 Installing ReSpeaker drivers (this may take a while)..."
    sudo ./install.sh --compat-kernel || {
        error "ReSpeaker driver installation failed"
        
        # Attempt SSH recovery
        log "🔄 Attempting SSH recovery after failed installation..."
        sudo /usr/local/bin/ssh_recovery.sh
        
        exit 1
    }
    
    log "✅ ReSpeaker drivers installed"
    
    # Immediately test SSH after installation
    log "🔍 Testing SSH after ReSpeaker installation..."
    sleep 5  # Give system time to settle
    
    if ! test_ssh_working; then
        warning "⚠️ SSH issues detected after ReSpeaker installation, running recovery..."
        sudo /usr/local/bin/ssh_recovery.sh
        
        # Test again
        sleep 5
        if ! test_ssh_working; then
            error "❌ SSH recovery failed. Manual intervention required."
            log "📋 SSH backup available at: $(cat $USER_HOME/.ssh_backup_path 2>/dev/null || echo 'Unknown')"
        else
            log "✅ SSH recovery successful"
        fi
    else
        log "✅ SSH is working correctly after ReSpeaker installation"
    fi
}

# Main setup function
main() {
    log "🚀 Starting Wyoming Satellite Setup v3.0 - SSH-Safe Edition"
    log "📅 $(date)"
    log "👤 Running as user: $ACTUAL_USER"
    log "📁 Working directory: $(pwd)"
    log "🏠 User home: $USER_HOME"
    
    # Update system
    log "📦 Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    
    # Install essential packages
    log "📦 Installing essential packages..."
    sudo apt install -y git python3 python3-pip python3-venv curl wget build-essential portaudio19-dev
    
    # Install Wyoming Satellite
    log "🛰️ Installing Wyoming Satellite..."
    
    # Create virtual environment as actual user
    run_as_user "python3 -m venv $USER_HOME/wyoming-satellite"
    
    # Create activation script for easier use
    log "📋 Creating activation script..."
    cat > "$USER_HOME/activate_wyoming.sh" << EOF
#!/bin/bash
source $USER_HOME/wyoming-satellite/bin/activate
echo "✅ Wyoming Satellite virtual environment activated"
echo "📁 Working directory: $USER_HOME"
EOF
    chmod +x "$USER_HOME/activate_wyoming.sh"
    chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/activate_wyoming.sh"
    
    # Install Wyoming packages with dependency fix
    log "📦 Installing Wyoming packages..."
    run_as_user "source $USER_HOME/wyoming-satellite/bin/activate && pip install --upgrade pip wheel setuptools"
    
    # Install TensorFlow Lite runtime first (fixes ARM64 dependency issues)
    log "🔧 Installing TensorFlow Lite runtime for ARM64..."
    run_as_user "source $USER_HOME/wyoming-satellite/bin/activate && pip install --extra-index-url https://google-coral.github.io/py-repo/ tflite_runtime"
    
    # Install pre-built wheels for faster installation
    log "📦 Installing pre-built dependencies..."
    run_as_user "source $USER_HOME/wyoming-satellite/bin/activate && pip install --prefer-binary numpy scipy"
    
    # Install zeroconf from pre-built wheel if available
    log "📦 Installing zeroconf (this may take a few minutes on ARM64)..."
    run_as_user "source $USER_HOME/wyoming-satellite/bin/activate && pip install --prefer-binary 'zeroconf>=0.88.0,<0.89.0' || pip install --no-build-isolation 'zeroconf>=0.88.0,<0.89.0'"
    
    # Install Wyoming packages separately to avoid conflicts
    log "📦 Installing Wyoming Satellite..."
    run_as_user "source $USER_HOME/wyoming-satellite/bin/activate && pip install --no-deps wyoming-satellite"
    
    log "📦 Installing Wyoming OpenWakeWord..."
    run_as_user "source $USER_HOME/wyoming-satellite/bin/activate && pip install --no-deps wyoming-openwakeword"
    
    # Install remaining dependencies manually
    log "📦 Installing remaining dependencies..."
    run_as_user "source $USER_HOME/wyoming-satellite/bin/activate && pip install wyoming pyring-buffer async-timeout ifaddr"
    
    # Install ReSpeaker drivers with SSH protection
    install_respeaker_safe
    
    # Configure Wyoming services
    log "⚙️ Configuring Wyoming services..."
    
    # Create Wyoming Satellite service
    sudo tee /etc/systemd/system/wyoming-satellite.service > /dev/null << EOF
[Unit]
Description=Wyoming Satellite
After=network.target
Wants=network.target

[Service]
Type=simple
User=$ACTUAL_USER
WorkingDirectory=$USER_HOME
Environment=PATH=$USER_HOME/wyoming-satellite/bin
ExecStart=$USER_HOME/wyoming-satellite/bin/wyoming-satellite \\
    --name "$(hostname)" \\
    --uri tcp://0.0.0.0:10700 \\
    --mic-command "arecord -D plughw:CARD=seeed2micvoicec,DEV=0 -r 16000 -c 1 -f S16_LE -t raw" \\
    --snd-command "aplay -D plughw:CARD=seeed2micvoicec,DEV=0 -r 22050 -c 1 -f S16_LE -t raw" \\
    --wake-uri tcp://127.0.0.1:10400 \\
    --wake-word-name "ok_nabu"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    # Create Wyoming OpenWakeWord service
    sudo tee /etc/systemd/system/wyoming-openwakeword.service > /dev/null << EOF
[Unit]
Description=Wyoming OpenWakeWord
After=network.target
Wants=network.target

[Service]
Type=simple
User=$ACTUAL_USER
WorkingDirectory=$USER_HOME
Environment=PATH=$USER_HOME/wyoming-satellite/bin
ExecStart=$USER_HOME/wyoming-satellite/bin/wyoming-openwakeword \\
    --uri tcp://127.0.0.1:10400 \\
    --model ok_nabu \\
    --preload-model
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start services
    sudo systemctl daemon-reload
    sudo systemctl enable wyoming-satellite.service
    sudo systemctl enable wyoming-openwakeword.service
    
    # Final SSH test
    log "🔍 Final SSH connectivity test..."
    if test_ssh_working; then
        log "✅ SSH is working correctly"
    else
        warning "⚠️ SSH issues detected, running final recovery..."
        sudo /usr/local/bin/ssh_recovery.sh
    fi
    
    log "🎉 Setup complete!"
    log "📋 Services status:"
    sudo systemctl status wyoming-satellite.service --no-pager -l || true
    sudo systemctl status wyoming-openwakeword.service --no-pager -l || true
    sudo systemctl status ssh.service --no-pager -l || true
    
    log "🔧 To start services: sudo systemctl start wyoming-satellite wyoming-openwakeword"
    log "📋 Setup log saved to: $USER_HOME/setup.log"
    log "🔒 SSH backup available at: $(cat $USER_HOME/.ssh_backup_path 2>/dev/null || echo 'Unknown')"
    log "🎤 To activate Wyoming environment: source $USER_HOME/activate_wyoming.sh"
}

# Run main function
main "$@" 