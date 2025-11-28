# DAY 3 - EC2 INTERVIEW QUESTIONS & ANSWERS 🎯

## 35+ Interview Questions with Detailed Explanations

Master these questions to confidently answer any EC2-related interview question. Each question includes real-world context and follow-up questions you might face.

---

## 📋 Table of Contents

1. [EC2 Fundamentals](#ec2-fundamentals)
2. [AMI & Instance Setup](#ami--instance-setup)
3. [Instance Types & Sizing](#instance-types--sizing)
4. [Spot vs On-Demand](#spot-vs-on-demand)
5. [User Data & Metadata](#user-data--metadata)
6. [Networking & Connectivity](#networking--connectivity)
7. [Monitoring & Troubleshooting](#monitoring--troubleshooting)
8. [Security & Best Practices](#security--best-practices)
9. [Cost Optimization](#cost-optimization)
10. [Architecture & Scaling](#architecture--scaling)

---

## EC2 Fundamentals

### Q1: What is Amazon EC2? Explain like I'm not technical.

**Answer:**

EC2 is like renting a computer from AWS. Instead of buying a physical server for your office, you:

1. **Rent computing power** from AWS (pay per hour)
2. **Choose the specs** (CPU, RAM, storage)
3. **Install software** you want (OS, applications, databases)
4. **Scale instantly** (add more servers in 2 minutes)

**Real-World Comparison:**

```
Traditional Server:
├── Buy hardware: $5,000 upfront
├── Setup: 2 weeks
├── Location: Your data center
├── Maintenance: Your team
├── Scaling up: Order new hardware (1 month wait)
└── Scaling down: Can't easily

AWS EC2:
├── Pay: $0.01-0.20 per hour (only what you use)
├── Setup: 2 minutes
├── Location: AWS global infrastructure
├── Maintenance: AWS handles hardware
├── Scaling up: Launch instance in 2 minutes
└── Scaling down: Terminate instance immediately
```

**Follow-up Q:** "When would you use EC2 instead of Lambda?"

**Follow-up Answer:**
```
Use EC2:
├── Long-running processes (> 15 minutes)
├── 24/7 services
├── Custom OS/software needs
└── Cost-sensitive workloads

Use Lambda:
├── Event-driven, short tasks (< 15 min)
├── Sporadic workloads
├── No infrastructure management
└── Simple functions
```

---

### Q2: What is an AMI (Amazon Machine Image)?

**Answer:**

An AMI is a **blueprint/template** that contains everything needed to launch an EC2 instance:

```
AMI = Blueprint containing:
├── Operating System (Linux, Windows)
├── Pre-installed software (Node.js, Docker, etc.)
├── Configuration files
├── File system structure
├── Permissions & security settings
└── Boot volume settings
```

**Analogy:** 

```
If EC2 is a rental house, AMI is:
├── House with plumbing already installed
├── Electricity already connected
├── Furniture already placed
├── You just move in and use it

Without AMI:
├── You'd get blank server
├── Install OS (2 hours)
├── Install software (2 hours)
├── Configure settings (1 hour)
└── Total: 5+ hours per server
```

**Types of AMIs:**

```
1. AWS-Provided:
   ├── Amazon Linux 2 (AWS-optimized)
   ├── Ubuntu Server
   ├── Red Hat Enterprise Linux
   └── Windows Server

2. Community AMIs:
   ├── Created by third parties
   ├── Free to use
   └── ⚠️ Security risk - vet carefully

3. Marketplace AMIs:
   ├── Pre-configured software
   ├── May have hourly charges
   └── Example: WordPress AMI

4. Custom AMIs:
   ├── You create from your instance
   ├── Contains your exact setup
   └── Reuse for identical servers
```

**Follow-up Q:** "How do you create a custom AMI?"

**Answer:**
```bash
1. Launch EC2 instance
2. Install software, configure, test
3. EC2 Console → Right-click → "Create image"
4. Name it: my-app-v1.0
5. Wait 5-10 minutes
6. AMI ready to launch instances from
```

---

### Q3: Explain EC2 Instance Lifecycle. What are the different states?

**Answer:**

```
Instance Lifecycle States:

pending (1-2 min)
   ↓ (OS booting, network setup)
running (hours+)
   ↓ (can stop or terminate)
   ├→ STOP → stopped → (can restart)
   │           ↓
   │        RESTART → pending → running
   │
   └→ TERMINATE → terminating → terminated (deleted)


Key Points:
├── pending: OS booting, not ready yet
├── running: Ready to use, can SSH
├── stopped: Halted but storage kept (can restart)
├── terminated: Completely deleted, can't restart
└── Charges: Only during "running" state (and "stopped" storage)
```

**Real-World Scenario:**

```
Monday-Friday (Business):
├── 9 AM: Start instances → running (Cost: $0.10/hour)
└── 5 PM: Stop instances → stopped (Cost: $0.01/hour storage only)

Saturday-Sunday (Weekend):
├── Saturday: Stopped (Cost: $0.01/hour storage)
├── Sunday: Stopped (Cost: $0.01/hour storage)
└── Save: 48 hours × ($0.10 - $0.01) = $4.32 saved!

If terminated instead:
├── No charges
├── But data deleted
└── Can't restart
```

**Follow-up Q:** "What happens to data when you stop vs terminate?"

**Answer:**
```
STOP:
├── Instance halts
├── EBS volume kept (data persists)
├── Cost: Storage charged, compute not charged
└── Can restart later

TERMINATE:
├── Instance deleted
├── EBS volume deleted (by default)
├── Data gone forever
├── Cost: Nothing
└── Cannot restart
```

---

## AMI & Instance Setup

### Q4: How does User Data differ from Metadata? When would you use each?

**Answer:**

```
USER DATA                          │  METADATA
───────────────────────────────────┼──────────────────────
Setup script (runs once)            │  Query instance info
Runs at instance launch             │  Available anytime
Installs software                   │  Read-only info
Can take 2-5 minutes               │  Returns instantly
Output: /var/log/cloud-init-*      │  No logging needed
User provides the script            │  AWS provides the info
```

**User Data Example:**

```bash
#!/bin/bash
apt update
apt install -y nodejs npm pm2
git clone https://github.com/user/repo.git
cd repo
npm install
pm2 start app.js
```

**Metadata Example:**

```bash
# From inside instance:
curl http://169.254.169.254/latest/meta-data/instance-id
# Output: i-0abcd1234efgh5678

curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
# Output: ec2-app-role

curl http://169.254.169.254/latest/meta-data/placement/availability-zone/
# Output: us-east-1a
```

**Follow-up Q:** "Can you run User Data again after instance is launched?"

**Answer:** No! User Data only runs on **first launch**.
```
Option 1: Run it again
├── SSH into instance
├── Manually run commands
└── Not recommended

Option 2: Use configuration management
├── Ansible
├── Chef
├── Puppet
└── Can run scripts repeatedly

Option 3: Re-launch instance
├── Terminate instance
├── Launch new from same AMI
├── User Data runs again
└── But loses all data
```

---

### Q5: What are the main differences between Amazon Linux 2 and Ubuntu?

**Answer:**

```
AMAZON LINUX 2         │  UBUNTU
─────────────────────────────────────────────────
AWS-optimized          │  Community-driven
Lightweight            │  More packages available
Good defaults for AWS  │  Better docs online
Smaller disk space     │  Larger community
Package manager: yum   │  Package manager: apt
User: ec2-user@        │  User: ubuntu@
───────────────────────────────────────────────

When to use Amazon Linux 2:
├── AWS-specific features needed
├── Cost optimization priority
├── AWS support wanted
└── New to Linux

When to use Ubuntu:
├── Larger developer community
├── More tutorials online
├── Specific software support
├── Corporate familiarity
```

**Follow-up Q:** "How do package managers differ?"

**Answer:**
```
Amazon Linux 2 (yum):
sudo yum update
sudo yum install nodejs
sudo yum remove nodejs

Ubuntu (apt):
sudo apt update
sudo apt install nodejs
sudo apt remove nodejs
```

---

## Instance Types & Sizing

### Q6: Explain EC2 instance type naming: t3.micro, m5.large, c5.xlarge. What do the letters and numbers mean?

**Answer:**

```
Instance Type Format: t3.micro
                      │ │ └─ Size
                      │ └─── Generation (AWS generation)
                      └───── Family (type of workload)


FAMILY (Purpose):
├── t = Burstable (variable workloads, cheap)
├── m = General Purpose (balanced CPU/RAM)
├── c = Compute Optimized (high CPU)
├── r = Memory Optimized (high RAM)
├── i = Storage Optimized (high I/O)
├── g = GPU Graphics
├── p = GPU Parallel Computing
└── x = Extreme Memory

GENERATION (AWS version):
├── 1, 2, 3, 3a = Older generations
├── 5, 6, 7 = Newer generations
└── Newer = Better performance, better price

SIZE (Capacity):
├── nano → micro → small → medium → large
├── xlarge (2 units) → 2xlarge (4 units) → etc.
└── Each step = 2x CPU, 2x RAM
```

**Real Examples:**

```
t3.micro
├── Family: t (burstable, cheap)
├── Generation: 3 (newer)
├── Size: micro
├── CPU: 1 vCPU (can burst to 3.3 GHz)
├── RAM: 1 GB
├── Cost: $0.01/hour
└── Use: Dev, testing, low-traffic sites

m5.large
├── Family: m (general purpose)
├── Generation: 5
├── Size: large
├── CPU: 2 vCPU (consistent)
├── RAM: 8 GB
├── Cost: $0.10/hour
└── Use: Web servers, small DBs

c5.xlarge
├── Family: c (compute optimized)
├── Generation: 5
├── Size: xlarge
├── CPU: 4 vCPU (high performance)
├── RAM: 8 GB
├── Cost: $0.17/hour
└── Use: ML, APIs, batch processing

r5.2xlarge
├── Family: r (memory optimized)
├── Generation: 5
├── Size: 2xlarge
├── CPU: 8 vCPU
├── RAM: 64 GB (ratio 1:8, not 1:4)
├── Cost: $0.60/hour
└── Use: Caches (Redis), databases
```

**Follow-up Q:** "How do you choose the right instance type?"

**Answer:**
```
Decision Tree:

Is it a web/app server?
├── Yes → m5.large or m5.xlarge (balanced)

Does it need high CPU?
├── Yes → c5.large or c5.xlarge (compute)

Does it need high RAM (cache, DB)?
├── Yes → r5.large or r5.xlarge (memory)

Does it need GPU (ML)?
├── Yes → g4dn.xlarge (graphics)

Budget tight + low traffic?
├── Yes → t3.micro or t3.small (burstable)

Performance critical + high load?
├── Yes → m5.xlarge or c5.xlarge (general/compute)
```

---

### Q7: What is the difference between burstable (t-family) and always-on (m-family) instances?

**Answer:**

```
BURSTABLE (t3)                │  ALWAYS-ON (m5)
─────────────────────────────────────────────
Variable workload             │  Consistent load
Baseline CPU % (10-20%)       │  Full CPU guaranteed
Burst to 100% when needed     │  100% anytime
CPU credits for bursting      │  No credits
Cheap ($0.01/hour)            │  More expensive ($0.10)
Can run out of credits        │  No limitations
Good for: Dev, websites       │  Good for: Production

Graph:
Burstable:     ╱╲   ╱╲          Always-On:  ████████████
              ╱  ╲ ╱  ╲         (Constant CPU)
             ╱    ╲    ╲
           (spiky)                
```

**Real Scenario:**

```
Blog Website:
├── Monday-Friday 9-5: Heavy traffic
├── Rest of time: No traffic
├── Use: t3.small (burstable)
│         └── Cost: $0.02/hour
│             Save money when empty
│
└── If traffic suddenly spikes:
    ├── CPU credits used for bursting
    ├── Performance maintained 30-60 min
    ├── After credits exhausted:
    │   └── Performance throttled
    └── Recover credits when idle

vs

Production API:
├── 24/7 traffic
├── Consistent load
├── Use: m5.large (always-on)
│       └── Cost: $0.10/hour
│           Full CPU guarantee
└── No throttling ever
```

**Follow-up Q:** "What happens when you run out of CPU credits on burstable instances?"

**Answer:**
```
Option 1: Unlimited Burstable (costs more)
├── Allow unlimited bursting
├── Pay for extra usage
├── Never throttled
└── Good for spiky predictable traffic

Option 2: Standard Burstable
├── Limited CPU credits
├── Throttled after credits exhausted
├── Cheap but risky
└── Good for dev/test only

Option 3: Upgrade to m5
├── Pay more but consistent
├── Better for production
└── No credit management needed
```

---

## Spot vs On-Demand

### Q8: Explain Spot Instances. How are they different from On-Demand? When would you use Spot?

**Answer:**

```
SPOT INSTANCES             │  ON-DEMAND INSTANCES
─────────────────────────────────────────────────
70-90% cheaper             │  Full price
Can be interrupted         │  Never interrupted
2-minute warning           │  No warning
Bid on unused capacity     │  Reserved for you
Price fluctuates           │  Fixed price
Can fail to launch         │  Guaranteed launch
Good for: Batch jobs      │  Good for: Production
```

**Pricing Comparison:**

```
Same instance: m5.large

On-Demand:     $0.096/hour = $70/month (always available)
Spot:          $0.029/hour = $21/month (70% cheaper!)

Savings:       49/month × 24 hours × 30 days = $47 saved!
```

**Spot Interruption Reality:**

```
Monthly interruptions: ~2-3 times per month
Duration: < 5 minutes usually
Warning: 2 minutes advance notice via AWS API

Why interrupted?
├── AWS needs capacity for on-demand customers
├── Your bid price below current spot price
└── Region/AZ demand fluctuates
```

**When to Use Spot:**

```
✅ Batch Processing (ML training)
   ├── Can restart if interrupted
   ├── Progress saved
   └── Fine with 2-3 interruptions

✅ CI/CD Pipeline
   ├── Build jobs are restartable
   ├── Can retry failed builds
   └── Save 70% on build costs

✅ Testing/Staging
   ├── Not production critical
   ├── Can handle downtime
   └── Great for saving dev costs

✅ Scalable Web Apps (with auto-scaling)
   ├── 5 spot instances behind ALB
   ├── One dies? ALB routes to 4 remaining
   ├── Auto-scaling launches replacement
   └── Users see no impact

❌ Databases
   └── Can't afford interruptions

❌ Long running processes
   └── Would need to retry

❌ Production critical
   └── Needs 99.9% availability
```

**Production Setup with Spot:**

```
Load Balancer (ON-DEMAND)
├── Always available
├── Cost: $16/month

Behind LB: 5 Spot Instances
├── Each: 70% cheaper
├── If one dies: 4 still running
├── ALB redirects traffic
├── Auto-scaling launches replacement
└── Total: $110/month for 5 m5.large

vs

All On-Demand:
├── 1 Load Balancer: $16
├── 5 instances: $350
└── Total: $366/month

Savings: $256/month (70%)! ✅
```

**Follow-up Q:** "How do you handle Spot instance interruptions?"

**Answer:**
```
1. Stateless application
   ├── State in database
   └── Any instance can handle request

2. Auto-scaling
   ├── Detects dead instance
   ├── Launches replacement
   ├── Registers with load balancer
   └── 1-2 minute recovery

3. Graceful shutdown
   ├── Receive termination notice
   ├── Stop accepting new requests
   ├── Wait for existing requests to finish
   └── Then shutdown

4. Monitoring
   ├── Check instance status
   ├── Alert if dead instances
   ├── Manual recovery if needed
   └── Logs for analysis
```

---

### Q9: Can you move a Spot Instance from one AZ to another? What about On-Demand?

**Answer:**

```
❌ NO - You cannot move instances between AZs

What you CAN do:

Option 1: Terminate + Relaunch
├── Terminate in us-east-1a
├── Launch new in us-east-1b
├── Data is LOST
├── This is the only way

Option 2: Migrate with Data
├── Take EBS snapshot (backup)
├── Copy snapshot to target AZ
├── Create volume in target AZ
├── Launch instance there
└── Attach volume
```

**Important Distinction:**

```
Availability Zone (AZ):
├── us-east-1a (different data center)
├── us-east-1b (different data center)
├── Instances CANNOT move between them
└── But ALB can span multiple AZs

Elastic IP (EIP):
├── Can move between instances
├── But same AZ only
├── Different instance, same zone
```

---

## User Data & Metadata

### Q10: Write a User Data script that installs Docker and starts a container.

**Answer:**

```bash
#!/bin/bash
# User Data script: Install Docker and run container

set -e  # Exit on error

echo "Starting User Data execution..."

# 1. Update system
apt-get update -y
apt-get upgrade -y

# 2. Install Docker
apt-get install -y docker.io

# 3. Enable Docker service
systemctl start docker
systemctl enable docker

# 4. Add current user to docker group (optional)
usermod -aG docker ubuntu

# 5. Pull Docker image
docker pull nginx:latest

# 6. Run container
docker run -d \
  --name web-server \
  -p 80:80 \
  -p 443:443 \
  --restart always \
  nginx:latest

echo "Docker setup complete!"
docker ps
```

**Explanation:**

```
#!/bin/bash               → Run as shell script
set -e                    → Exit if any command fails
apt-get update            → Get latest package list
apt-get install docker.io → Install Docker
systemctl start docker    → Start Docker service
systemctl enable docker   → Auto-start on reboot
docker pull nginx         → Download image
docker run -d             → Run container in background
-p 80:80                  → Map port 80 container→host
--restart always          → Auto-restart if fails
nginx:latest              → Image to run
```

**Test It:**

```bash
# After instance running, SSH in
ssh -i key.pem ubuntu@IP

# Check Docker
docker ps
# Should show nginx container running

# Test web server
curl http://localhost
# Should return nginx HTML
```

**Follow-up Q:** "What if you want to run a custom application instead of nginx?"

**Answer:**
```bash
#!/bin/bash
set -e

# 1. Install Docker
apt-get update -y
apt-get install -y docker.io

# 2. Clone app code
git clone https://github.com/user/app.git /app

# 3. Build Docker image
cd /app
docker build -t my-app:latest .

# 4. Run container
docker run -d \
  --name my-app \
  -p 3000:3000 \
  --restart always \
  my-app:latest
```

---

### Q11: You want to get the instance ID, availability zone, and IAM role from metadata. Write the curl commands.

**Answer:**

```bash
# From inside running instance:

# Get Instance ID
curl http://169.254.169.254/latest/meta-data/instance-id
# Output: i-0abcd1234efgh5678

# Get Availability Zone
curl http://169.254.169.254/latest/meta-data/placement/availability-zone
# Output: us-east-1a

# Get IAM Role Name
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
# Output: ec2-app-role

# Get IAM Role Credentials
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/ec2-app-role
# Output: JSON with AccessKeyId, SecretAccessKey, Token, Expiration

# Get Public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4
# Output: 54.123.45.67

# Get Private IP
curl http://169.254.169.254/latest/meta-data/local-ipv4
# Output: 10.0.1.42

# Get Security Groups
curl http://169.254.169.254/latest/meta-data/security-groups
# Output: web-server-sg, default

# Get Instance Type
curl http://169.254.169.254/latest/meta-data/instance-type
# Output: t3.micro

# Get all metadata (verbose)
curl http://169.254.169.254/latest/meta-data/
```

**Real-World Use Case:**

```bash
#!/bin/bash
# Script to configure app based on instance metadata

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
AVAILABILITY_ZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

# Write to config file
cat > /etc/app-config.json << EOF
{
  "instance_id": "$INSTANCE_ID",
  "region": "$AVAILABILITY_ZONE",
  "private_ip": "$PRIVATE_IP",
  "deployed_at": "$(date)"
}
EOF

# Use in your application
node app.js
```

---

## Networking & Connectivity

### Q12: You can't SSH into your instance. What are the common causes and how do you debug?

**Answer:**

```
Error: ssh: connect to host 54.123.45.67 port 22: Connection timed out

Debugging Checklist:

1. ✅ Is instance running?
   └── EC2 Dashboard → State: running?

2. ✅ Does instance have public IP?
   └── EC2 Dashboard → Public IPv4: 54.123.45.67?
   └── If no: Allocate Elastic IP

3. ✅ Security Group allows SSH?
   └── EC2 Dashboard → Security groups
   └── Inbound Rules: SSH (port 22) from your IP?
   └── ⚠️ Most common issue!

4. ✅ NACL allows SSH?
   └── VPC → Network ACLs
   └── Rule 100 (inbound): Allow TCP 22
   └── Ephemeral ports (1024-65535) allowed

5. ✅ Correct key pair?
   └── ls ~/.ssh/
   └── Using: ssh -i /path/to/correct/key.pem

6. ✅ Key permissions correct?
   └── chmod 400 ~/.ssh/my-key.pem
   └── Not 644 or 755

7. ✅ Instance Status Checks Passed?
   └── EC2 Dashboard → Status Checks tab
   └── Both should show "2/2 passed"
   └── If pending: Wait 2-3 minutes

8. ✅ Correct username?
   └── Ubuntu AMI: ubuntu@54.123.45.67
   └── Amazon Linux: ec2-user@54.123.45.67
   └── Not root@

9. ✅ Network ACL allows ephemeral ports?
   └── Outbound: TCP 1024-65535 (for response)
```

**Step-by-Step Fix:**

```bash
# Step 1: Check security group
aws ec2 describe-security-groups \
  --group-ids sg-0abcd1234efgh5678 \
  --query 'SecurityGroups[0].IpPermissions' \
  --output table

# Should show:
# IpProtocol: tcp
# FromPort: 22
# ToPort: 22
# IpRanges: 0.0.0.0/0 or YOUR_IP/32

# Step 2: If no SSH rule, add it
aws ec2 authorize-security-group-ingress \
  --group-id sg-0abcd1234efgh5678 \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_PUBLIC_IP/32

# Step 3: Get instance public IP
aws ec2 describe-instances \
  --instance-ids i-0abcd1234efgh5678 \
  --query 'Reservations[0].Instances[0].PublicIpAddress'

# Step 4: SSH with verbose output
ssh -vvv -i ~/.ssh/my-key.pem ubuntu@54.123.45.67

# Step 5: If still fails, check instance status
aws ec2 describe-instance-status \
  --instance-ids i-0abcd1234efgh5678 \
  --query 'InstanceStatuses[0].[InstanceStatus.Status,SystemStatus.Status]'
```

---

### Q13: What is an Elastic IP? When and why would you use it?

**Answer:**

```
Elastic IP (EIP):
├── Static public IP address
├── Stays with instance even after stop/start
├── Can be moved between instances
├── Costs if NOT attached ($0.005/hour)
└── Free if attached to running instance

Public IP (Regular):
├── Temporary dynamic IP
├── Lost when instance stops/starts
├── Can't be reserved
└── Always free
```

**When to Use Elastic IP:**

```
✅ Use Elastic IP:
├── Production servers with static IP
├── Hardcoded IP in config
├── Domain name points to EIP (DNS)
├── IP-based firewall rules
├── Database connection from fixed IP
└── Cost: Free if attached to running instance

❌ Don't Need Elastic IP:
├── Instance behind load balancer
├── Short-lived instances
├── Development/testing only
├── Auto-scaling groups
└── Cost saved: Don't waste $0.005/hour
```

**Real Scenario:**

```
Scenario 1: Production API Server
├── Domain: api.myapp.com
├── Points to: Elastic IP 52.12.34.56
├── Clients rely on this IP
├── If IP changes: Clients fail
└── NEED: Elastic IP ✅

Scenario 2: Database with IP-based Auth
├── Corporate firewall allows: 52.12.34.56
├── Backups run from this IP
├── If IP changes: Backups fail
└── NEED: Elastic IP ✅

Scenario 3: Web Server Behind ALB
├── Users connect to: ALB DNS name
├── ALB routes to: Instance (any IP)
├── If instance IP changes: No impact
├── Users still reach ALB
└── DON'T NEED: Elastic IP ✗
└── Save: $0.005/hour × 730 hours = $3.65/month
```

---

## Monitoring & Troubleshooting

### Q14: How do you monitor EC2 instances? What metrics are important?

**Answer:**

```
Key Metrics to Monitor:

CPU Utilization
├── % of compute power used
├── Alarm if > 80% (scale up)
├── Alarm if < 10% (scale down)
└── CloudWatch: AWS/EC2 namespace

Memory Utilization
├── ⚠️ NOT tracked by default
├── Install CloudWatch Agent
└── Then monitor %usage

Network In/Out
├── Bytes sent/received
├── Alarm if spike (DDoS detection)
└── CloudWatch: NetworkIn, NetworkOut

Disk I/O
├── Read/Write operations
├── High = Slow app
└── Consider: Upgrade to SSD, add caching

Status Checks
├── System Status: AWS infrastructure
├── Instance Status: OS-level
├── Alarm if failures (reboot/replace)
└── Take 5-10 minutes to trigger

Disk Free Space
├── ⚠️ NOT tracked by default
├── Install CloudWatch Agent
├── Alarm if < 10% free
└── Manual cleanup or scale storage
```

**Setting Up Monitoring:**

```bash
# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Create config (memory, disk metrics)
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Start agent
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent
```

**Create Alarms:**

```
CloudWatch → Alarms → Create Alarm

Example 1: High CPU
├── Metric: CPU Utilization
├── Threshold: > 80%
├── Duration: 5 minutes
├── Action: Send SNS email

Example 2: Memory High
├── Metric: mem_used_percent
├── Threshold: > 85%
├── Duration: 5 minutes
├── Action: Auto-scaling (add instance)

Example 3: Disk Low
├── Metric: disk_used_percent
├── Threshold: > 90%
├── Duration: 10 minutes
├── Action: Alert ops team
```

---

### Q15: Your application keeps crashing. How do you troubleshoot?

**Answer:**

```
Debugging Checklist:

1. SSH into instance
   └── ssh -i key.pem ubuntu@IP

2. Check process status
   ├── ps aux | grep app-name
   ├── Is it running? No = crashed
   └── killed why?

3. Check application logs
   ├── tail -f /var/log/app.log
   ├── Look for errors, stack traces
   └── Find root cause

4. Check system logs
   ├── tail -f /var/log/syslog
   ├── Look for: OOM (out of memory), kernel panics
   └── Check free memory: free -h

5. Check disk space
   ├── df -h
   ├── If 100% full: Delete temp files
   ├── Or: Add volume, expand partition

6. Check resource usage
   ├── top (shows CPU, memory)
   ├── Is app consuming everything?
   └── Other processes?

7. If using PM2 (process manager)
   ├── pm2 status
   ├── pm2 logs app-name
   ├── pm2 monit
   └── pm2 restart app-name

8. If using systemd service
   ├── systemctl status app-name
   ├── journalctl -u app-name -f
   ├── systemctl restart app-name
```

**Common Causes & Fixes:**

```
1. Out of Memory (OOM)
   ├── Symptom: App crashes randomly
   ├── Check: free -h
   ├── Fix: Restart app, upgrade instance
   └── Long-term: Find memory leak in code

2. Disk Full
   ├── Symptom: App can't write logs
   ├── Check: df -h
   ├── Fix: Delete old logs, expand volume
   └── Long-term: Implement log rotation

3. Database Connection Failed
   ├── Symptom: App crashes on DB query
   ├── Check: Can app reach RDS?
   ├── Verify: Security group allows port 5432
   └── Verify: RDS is running

4. Port Already in Use
   ├── Symptom: App won't start, port 3000 in use
   ├── Check: lsof -i :3000
   ├── Fix: Kill other process or change port
   └── Long-term: Use PM2 or systemd for auto-restart

5. Missing Dependencies
   ├── Symptom: "Module not found" error
   ├── Check: npm list (for Node)
   ├── Fix: npm install
   └── Long-term: Include node_modules in deployment

6. Environment Variables Missing
   ├── Symptom: "Cannot read property 'apiKey' of undefined"
   ├── Check: env | grep API_KEY
   ├── Fix: Export variables or use .env file
   └── Long-term: Use AWS Secrets Manager
```

---

## Security & Best Practices

### Q16: What are EC2 security best practices?

**Answer:**

```
1. Restrict SSH Access ✅
   ├── ❌ Bad: SSH from 0.0.0.0/0
   ├── ✅ Good: SSH from specific IP
   ├── ✅ Best: Use Bastion host
   └── ✅ Best: Use EC2 Instance Connect (no SSH key)

2. Use IAM Roles Instead of Access Keys ✅
   ├── ❌ Bad: Hardcode AWS credentials in code
   ├── ✅ Good: Attach IAM role to instance
   ├── AWS SDK auto-discovers credentials
   └── Automatic credential rotation

3. Regular Security Updates ✅
   ├── apt update && apt upgrade -y
   ├── Run monthly
   ├── Or: Rebuild AMI with latest patches
   └── Or: Use Systems Manager Patch Manager

4. Implement Defense-in-Depth ✅
   ├── Layer 1: NACL (stateless firewall)
   ├── Layer 2: Security Group (stateful firewall)
   ├── Layer 3: Host-level firewall (ufw)
   └── Layer 4: Application-level auth

5. Encrypt Data ✅
   ├── Encryption in Transit: HTTPS, TLS
   ├── Encryption at Rest: EBS encryption
   ├── AWS KMS: Manage encryption keys
   └── Secrets Manager: Store passwords

6. Monitor & Log ✅
   ├── CloudWatch logs for app
   ├── CloudTrail logs for AWS API calls
   ├── Application logs with timestamps
   └── Send to centralized logging system

7. Use VPC Features ✅
   ├── Public subnet: Only if web-facing
   ├── Private subnet: For databases, app servers
   ├── NAT gateway: Outbound internet from private
   └── VPC Flow Logs: Debug network issues

8. Patch Management ✅
   ├── Ubuntu: apt update && apt upgrade -y
   ├── Amazon Linux: yum update -y
   ├── Run: Weekly or monthly
   └── Automate: Systems Manager Agent

9. Principle of Least Privilege ✅
   ├── Only open needed ports
   ├── Only allow needed IPs
   ├── Only give needed IAM permissions
   └── Audit: What does this need access to?

10. Termination Protection ✅
    ├── Prevent accidental deletion
    ├── EC2 Dashboard → Right-click → Instance Settings
    ├── Check: Termination Protection
    └── Can't terminate until unchecked
```

---

### Q17: How do you use IAM roles with EC2 instances? Why not just hardcode AWS credentials?

**Answer:**

```
❌ Hardcoding Credentials (BAD):
────────────────────────────────
// app.js
const AWS = require('aws-sdk');
const s3 = new AWS.S3({
  accessKeyId: 'AKIAIOSFODNN7EXAMPLE',
  secretAccessKey: 'wJalrXUtnFEMI/K7MD.../...'
});

Problems:
├── Credentials visible in code ⚠️
├── In GitHub → World can see it
├── Hard to rotate credentials
├── Same creds for all instances
├── Can't revoke individual instances
└── Audit trail unclear


✅ Using IAM Roles (GOOD):
───────────────────────────
// app.js
const AWS = require('aws-sdk');
const s3 = new AWS.S3();  // ← Finds creds automatically!

Benefits:
├── No credentials in code ✅
├── AWS SDK auto-discovers role credentials
├── Credentials short-lived (auto-refresh)
├── Different role per instance
├── Can revoke at instance/role level
├── Audit trail: Which role accessed what
└── Easy credential rotation
```

**How to Use IAM Roles:**

```
Step 1: Create IAM Role
├── AWS Console → IAM → Roles → Create role
├── Trust entity: AWS service → EC2
├── Permissions: AmazonS3FullAccess (example)
└── Name: ec2-app-role

Step 2: Launch EC2 with Role
├── EC2 Dashboard → Launch instances
├── Advanced Details → IAM instance profile: ec2-app-role
└── Launch

Step 3: In Application Code
// Node.js automatically finds credentials
const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const objects = await s3.listBuckets().promise();

// Python
import boto3
s3 = boto3.client('s3')  # ← Finds creds automatically
response = s3.list_buckets()

// Java
software.amazon.awssdk.services.s3.S3Client s3 = S3Client.builder().build();
ListBucketsResponse buckets = s3.listBuckets();
```

**Credential Resolution Order:**

```
AWS SDK looks for credentials in this order:

1. Environment Variables (if set)
2. Instance Profile (IAM Role) ← Current instance
3. Shared credentials file (~/.aws/credentials)
4. ECS Task Role (if running in ECS)
5. Fails if none found
```

**Audit Trail Example:**

```
CloudTrail Log:

{
  "eventTime": "2024-01-28T10:05:03Z",
  "sourceIPAddress": "10.0.1.42",  ← Private IP of instance
  "userAgent": "aws-cli/2.0.0",
  "requestParameters": {
    "bucketName": "my-app-bucket"
  },
  "eventName": "ListBucket",
  "userIdentity": {
    "type": "AssumedRole",
    "arn": "arn:aws:iam::123456789012:role/ec2-app-role",
    "accountId": "123456789012",
    "roleId": "AIDAI...",
    "sessionContext": {
      "sessionIssuer": {
        "arn": "arn:aws:iam::123456789012:role/ec2-app-role"
      }
    }
  }
}

Insight:
├── Exactly which role made the request
├── When exactly it happened
├── From which instance IP
└── Can be traced back to EC2 instance
```

---

## Cost Optimization

### Q18: You're running 10 EC2 instances 24/7 costing $2,400/month. How would you reduce costs?

**Answer:**

```
Current Setup (Bad):
├── 10 × m5.large On-Demand
├── 24/7 × $0.096/hour
├── 730 hours/month
└── Cost: 10 × $70/month = $700/month

Wait, you said $2,400? That's 24/7 operation of expensive instances.
Let's assume: 10 × c5.xlarge = $0.17/hour
├── Cost: 10 × $0.17 × 730 = $1,241/month


Cost Reduction Strategy:

1. Use Spot Instances (Save 70%)
   ├── 10 Spot instances × $0.051/hour (70% cheaper)
   ├── Cost: 10 × $0.051 × 730 = $372/month
   ├── Savings: $1,241 - $372 = $869/month
   └── Catch: Can be interrupted (need auto-scaling)

2. Stop During Off-Hours (Save 50%)
   ├── If not used nights/weekends:
   ├── Business hours: On (8:00 AM - 6:00 PM)
   ├── After hours: Off (saves compute)
   ├── Storage still charged: $0.10/GB/month
   ├── Savings: ~50% of compute costs = $620/month
   └── Setup: AWS Lambda + EventBridge (auto stop/start)

3. Reserved Instances (Save 40% vs on-demand)
   ├── 1-year commitment: 40% discount
   ├── 3-year commitment: 60% discount
   ├── For: Baseline capacity (always running)
   ├── Cost: 10 × $0.096 × 0.4 (40% off) × 730 = $264/month
   ├── Savings: $700 - $264 = $436/month
   └── Catch: Can't cancel early without penalty

4. Right-size Instances
   ├── Currently: c5.xlarge (4 vCPU, 8 GB RAM)
   ├── Actual usage: 20% CPU, 30% RAM
   ├── Downsize to: t3.large (2 vCPU, 8 GB RAM)
   ├── Cost: $0.10/hour instead of $0.17
   ├── Savings: ($0.17 - $0.10) × 10 × 730 = $511/month
   └── Risk: Less headroom for spikes

5. Consolidate Workloads
   ├── 10 small instances → 5 larger instances + ALB
   ├── More efficient resource usage
   ├── Cost: 5 × $0.10 × 730 + ALB = $365 + $16 = $381/month
   └── Savings: $700 - $381 = $319/month

6. Use Auto-Scaling
   ├── 24/7: Only 2 instances baseline
   ├── Peak hours (8 AM-6 PM): Scale to 10
   ├── Average cost: (2 × 730 + 8 × 250) × $0.10 = $346/month
   └── Savings: $700 - $346 = $354/month

7. Combine All (Maximum Savings):
   ├── Reserved instances: Baseline 2 × $0.06 × 730 = $88
   ├── Spot for scaling: 8 × $0.051 × 250 = $102
   ├── Off-hours: 0 cost
   ├── Right-size to: t3.medium (cheaper)
   └── Total: ~$250/month (from $700)
   └── Savings: 64%! 🎉
```

**Recommended Approach (Balanced):**

```
Tier 1: Use Reserved Instances
├── Commit to baseline capacity (2 instances)
├── 1-year: 40% discount
├── Cost: 2 × $0.06 × 730 = $88/month
└── For: Database, core services

Tier 2: Use Spot Instances
├── Auto-scaling from 2 → 10
├── 70% discount on excess capacity
├── Cost: 8 × $0.051 × 250 (peak hours) = $102/month
└── For: Web servers, stateless services

Tier 3: Stop During Off-Hours
├── Stop all 10 instances 6 PM - 8 AM
├── Weekends: All off
├── Cost: Storage only ($50-100/month)
└── Setup: EventBridge + Lambda

Total: $88 + $102 + $75 = $265/month
From: $700/month
Savings: 62%! 💰
```

---

### Q19: What is a Reserved Instance (RI)? When should you buy one?

**Answer:**

```
Reserved Instance (RI) = Commitment discount

How it works:
├── Commit to run instance for 1 or 3 years
├── Get discount: 40% (1-year) or 60% (3-year)
├── Must be specific instance type/region
├── Can't cancel without penalty
└── Costs upfront + hourly rate

Example - m5.large in us-east-1:

On-Demand:        $0.096/hour
├── 730 hours/month = $70/month
├── 12 months = $840/year
└── No commitment

1-Year RI (40% off): $0.058/hour
├── Upfront: $300
├── Hourly: $0.058
├── Monthly: $42
├── 12 months: $300 + (12 × $42) = $804/year
└── Savings: $36/year (small)

3-Year RI (60% off): $0.038/hour
├── Upfront: $600
├── Hourly: $0.038
├── Monthly: $28
├── 36 months: $600 + (36 × $28) = $1,608 (3 years)
└── Savings: $1,512 (3 years) = $504/year
```

**When to Buy RIs:**

```
✅ Use Reserved Instances:
├── Baseline capacity (always running)
├── Production critical
├── Predictable, stable workload
├── Can commit 1+ years
├── Database servers
└── Load balancers

✅ Compute: 
├── Baseline 5 instances
├── Buy 5 × 3-year RIs
├── Saves ~60% vs on-demand

❌ Don't Use RIs:
├── Experimental workloads
├── Testing environments (use Spot)
├── Temporary infrastructure
├── Unpredictable demand
└── Short-term projects

Strategy - Hybrid Approach:
├── Tier 1: RI for baseline (always on)
├── Tier 2: Spot for scaling (burst capacity)
├── Tier 3: On-demand for peak (emergency)
└── Result: Minimum cost, maximum flexibility
```

---

## Architecture & Scaling

### Q20: Design a scalable web application architecture using EC2, ALB, and Auto Scaling.

**Answer:**

```
SCALABLE WEB APPLICATION ARCHITECTURE

Internet Users
       │
       ↓
[Route53] - DNS routing
       │
       ↓
[CloudFront] - CDN (optional, for static assets)
       │
       ↓
┌─────────────────────────────────────────┐
│ Application Load Balancer (Always On)   │
│ ├─ Sits in: Public Subnets (AZ-1 & 2)  │
│ ├─ Listens on: Port 80 & 443           │
│ ├─ Auto-scales: Health checks          │
│ └─ Cost: ~$16/month                    │
└────────────────┬────────────────────────┘
                 │ (Distributes traffic)
    ┌────────────┼────────────┐
    ↓            ↓            ↓
┌────────┐  ┌────────┐  ┌────────┐
│Web-EC2-1  │Web-EC2-2  │Web-EC2-3   │ (Minimum 2 running)
│  t3.small │ t3.small  │ t3.small   │ (Auto-scaling group)
│Port 3000  │Port 3000  │Port 3000   │
│ Healthy   │ Healthy   │ Health check
└────────┘  └────────┘  └────────┘
    │            │            │
    └────────────┼────────────┘
                 │
                 ↓
        ┌──────────────────┐
        │   RDS Database   │
        │ (Private Subnet) │
        │  Multi-AZ        │
        └──────────────────┘
```

**Auto Scaling Group Configuration:**

```
Minimum instances:  2 (always running)
Desired instances:  4 (optimal baseline)
Maximum instances:  10 (peak traffic)

Scaling Policies:

Scale UP when:
├── Average CPU > 70% for 2 minutes
├── Add 2 instances at a time
└── Wait 5 minutes before next scale

Scale DOWN when:
├── Average CPU < 30% for 10 minutes
├── Remove 1 instance at a time
└── Wait 10 minutes before next scale
```

**Traffic Flow During Scaling:**

```
Scenario 1: Normal Traffic (2 instances)
├── ALB distributes to 2 instances
├── Cost: 2 × $0.025/hour (t3.small) = $0.05/hour

Scenario 2: Traffic Spike (8 AM Monday)
├── CPU jumps to 80%
├── Auto-scaling triggered
├── 1-2 minutes: Launch instances 3 & 4
├── Instances booting (User Data running)
├── 2-4 minutes: Instances 3 & 4 available
├── ALB distributes to 4 instances
├── CPU drops to 45%
└── Cost: 4 × $0.025/hour = $0.10/hour

Scenario 3: Holiday Weekend (Low Traffic)
├── CPU stays < 30% for 10 min
├── Auto-scaling triggered
├── Gracefully drain connections from instances 3 & 4
├── Wait for existing requests to finish
├── Terminate instances 3 & 4
├── Back to 2 instances
└── Cost: 2 × $0.025/hour = $0.05/hour

Scenario 4: Planned Deployment
├── Deployment: Push new code
├── ASG replaces instances gradually
├── Old instances: Graceful shutdown (30 sec)
├── New instances: Launch with latest code
├── During deployment: Full capacity maintained!
└── Zero downtime deployment ✅
```

**High Availability with Multi-AZ:**

```
┌──────────────────────────┐
│ ALB (spans AZ-1 & AZ-2)  │
└────────────┬─────────────┘
             │
    ┌────────┴────────┐
    ↓                 ↓

AZ-1 (us-east-1a)   AZ-2 (us-east-1b)
├── EC2-1 (web)     ├── EC2-3 (web)
├── EC2-2 (web)     ├── EC2-4 (web)
└── Subnet A        └── Subnet B

Benefit:
├── If AZ-1 goes down: AZ-2 still serving traffic
├── If one instance fails: 3 others handle it
├── Automatic failover by ALB health checks
└── 99.9% availability
```

**Monitoring & Alerts:**

```
CloudWatch Metrics:

1. ALB Target Health
   ├── Healthy targets: Should be >= 2
   ├── Unhealthy targets: Alert if > 0
   └── Status: Green = all good

2. ASG Activity
   ├── Desired capacity: 4
   ├── Current capacity: 4
   ├── In-service instances: 4
   └── Terminated instances: Alert if unexpected

3. Instance Metrics
   ├── CPU Utilization: Average should be 40-60%
   ├── Network In/Out: Spike = DDoS?
   ├── EBS Operations: Slow = Need caching?
   └── Status Checks: Should be 2/2 passed

4. Application Metrics
   ├── Request count: Track trends
   ├── Error rate: Should be < 0.1%
   ├── Response time: Should be < 200ms
   └── Database connections: Pool healthy?
```

**Cost Calculation:**

```
ASG with t3.small instances:

Minimum 2 × 24 hours × 30 days × $0.025/hour = $36/month
Scaling 2-10 average 4 × 24 × 30 × $0.025 = $72/month
Subtotal: $108/month

ALB:
├── Fixed: $16/month
├── Data processing: $0.006/GB (usually negligible)
└── Total: ~$16-25/month

RDS Multi-AZ:
├── db.t3.small × 2: $0.05/hour
├── Cost: $0.05 × 730 hours = $36.50/month
└── Backups: ~$10/month

Storage (EBS):
├── 50 GB × $0.10 = $5/month

Total Monthly Cost: ~$180/month
Per instance: Very cheap ($15/month each)
With 1M+ requests/month: Highly scalable
```

---

## Advanced Questions (Bonus)

### Q21: What is the difference between stopping and terminating an EC2 instance?

Already answered in Q3, but key points:
- **Stop:** Data kept, can restart, charged for storage only
- **Terminate:** Data deleted, can't restart, no charges

---

### Q22: You want to migrate an instance from one AZ to another. How?

**Answer:**

```
Option 1: Simple (Data Lost)
├── Terminate instance in AZ-1a
├── Launch new instance in AZ-1b
└── Re-deploy application
└── Fast but loses data

Option 2: With Data (Best)
├── Create EBS snapshot of root volume
├── Wait for snapshot complete
├── Copy snapshot to target AZ
├── Create volume from snapshot in target AZ
├── Launch instance in target AZ
├── Attach volume as root device
├── Boot instance
└── Application + data preserved!

Option 3: AMI Method
├── Stop instance in AZ-1a
├── Create AMI from instance
├── Launch from AMI in AZ-1b
├── Data on root volume kept
└── Quick and clean
```

---

### Q23: Can you modify instance type after launch? (Like t3.micro → t3.small)

**Answer:**

```
✅ YES - You can resize!

Requirements:
├── Instance must be EBS-backed (not instance store)
├── Instance must be STOPPED
├── Elastic IP helps (if you need static IP)

Steps:
1. Stop instance
2. EC2 Dashboard → Right-click → Instance Settings
3. Change instance type
4. Confirm
5. Start instance
6. Wait 2-3 minutes for resize

Cost Impact:
├── If upgrading: Higher hourly cost
├── If downgrading: Lower hourly cost
└── Changes apply immediately next time you start

Limitations:
├── Can't change some families (t → c requires different AMI)
├── Can't resize instance store instances
└── Check AWS docs for compatibility
```

---

## Summary: Key EC2 Concepts

```
EC2 Basics:
├── Virtual server in AWS cloud
├── Pay per hour (or per second)
├── Choose OS, software, configuration
└── Scale instantly

AMI:
├── Blueprint/template
├── Contains OS + software
├── Reusable for multiple instances
└── Can be custom-made

Instance Types:
├── t = Burstable (cheap)
├── m = General purpose (balanced)
├── c = Compute optimized (CPU)
├── r = Memory optimized (RAM)
├── i = Storage optimized (I/O)
└── g/p = GPU (machine learning)

Lifecycle:
├── pending → running → stop/terminate
├── Stop: Halt but keep data
├── Terminate: Delete everything
└── Only pay during "running"

User Data:
├── Setup script
├── Runs once at first launch
├── Install software, configure OS
└── Output: /var/log/cloud-init-output.log

Metadata:
├── Query instance information
├── Available anytime (running)
├── Get instance ID, IAM role, IPs
└── Endpoint: 169.254.169.254/latest/

Networking:
├── Public IP: Temporary, free
├── Elastic IP: Permanent, costs if unused
├── Both in security group for firewall
└── Security group = stateful firewall

Monitoring:
├── CloudWatch for metrics
├── CPU, Memory, Network, Disk I/O
├── Create alarms for thresholds
└── Auto-scaling based on metrics

Security:
├── Restrict SSH access
├── Use IAM roles (not hardcoded keys)
├── Update regularly
├── Defense-in-depth (multiple layers)
├── Encrypt data in transit and at rest
└── Monitor all access via CloudTrail

Scaling:
├── Use Auto Scaling Group
├── Minimum 2 instances for HA
├── Scale up on high CPU (< 2 min)
├── Scale down on low CPU (< 5 min)
└── Always use ALB in front

Cost:
├── On-Demand: Full price, no commitment
├── Reserved: 40% off (1-yr) or 60% off (3-yr)
├── Spot: 70% off but can be interrupted
├── Optimize: Use hybrid of all three
└── Save 60-80% with right architecture
```

---

## Interview Tips

```
1. Know the difference:
   ├── EC2 vs Lambda
   ├── Security Group vs NACL
   ├── User Data vs Metadata
   ├── AMI vs EC2 instance
   └── Stop vs Terminate

2. Have examples ready:
   ├── "I once fixed SSH timeout by..."
   ├── "I optimized costs by..."
   ├── "I scaled an application using..."
   └── Real scenarios you've handled

3. Ask clarifying questions:
   ├── "Is this a production system?"
   ├── "What's the expected traffic?"
   ├── "What's the SLA requirement?"
   └── "Are there budget constraints?"

4. Draw architecture:
   ├── Whiteboard = Draw your design
   ├── Show multiple layers
   ├── Explain failover scenarios
   └── Discuss cost tradeoffs

5. Mention security:
   ├── "I'd restrict SSH access"
   ├── "I'd use IAM roles"
   ├── "I'd enable CloudTrail logging"
   └── "I'd implement defense-in-depth"

6. Think about operations:
   ├── "How do I monitor this?"
   ├── "How do I troubleshoot issues?"
   ├── "How do I scale during peak?"
   ├── "How do I deploy new code?"
   └── "What happens if component fails?"
```

Good luck on your interviews! 🚀
