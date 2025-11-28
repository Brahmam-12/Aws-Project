#!/bin/bash
# USER DATA SCRIPT - UBUNTU 20.04 WITH NODE.JS & PM2
# For: Launching Node.js application servers automatically
# Runtime: ~3-4 minutes
# Log file: /var/log/cloud-init-output.log

set -e  # Exit on any error

echo "=========================================="
echo "START: User Data Execution"
echo "=========================================="
echo "Time: $(date)"
echo "Running as: $(whoami)"
echo ""

# ============================================
# 1. SYSTEM UPDATES & BASIC TOOLS
# ============================================
echo "[1/7] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl git wget nano htop

# ============================================
# 2. INSTALL NODE.JS (v18 Latest LTS)
# ============================================
echo "[2/7] Installing Node.js v18..."
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs

# Verify installation
echo "Node.js version: $(node -v)"
echo "NPM version: $(npm -v)"

# ============================================
# 3. INSTALL PM2 (Process Manager)
# ============================================
echo "[3/7] Installing PM2..."
npm install -g pm2

# Enable PM2 to start on boot
pm2 startup systemd -u ubuntu --hp /home/ubuntu
echo "PM2 startup enabled"

# ============================================
# 4. CLONE APPLICATION FROM GITHUB
# ============================================
echo "[4/7] Cloning Node.js application..."
cd /home/ubuntu

# Example: Your GitHub repository
git clone https://github.com/brahmam-demo/sample-api.git app
cd /home/ubuntu/app

# Change ownership to ubuntu user (not root)
chown -R ubuntu:ubuntu /home/ubuntu/app

# ============================================
# 5. INSTALL APPLICATION DEPENDENCIES
# ============================================
echo "[5/7] Installing npm dependencies..."
npm install --production

# ============================================
# 6. START APPLICATION WITH PM2
# ============================================
echo "[6/7] Starting application with PM2..."
sudo -u ubuntu pm2 start index.js --name "node-api"

# Save PM2 process list
sudo -u ubuntu pm2 save

echo "Application started with PM2"
pm2 list

# ============================================
# 7. VERIFY APPLICATION IS RUNNING
# ============================================
echo "[7/7] Verifying application..."
sleep 2
curl http://localhost:3000 || echo "App not responding yet"

# ============================================
# COMPLETION
# ============================================
echo ""
echo "=========================================="
echo "SUCCESS: User Data Execution Complete"
echo "=========================================="
echo "Application is running on port 3000"
echo "Access via: http://$(hostname -I | awk '{print $1}'):3000"
echo ""
echo "Next steps:"
echo "1. Update ALB target group to use port 3000"
echo "2. Test health check: GET /health"
echo "3. Monitor logs: pm2 logs node-api"
