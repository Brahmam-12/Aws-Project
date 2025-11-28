#!/bin/bash
# USER DATA SCRIPT - UBUNTU 20.04 WITH PYTHON 3 & GUNICORN
# For: Launching Python/Django/Flask application servers
# Runtime: ~3-4 minutes
# Log file: /var/log/cloud-init-output.log

set -e  # Exit on any error

echo "=========================================="
echo "START: User Data Execution (Python/Gunicorn)"
echo "=========================================="
echo "Time: $(date)"
echo ""

# ============================================
# 1. SYSTEM UPDATES & BASIC TOOLS
# ============================================
echo "[1/6] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl git wget nano htop python3 python3-pip python3-venv

# ============================================
# 2. CLONE APPLICATION FROM GITHUB
# ============================================
echo "[2/6] Cloning Python application..."
cd /home/ubuntu

git clone https://github.com/brahmam-demo/sample-flask-app.git app
cd /home/ubuntu/app

chown -R ubuntu:ubuntu /home/ubuntu/app

# ============================================
# 3. CREATE PYTHON VIRTUAL ENVIRONMENT
# ============================================
echo "[3/6] Setting up Python virtual environment..."
sudo -u ubuntu python3 -m venv venv
source venv/bin/activate

# ============================================
# 4. INSTALL PYTHON DEPENDENCIES
# ============================================
echo "[4/6] Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn

# ============================================
# 5. CREATE SYSTEMD SERVICE FOR GUNICORN
# ============================================
echo "[5/6] Creating Gunicorn systemd service..."

cat > /etc/systemd/system/flask-app.service << 'EOF'
[Unit]
Description=Flask Application with Gunicorn
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/app
Environment="PATH=/home/ubuntu/app/venv/bin"
ExecStart=/home/ubuntu/app/venv/bin/gunicorn --workers 4 --bind 0.0.0.0:5000 app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable flask-app.service
systemctl start flask-app.service

# ============================================
# 6. VERIFY APPLICATION IS RUNNING
# ============================================
echo "[6/6] Verifying application..."
sleep 3
curl http://localhost:5000 || echo "App not responding yet"

# ============================================
# COMPLETION
# ============================================
echo ""
echo "=========================================="
echo "SUCCESS: User Data Execution Complete"
echo "=========================================="
echo "Flask application running on port 5000"
echo "Access via: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "To view logs:"
echo "  journalctl -u flask-app.service -f"
echo "To restart app:"
echo "  systemctl restart flask-app.service"
echo "To check status:"
echo "  systemctl status flask-app.service"
