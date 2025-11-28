# DAY 3 - STEP-BY-STEP EC2 LAUNCH GUIDE 🚀

## Complete Hands-On Tasks from Zero to Running Application

By the end of this guide, you'll have launched an EC2 instance with Node.js, deployed a real application, and tested it in your browser.

---

## 📋 Table of Contents

1. [Task 0: Prerequisites](#task-0-prerequisites)
2. [Task 1: Launch EC2 Instance](#task-1-launch-ec2-instance)
3. [Task 2: Connect via SSH](#task-2-connect-via-ssh)
4. [Task 3: Test Application](#task-3-test-application)
5. [Task 4: Monitor with CloudWatch](#task-4-monitor-with-cloudwatch)
6. [Task 5: Create Custom AMI](#task-5-create-custom-ami)
7. [Task 6: Troubleshooting](#task-6-troubleshooting)

---

## Task 0: Prerequisites

### What You Need

```
✅ AWS account with permission to launch EC2
✅ VPC and public subnet created (from Day 1)
✅ Security group with SSH + HTTP (or create one)
✅ SSH client (built-in on Mac/Linux, PuTTY on Windows)
✅ Key pair created in AWS EC2 console
```

### Quick Security Group Setup

**If you don't have a security group yet:**

1. **EC2 Console** → **Security Groups** (left sidebar)
2. Click **"Create security group"**
3. **Basic Details:**
   ```
   Name:        web-server-sg
   Description: Security group for web servers
   VPC:         Your VPC
   ```

4. **Inbound Rules** - Click "Add rule":

   **Rule 1: SSH**
   ```
   Type:       SSH
   Protocol:   TCP
   Port:       22
   Source:     My IP (Get from: https://whatismyipaddress.com/)
   Description: SSH from my IP only
   ```

   **Rule 2: HTTP**
   ```
   Type:       HTTP
   Protocol:   TCP
   Port:       80
   Source:     0.0.0.0/0 (from anywhere)
   Description: HTTP from internet
   ```

   **Rule 3: HTTPS**
   ```
   Type:       HTTPS
   Protocol:   TCP
   Port:       443
   Source:     0.0.0.0/0
   Description: HTTPS from internet
   ```

   **Rule 4: Application Port (Node.js)**
   ```
   Type:       Custom TCP
   Protocol:   TCP
   Port:       3000
   Source:     0.0.0.0/0 (for testing, restrict later)
   Description: Node.js app port
   ```

5. **Outbound Rules** - Leave default (allow all)

6. Click **"Create security group"**

---

## Task 1: Launch EC2 Instance

### Method 1: AWS Console (Easiest)

#### Step 1: Open EC2 Console

```
AWS Console → EC2 → Instances → "Launch instances"
```

#### Step 2: Choose AMI

```
Name: Ubuntu
Version: Ubuntu Server 20.04 LTS (or 22.04)
Architecture: 64-bit (x86)
Click: SELECT
```

**Why Ubuntu 20?** Popular, well-documented, lots of tutorials available.

#### Step 3: Choose Instance Type

```
Instance Type:  t3.micro
├── Free tier eligible
├── Good for learning
└── Click: "Next: Configure Instance Details"
```

#### Step 4: Configure Instance Details

```
Number of Instances:  1
Network:             Your VPC
Subnet:              Public Subnet (has route to IGW)
Auto-assign Public IP: Enable (so you can SSH)

┌────────────────────────────────────────────┐
│ IMPORTANT: User Data Section               │
├────────────────────────────────────────────┤
│ Select: "As text"                          │
│ Paste: Content from:                       │
│ user-data-ubuntu-nodejs.sh                 │
│ (This auto-installs Node.js, PM2, app)    │
└────────────────────────────────────────────┘

Click: "Next: Add Storage"
```

#### Step 5: Add Storage

```
Size: 20 GB (default)
└── Good enough for application + OS

Click: "Next: Add Tags"
```

#### Step 6: Add Tags (Optional but Recommended)

```
Key:    Name
Value:  web-server-1

Key:    Environment
Value:  Development

Key:    Application
Value:  Node.js API

(Tags help organize instances)
Click: "Next: Configure Security Group"
```

#### Step 7: Configure Security Group

```
Select existing security group:
└── web-server-sg (created in Prerequisites)

Click: "Review and Launch"
```

#### Step 8: Review and Launch

```
Review all settings:
├── AMI:                Ubuntu 20.04
├── Instance Type:      t3.micro
├── Network:            Your VPC
├── Subnet:             Public Subnet
├── Auto-assign IP:     Enabled
├── Security Group:     web-server-sg
└── User Data:          Enabled (shows first 100 chars)

Key Pair:
├── Select existing key pair: Your-Key-Pair
├── ✓ Acknowledge you have access to key
└── Click: "Launch Instances"
```

#### Step 9: Instance Launching

```
✅ SUCCESS! Instance is launching
├── State: pending (1-2 minutes)
├── Your instance: i-0abcd1234efgh5678
├── Public IP: (will appear in 1-2 minutes)
└── Click: "View Instances"
```

#### Step 10: Monitor Instance Launch

```
EC2 Instances dashboard:

Instance:       web-server-1
State:          running ✅
Public IP:      54.123.45.67 (changes when stop/start)
Private IP:     10.0.1.42

Columns to watch:
├── Instance State: pending → running (2-3 min)
├── Status Checks: 2/2 passed ✅
└── Public IPv4:   54.123.45.67

⏰ WAIT 2-3 MINUTES before trying SSH
(User data script still running)
```

---

### Method 2: AWS CLI (Advanced)

```bash
# 1. Get latest Ubuntu 20 AMI ID
ami_id=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" \
  --query 'sort_by(Images, &CreationDate)[-1].[ImageId]' \
  --output text)

echo "Using AMI: $ami_id"

# 2. Launch instance
aws ec2 run-instances \
  --image-id $ami_id \
  --instance-type t3.micro \
  --key-name Your-Key-Pair \
  --security-group-ids sg-0abcd1234efgh5678 \
  --subnet-id subnet-0abcd1234efgh5678 \
  --associate-public-ip-address \
  --user-data file://user-data-ubuntu-nodejs.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server-1},{Key=Environment,Value=Development}]' \
  --output table

# 3. Get instance details
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=web-server-1" \
  --query 'Reservations[0].Instances[0].[InstanceId,PublicIpAddress,State.Name]' \
  --output table
```

---

## Task 2: Connect via SSH

### Step 1: Wait for Instance to Fully Boot

```
Indicators that instance is ready:
├── Instance State: running ✅
├── Status Checks: 2/2 passed ✅ (takes 2-3 min)
├── Public IP assigned
└── User data execution complete
```

**Check User Data Progress:**

```bash
# SSH into instance (even if still booting)
ssh -i /path/to/key.pem ubuntu@54.123.45.67

# Check cloud-init progress
tail -f /var/log/cloud-init-output.log
```

### Step 2: SSH Connection

#### On Mac/Linux:

```bash
# 1. Ensure key is readable only by you
chmod 400 ~/.ssh/my-key.pem

# 2. SSH into instance
ssh -i ~/.ssh/my-key.pem ubuntu@54.123.45.67

# Success output:
# Welcome to Ubuntu 20.04.5 LTS
# Last login: Wed Nov 28 12:34:56 2025
# ubuntu@ip-10-0-1-42:~$
```

#### On Windows (PowerShell):

```powershell
# 1. Set key permissions (Windows-specific)
$KeyPath = "$env:USERPROFILE\.ssh\my-key.pem"
icacls $KeyPath /inheritance:r /grant:r "$env:USERNAME`:F"

# 2. SSH into instance
ssh -i "$env:USERPROFILE\.ssh\my-key.pem" ubuntu@54.123.45.67
```

#### On Windows (PuTTY):

```
1. Convert PEM to PPK:
   ├── PuTTYgen → Load → my-key.pem
   ├── Save private key as: my-key.ppk

2. Connect:
   ├── PuTTY → Host: 54.123.45.67
   ├── Connection → SSH → Auth
   ├── Browse → my-key.ppk
   └── Open
```

### Step 3: SSH Troubleshooting

```
Error: "Connection refused"
├── Reason: Instance still booting
├── Fix: Wait 2-3 minutes, try again

Error: "Connection timeout"
├── Reason 1: No public IP assigned
│   └── Fix: Enable auto-assign public IP
├── Reason 2: Security group SSH port closed
│   └── Fix: Add inbound rule for SSH port 22
└── Reason 3: Instance in private subnet
    └── Fix: Use Bastion host or put in public subnet

Error: "Permission denied (publickey)"
├── Reason 1: Wrong key file
│   └── Fix: -i /path/to/correct/key.pem
├── Reason 2: Key permissions too open
│   └── Fix: chmod 400 key.pem
└── Reason 3: Wrong username
    └── Fix: ubuntu@ (not ec2-user@) for Ubuntu AMI

Error: "Permission denied (publickey), gssapi-keyex"
├── Reason: This is normal, just means trying multiple auth methods
└── Fix: Just wait, next attempt will succeed
```

---

## Task 3: Test Application

### Step 1: Verify Node.js & PM2 Running

```bash
# SSH into instance (from Task 2)
ubuntu@ip-10-0-1-42:~$ 

# Check Node.js version
node -v
# v18.18.2

# Check NPM version
npm -v
# 9.8.1

# Check PM2 status
pm2 status
# ┌─────┬────────┬──────┬──────────┬──────┐
# │ id  │ name   │ mode │ status   │ cpu  │
# ├─────┼────────┼──────┼──────────┼──────┤
# │ 0   │node-api│fork  │ online   │ 0%   │
# └─────┴────────┴──────┴──────────┴──────┘

# Check logs
pm2 logs node-api
```

### Step 2: Test Locally on Instance

```bash
# Check if app listening on port 3000
curl http://localhost:3000

# Should return: JSON response or HTML
# If nothing: app might not be ready (wait 30 sec)
```

### Step 3: Test from Browser

**Option 1: Direct to Instance IP**

```
Browser: http://54.123.45.67:3000

Result:
├── ✅ JSON response = App working!
├── ❌ Connection timeout = App not listening
└── ❌ Connection refused = Port not in security group
```

**Option 2: Using ALB (Better for Production)**

```
If you have an Application Load Balancer:

1. Go to ALB Target Groups
2. Add this EC2 instance as target
3. Port: 3000
4. Health check path: /health (or /)
5. Wait for target to become "healthy"
6. Access via: http://alb-dns.us-east-1.elb.amazonaws.com
```

### Step 4: Common Application Ports

```
Node.js (Express):         Port 3000 or 5000
Python (Flask):            Port 5000 or 8000
Python (Django):           Port 8000
Java (Spring Boot):        Port 8080
.NET (ASP.NET Core):       Port 5000 or 80
Ruby on Rails:             Port 3000
Go:                        Port 8080
```

**⚠️ Important:** Add the app port to security group inbound rules!

---

## Task 4: Monitor with CloudWatch

### Step 1: View EC2 Metrics in CloudWatch

```
AWS Console → CloudWatch → Metrics → EC2

Available metrics:
├── CPU Utilization
├── Network In/Out
├── Disk Read/Write
└── Status Check Failed
```

### Step 2: Create CloudWatch Alarm (CPU)

```
1. CloudWatch → Alarms → Create Alarm

2. Metric:
   ├── EC2
   ├── Select Instance: web-server-1
   └── Metric: CPU Utilization

3. Conditions:
   ├── Threshold: > 80%
   └── For: 5 minutes

4. Actions:
   ├── Send notification to SNS topic
   └── Create new SNS topic: web-server-alerts

5. Create Alarm
```

### Step 3: Stress Test (Generate High CPU)

```bash
# SSH into instance
ssh -i ~/.ssh/my-key.pem ubuntu@54.123.45.67

# Install stress tool
sudo apt install stress

# Generate high CPU load
stress --cpu 2 --timeout 300s

# Check CloudWatch
# → CPU Utilization should spike to 80%+
# → Alarm should trigger after 5 minutes
```

### Step 4: View Detailed Monitoring

```bash
# From instance, check current status
top
# Shows CPU, memory, processes

# Check application logs
pm2 logs node-api
# Application request logs

# Check system logs
tail -f /var/log/syslog
```

---

## Task 5: Create Custom AMI

### Why Create Custom AMI?

```
Scenario 1: Normal Approach
├── Launch instance 1
├── Wait 3-4 minutes (user data)
├── Launch instance 2
├── Wait 3-4 minutes
└── Launch instance 3... same again
Total: Launch 100 instances = 300+ minutes

Scenario 2: Custom AMI Approach
├── Launch instance, install everything
├── Create AMI from instance (2-3 minutes)
├── Launch 100 instances from AMI
├── Each instance ready in 30 seconds!
Total: 2 hours setup + 30 seconds × 100 = 3.5 hours
```

**Time saved: Huge!**

### Step 1: Create AMI from Running Instance

```
1. EC2 → Instances → web-server-1

2. Right-click Instance → Image and templates
   → Create image

3. Image Details:
   ├── Image name:        nodejs-app-v1
   ├── Image description: Node.js 18, PM2, sample app
   └── No reboot:         Unchecked (for consistency)

4. Click: "Create image"

5. Status: pending → available (5-10 minutes)
   Monitor: EC2 → AMIs
```

### Step 2: Launch New Instance from Custom AMI

```
1. EC2 → AMIs

2. Select your custom AMI: nodejs-app-v1

3. Click: "Launch instance from AMI"

4. Configuration:
   ├── Instance Type: t3.micro
   ├── Network: Your VPC
   ├── Subnet: Public Subnet
   ├── Security Group: web-server-sg
   └── User Data: NONE (already included in AMI!)

5. Launch

6. Wait 30-60 seconds (vs 3-4 minutes before!)

7. Access: http://54.234.56.78:3000
   (New instance, but app already running!)
```

### Step 3: Manage Custom AMIs

```bash
# List all custom AMIs
aws ec2 describe-images \
  --owners self \
  --query 'Images[*].[ImageId,Name,State,CreationDate]' \
  --output table

# Delete old AMI (save storage costs)
aws ec2 deregister-image --image-id ami-0abcd1234efgh5678

# Delete associated snapshots
aws ec2 delete-snapshot --snapshot-id snap-0abcd1234efgh5678
```

---

## Task 6: Troubleshooting

### Issue 1: User Data Not Running

**Symptoms:**
```
✗ Node.js not installed
✗ PM2 not found
✗ Application not running
✗ Port 3000 not listening
```

**Debugging:**

```bash
# SSH into instance
ssh -i ~/.ssh/my-key.pem ubuntu@54.123.45.67

# Check user data execution log
cat /var/log/cloud-init-output.log

# Look for:
├── ✅ SUCCESS messages
├── ❌ Error messages
└── Command output

# Check if script completed
tail -20 /var/log/cloud-init-output.log
```

**Common Causes:**

```
1. User data script has syntax errors
   └── Fix: Test script locally first

2. Application repository doesn't exist
   └── Fix: Verify GitHub URL is correct

3. Node.js installation failed
   └── Fix: Check internet connectivity, NTP sync

4. npm install fails
   └── Fix: Check package.json exists

5. PM2 not starting app
   └── Fix: Check app.js file exists
```

### Issue 2: SSH Connection Timeout

**Symptoms:**
```
ssh: connect to host 54.123.45.67 port 22: Connection timed out
```

**Debugging:**

```
1. Check instance is running
   ├── EC2 Dashboard → State: running?
   ├── Status Checks: 2/2 passed?

2. Check security group allows SSH
   ├── EC2 → Security Groups → web-server-sg
   ├── Inbound Rules: SSH port 22 from your IP?

3. Check NACL allows SSH (if using custom NACL)
   ├── VPC → Network ACLs
   ├── Inbound: Allow port 22, 1024-65535
   ├── Outbound: Allow port 22, 1024-65535

4. Check instance has public IP
   ├── EC2 Dashboard → Instance Details
   ├── Public IPv4: Has value?
   ├── If not: Allocate Elastic IP
```

### Issue 3: Application Port Not Accessible

**Symptoms:**
```
Browser: http://54.123.45.67:3000
Result: Connection refused
```

**Debugging:**

```bash
# SSH into instance
ssh -i ~/.ssh/my-key.pem ubuntu@54.123.45.67

# Check if app is listening on port 3000
netstat -tuln | grep 3000
# Should show: tcp 0 0 0.0.0.0:3000 0.0.0.0:* LISTEN

# Check PM2 status
pm2 status
# Should show: online

# Check app logs
pm2 logs node-api | tail -20

# If not listening:
pm2 start app.js  # or index.js
```

**Then check security group:**

```
1. EC2 → Security Groups → web-server-sg

2. Inbound Rules:
   ├── Custom TCP, Port 3000, 0.0.0.0/0?
   └── If not → Add this rule

3. Test again: http://54.123.45.67:3000
```

### Issue 4: High CPU Usage

**Symptoms:**
```
Instance responding slowly
CloudWatch CPU Utilization: 90%+
```

**Debugging:**

```bash
# SSH into instance
ssh -i ~/.ssh/my-key.pem ubuntu@54.123.45.67

# Check top CPU processes
top -b -n 1 | head -15

# Check Node.js process CPU
ps aux | grep node

# Check application logs
pm2 logs node-api | tail -50
# Look for errors, infinite loops

# Check memory
free -h

# Solutions:
├── If app is leaking memory: Restart PM2
├── If CPU constantly high: Upgrade instance type
└── If specific request causes spike: Debug that request
```

### Issue 5: Application Crashes After User Data

**Symptoms:**
```
User data completes successfully
But application not responding 5 minutes later
```

**Debugging:**

```bash
# SSH into instance (quickly!)
ssh -i ~/.ssh/my-key.pem ubuntu@54.123.45.67

# Check PM2 status
pm2 status
# Status: exited? stopped?

# Check if crash happened
pm2 logs node-api | tail -50
# Look for errors, stack traces

# Check if disk full
df -h
# / should have > 1 GB free

# Check if out of memory
free -h
# Available should be > 100 MB

# Restart app
pm2 restart node-api
```

### Issue 6: PM2 Processes Not Persistent After Reboot

**Symptoms:**
```
Reboot instance
SSH back in
PM2 shows no processes
Application not running
```

**Debugging:**

```bash
# Check PM2 startup configuration
pm2 startup
# Should show: [PM2] You have to run this command as root

# Fix:
sudo pm2 startup systemd -u ubuntu --hp /home/ubuntu
sudo pm2 save

# Verify
systemctl status pm2-ubuntu

# Test reboot
sudo reboot
# Wait 1-2 minutes
ssh -i ~/.ssh/my-key.pem ubuntu@54.123.45.67

# Check processes
pm2 status
# Should show application still running!
```

---

## Quick Reference: Common Commands

```bash
# Get instance details
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,PrivateIpAddress,State.Name]' --output table

# SSH into instance
ssh -i ~/.ssh/my-key.pem ubuntu@PUBLIC_IP

# Check if application is running
curl http://localhost:3000

# View PM2 processes
pm2 status
pm2 logs

# Monitor system
top
htop (if installed)

# Check logs
tail -f /var/log/cloud-init-output.log
journalctl -u service-name -f

# Stop/Start/Reboot instance (AWS CLI)
aws ec2 stop-instances --instance-ids i-0abcd1234efgh5678
aws ec2 start-instances --instance-ids i-0abcd1234efgh5678
aws ec2 reboot-instances --instance-ids i-0abcd1234efgh5678

# Terminate instance (DELETE IT)
aws ec2 terminate-instances --instance-ids i-0abcd1234efgh5678
```

---

## Checkpoint: What You've Accomplished

By now you should have:

```
✅ Launched an EC2 instance in public subnet
✅ Used User Data to auto-install Node.js
✅ Connected via SSH from your machine
✅ Verified application running on port 3000
✅ Tested application in browser
✅ Monitored instance with CloudWatch
✅ Created custom AMI from instance
✅ Launched new instance from custom AMI
✅ Troubleshot common issues
✅ Understood instance lifecycle
```

**Next Steps:**

1. Put multiple instances behind ALB (from Day 2)
2. Set up auto-scaling (Day 3 Advanced)
3. Deploy real application code
4. Set up CI/CD pipeline (Day 4)

---

## Getting Help

**Instance won't launch:**
- Check AWS service quotas
- Check account limits
- Try different availability zone

**Can't SSH:**
- Check security group (most common issue)
- Verify key pair is correct
- Check instance has public IP

**Application won't start:**
- Check user data logs: `/var/log/cloud-init-output.log`
- Verify code repository is public or has credentials
- Check application port and security group rules

**Performance issues:**
- Monitor with CloudWatch
- Increase instance type (t3.micro → t3.small)
- Add more instances behind ALB
