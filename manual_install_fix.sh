#!/bin/bash
# Manual installation fix for Wyoming Satellite

echo "🔧 Manual Wyoming Installation Fix"
echo "This will complete the installation from where it got stuck"
echo ""

# Activate virtual environment
source /home/prototype/wyoming-satellite/bin/activate

echo "📦 Installing dependencies with pre-built wheels..."

# Install wheel and setuptools first
pip install --upgrade wheel setuptools

# Install pre-built numpy and scipy
pip install --prefer-binary numpy scipy

# Try to install zeroconf with timeout
echo "📦 Installing zeroconf (with 2-minute timeout)..."
timeout 120 pip install --prefer-binary 'zeroconf>=0.88.0,<0.89.0' || {
    echo "⚠️ Zeroconf installation timed out, trying alternative method..."
    pip install --no-build-isolation 'zeroconf>=0.88.0,<0.89.0'
}

# Install Wyoming packages without dependencies
echo "📦 Installing Wyoming packages..."
pip install --no-deps wyoming-satellite
pip install --no-deps wyoming-openwakeword

# Install remaining dependencies
echo "📦 Installing remaining dependencies..."
pip install wyoming pyring-buffer async-timeout ifaddr

echo "✅ Package installation complete!"
echo ""
echo "Next steps:"
echo "1. The main setup script should continue automatically"
echo "2. If not, run: ./setup_wyoming_satellite_v3.sh" 