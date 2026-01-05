#!/bin/bash

# Eclipse Backend Auto-Start Setup Script
# This script sets up your backend server to run automatically

set -e  # Exit on error

echo "🌙 Eclipse Backend Auto-Start Setup"
echo "===================================="
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    echo ""
    echo "Please install Node.js first:"
    echo "  brew install node"
    echo ""
    exit 1
fi

echo "✅ Node.js found: $(node --version)"
echo "✅ npm found: $(npm --version)"
echo ""

# Navigate to Backend directory
cd "$(dirname "$0")"

# Install dependencies
echo "📦 Installing dependencies..."
npm install
echo ""

# Install PM2 globally
echo "📦 Installing PM2 process manager..."
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
    echo "✅ PM2 installed"
else
    echo "✅ PM2 already installed"
fi
echo ""

# Stop existing instance if running
echo "🛑 Stopping any existing instances..."
pm2 delete eclipse-backend 2>/dev/null || true
echo ""

# Start with PM2
echo "🚀 Starting Eclipse backend with PM2..."
pm2 start server.js --name eclipse-backend
echo ""

# Setup auto-start on system boot
echo "⚙️  Configuring auto-start on system boot..."
pm2 startup > /tmp/pm2-startup.sh 2>&1 || true

# Check if we need to run a startup command
if grep -q "sudo" /tmp/pm2-startup.sh; then
    echo ""
    echo "⚠️  PM2 needs sudo access to set up auto-start."
    echo "Please run the following command manually:"
    echo ""
    grep "sudo" /tmp/pm2-startup.sh | head -1
    echo ""
    echo "After running that command, run this script again."
    echo ""
    read -p "Press Enter to continue without auto-start, or Ctrl+C to exit and run the command..."
else
    pm2 save
    echo "✅ Auto-start configured"
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "Your backend is now running on http://localhost:3000"
echo ""
echo "Useful commands:"
echo "  pm2 status              - Check server status"
echo "  pm2 logs eclipse-backend - View logs"
echo "  pm2 restart eclipse-backend - Restart server"
echo "  pm2 stop eclipse-backend    - Stop server"
echo "  pm2 delete eclipse-backend  - Remove from PM2"
echo ""
echo "The server will automatically:"
echo "  ✅ Restart if it crashes"
echo "  ✅ Start when your Mac boots up"
echo ""
