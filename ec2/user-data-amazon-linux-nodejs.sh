#!/bin/bash
# USER DATA SCRIPT - AMAZON LINUX 2 WITH NODE.JS & PM2
# For: Launching Node.js application servers on Amazon Linux AMI
# Runtime: ~3-4 minutes
# Log file: /var/log/cloud-init-output.log

set -e  # Exit on any error

echo "=========================================="
echo "START: User Data Execution (Amazon Linux 2)"
echo "=========================================="
echo "Time: $(date)"
echo "Running as: $(whoami)"
echo ""

# ============================================
# 1. SYSTEM UPDATES & BASIC TOOLS
# ============================================
echo "[1/7] Updating system packages..."
yum update -y
yum install -y curl git wget nano htop

# ============================================
# 2. INSTALL NODE.JS (v18 Latest LTS)
# ============================================
echo "[2/7] Installing Node.js v18..."
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Verify installation
echo "Node.js version: $(node -v)"
echo "NPM version: $(npm -v)"

# ============================================
# 3. INSTALL PM2 (Process Manager)
# ============================================
echo "[3/7] Installing PM2..."
npm install -g pm2

# Enable PM2 to start on boot
pm2 startup systemd -u ec2-user --hp /home/ec2-user
echo "PM2 startup enabled"

# ============================================
# 4. CLONE APPLICATION FROM GITHUB
# ============================================
echo "[4/7] Cloning Node.js application..."
cd /home/ec2-user

# Example: Your GitHub repository
git clone https://github.com/brahmam-demo/sample-api.git app
cd /home/ec2-user/app

# Change ownership to ec2-user (not root)
chown -R ec2-user:ec2-user /home/ec2-user/app

# ============================================
# 5. INSTALL APPLICATION DEPENDENCIES
# ============================================
echo "[5/7] Installing npm dependencies..."
npm install --production

# ============================================
# 6. START APPLICATION WITH PM2
# ============================================
echo "[6/7] Starting application with PM2..."
sudo -u ec2-user pm2 start index.js --name "node-api"

# Save PM2 process list
sudo -u ec2-user pm2 save

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
echo "To view logs:"
echo "  pm2 logs node-api"
echo "To restart app:"
echo "  pm2 restart node-api"
echo "To check status:"
echo "  pm2 status"
