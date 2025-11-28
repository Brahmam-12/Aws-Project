#!/bin/bash
# USER DATA SCRIPT - SIMPLE LOGGING & MONITORING SETUP
# For: Adding CloudWatch agent and monitoring to any instance
# Runtime: ~2 minutes
# Log file: /var/log/cloud-init-output.log

set -e

echo "=========================================="
echo "START: Monitoring Setup"
echo "=========================================="

# ============================================
# 1. INSTALL CLOUDWATCH AGENT
# ============================================
echo "[1/3] Installing CloudWatch Agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# ============================================
# 2. CREATE CLOUDWATCH CONFIG
# ============================================
echo "[2/3] Configuring CloudWatch metrics..."

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "metrics": {
    "namespace": "EC2-Monitoring",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          },
          "cpu_usage_iowait"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "/aws/ec2/cloud-init",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# ============================================
# 3. START CLOUDWATCH AGENT
# ============================================
echo "[3/3] Starting CloudWatch Agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

echo ""
echo "=========================================="
echo "CloudWatch Agent configured successfully!"
echo "=========================================="
echo "Metrics will appear in CloudWatch within 2 minutes"
echo "Namespace: EC2-Monitoring"
echo "Log group: /aws/ec2/cloud-init"
