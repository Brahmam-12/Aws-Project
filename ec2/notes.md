# DAY 3 - EC2 DEEP DIVE 🚀

## Complete EC2 Mastery Guide

Master Amazon EC2 from basics to advanced production deployment. By the end of Day 3, you'll understand every aspect of EC2 and be able to launch, manage, and troubleshoot instances confidently.

---

## 📚 Table of Contents

1. [EC2 Fundamentals](#ec2-fundamentals)
2. [AMI (Amazon Machine Image)](#ami-amazon-machine-image)
3. [EC2 Instance Types](#ec2-instance-types)
4. [EC2 Instance Lifecycle](#ec2-instance-lifecycle)
5. [User Data vs Metadata](#user-data-vs-metadata)
6. [Key Pairs & SSH Access](#key-pairs--ssh-access)
7. [Spot vs On-Demand Instances](#spot-vs-on-demand-instances)
8. [Elastic IP & Public IP](#elastic-ip--public-ip)
9. [EC2 Monitoring & CloudWatch](#ec2-monitoring--cloudwatch)
10. [Security Best Practices](#security-best-practices)

---

## EC2 Fundamentals

### What is EC2?

**EC2 = Elastic Compute Cloud**

Think of it as a **virtual computer in the cloud**:
- You rent computing power (CPU, RAM, Storage)
- You control the OS, applications, and configurations
- You pay only for what you use
- You can scale up or down instantly

### Real-World Analogy

```
Physical Server in Your Data Center
├── Limited capacity
├── Takes weeks to add hardware
├── You manage cooling, electricity, security
└── High upfront cost

AWS EC2
├── Unlimited capacity (pay-as-you-go)
├── Launch new server in 2 minutes
├── AWS manages infrastructure
└── Pay hourly (or per second)
```

### EC2 Relationship to VPC & Security Groups

```
VPC (Virtual Private Cloud)
├── Network boundary
├── Contains Subnets
└── EC2 instances launch into Subnets
    ├── Instance gets Private IP from Subnet CIDR
    ├── Instance attached to Security Group
    │   └── SG controls inbound/outbound traffic
    └── If in Public Subnet:
        └── Can be assigned Elastic/Public IP
```

**Key Point:** EC2 is **compute** | VPC is **network** | Security Group is **firewall**

---

## AMI (Amazon Machine Image)

### What is an AMI?

An **AMI is a template** that contains:
- ✅ Operating System (Linux, Windows)
- ✅ Pre-installed software (Node.js, Docker, etc.)
- ✅ Configuration settings
- ✅ File systems and partitions
- ✅ Permissions and security configurations

### Think of AMI as a **Blueprint**

```
Traditional Approach:
1. Get blank server
2. Install OS (30 min)
3. Install software (1 hour)
4. Configure settings (30 min)
5. Test everything
Total: 2+ hours for each server

AWS AMI Approach:
1. Create custom AMI once with all software
2. Launch 100 instances from this AMI in seconds
Total: 2 hours first time, 2 seconds per subsequent instance
```

### Types of AMIs

#### 1. **AWS-Provided AMIs** (Free/Cheap)

```
Amazon Linux 2
├── Lightweight
├── AWS-optimized
├── Best for: Production servers
└── Cost: Free tier eligible

Ubuntu 20.04 / 22.04
├── Popular in developer community
├── Wider software support
├── Best for: General purpose
└── Cost: Very cheap (micro = free tier)

Red Hat Enterprise Linux (RHEL)
├── Enterprise-grade
├── Long-term support
├── Best for: Corporate environments
└── Cost: Paid

Windows Server 2022
├── Full Windows OS
├── For .NET, SQL Server apps
├── Best for: Windows-only applications
└── Cost: Expensive (~$0.50/hour extra)
```

#### 2. **Community AMIs**

Free AMIs created by third parties. **⚠️ Security Risk!** Use only from trusted sources.

#### 3. **Marketplace AMIs**

Pre-configured software (WordPress, Jenkins, Docker). May have hourly charges on top of EC2 cost.

#### 4. **Custom AMIs**

Create your own by:
1. Launch EC2 instance
2. Install and configure software
3. Create image → "Create Image"
4. Use for future launches

### AMI Versioning & Updates

```
Amazon Linux 2 AMI Versions:
├── amzn2-ami-hvm-2.0.20231115.0-x86_64-gp2 ← Latest
├── amzn2-ami-hvm-2.0.20231101.0-x86_64-gp2
├── amzn2-ami-hvm-2.0.20231015.0-x86_64-gp2
└── ...

When you launch, always use LATEST version!
(Older versions = outdated security patches)
```

**Best Practice:** 
- Use AWS-provided AMIs for consistency
- Update your custom AMI every 3-6 months with security patches
- Document what's installed in each custom AMI

---

## EC2 Instance Types

### Instance Type Naming Convention

```
t3.micro
│ │ └─ Size (micro, small, medium, large, xlarge, 2xlarge...)
│ └─── Family (t, m, c, r, i, g, p, x, etc.)
└───── Generation (1, 2, 3, 3a, 4, 5, 6, 7...)

Example: m5.2xlarge
├── Family: m = General Purpose
├── Generation: 5 = AWS Generation 5
└── Size: 2xlarge = 8 vCPU + 32 GB RAM
```

### Instance Families

#### **1. General Purpose (t, m)**

```
t3.micro / t3.small (Burstable)
├── CPU: 1-2 vCPU (can burst to 3.3 GHz)
├── RAM: 1-2 GB
├── Best for: Dev/Test, low-traffic apps, learning
└── Cost: Cheapest ($0.01-0.05/hour)
    
m5.large (Steady Performance)
├── CPU: 2 vCPU sustained
├── RAM: 8 GB
├── Best for: Web servers, small databases
└── Cost: ~$0.10/hour
```

#### **2. Compute Optimized (c)**

```
c5.large
├── CPU: 2 vCPU High Performance
├── RAM: 4 GB
├── Best for: ML, batch processing, APIs, compression
└── Cost: ~$0.09/hour
```

#### **3. Memory Optimized (r)**

```
r5.large
├── CPU: 2 vCPU
├── RAM: 16 GB (ratio 1:8, unlike t3 which is 1:1)
├── Best for: In-memory databases, caches (Redis, Memcached)
└── Cost: ~$0.15/hour
```

#### **4. Storage Optimized (i)**

```
i3.large
├── CPU: 2 vCPU
├── RAM: 16 GB
├── Storage: NVMe SSD (extremely fast)
├── Best for: High I/O operations, NoSQL databases
└── Cost: ~$0.25/hour
```

#### **5. GPU Instances (g, p)**

```
g4dn.xlarge (Graphics)
├── GPU: 1x NVIDIA T4
├── CPU: 4 vCPU
├── RAM: 16 GB
├── Best for: ML inference, graphics rendering
└── Cost: ~$0.50/hour

p3.2xlarge (Compute)
├── GPU: 8x NVIDIA V100
├── CPU: 8 vCPU
├── RAM: 61 GB
├── Best for: Deep learning training
└── Cost: ~$24.48/hour
```

### Choosing an Instance Type

```
Decision Tree:

Is it a web/app server?
├── Yes → m5.large or m5.xlarge
│         (General purpose, balanced)
└── No → Continue...

Does it need high CPU?
├── Yes → c5.large or c5.xlarge
│         (Compute optimized)
└── No → Continue...

Does it need high RAM (cache, DB)?
├── Yes → r5.large or r5.xlarge
│         (Memory optimized)
└── No → Continue...

Does it need GPU (ML, graphics)?
├── Yes → g4dn.xlarge or p3.2xlarge
│         (GPU instances)
└── No → t3.micro
         (General purpose, cheapest)
```

### Performance vs Cost Trade-off

```
t3.micro (Burstable)
├── Cost: $0.01/hour (~$7/month)
├── Performance: Bursts to 3.3 GHz (limited)
└── Use: Dev, testing, learning, low traffic

t3.small
├── Cost: $0.02/hour (~$15/month)
├── Performance: Better burst capacity
└── Use: Small production apps, 1000s requests/day

m5.large
├── Cost: $0.10/hour (~$70/month)
├── Performance: Consistent 2 vCPU
└── Use: Production web servers, moderate load

m5.xlarge
├── Cost: $0.19/hour (~$140/month)
├── Performance: Consistent 4 vCPU
└── Use: Production apps, heavy load
```

**Rule of Thumb:**
- **Free Tier:** t2.micro or t3.micro
- **Learning/Dev:** t3.small to t3.medium
- **Production:** m5.large minimum
- **High Traffic:** m5.xlarge or larger

---

## EC2 Instance Lifecycle

### Complete Instance State Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    EC2 INSTANCE LIFECYCLE                    │
└──────────────────────────────────────────────────────────────┘

         ┌─────────────────────────────┐
         │  Launch Instance (Console)  │
         └──────────────┬──────────────┘
                        │
                        ↓
         ┌─────────────────────────────┐
         │    Pending (1-2 minutes)    │
         │  - OS booting               │
         │  - User data running        │
         │  - Network interfaces setup │
         └──────────────┬──────────────┘
                        │
                        ↓
    ┌────────────────────────────────────────┐
    │ RUNNING (Instance is ready to use)     │
    │                                        │
    │ From this state, you can:              │
    ├────────────────────────────────────────┤
    │ ✓ SSH into it                          │
    │ ✓ Deploy applications                  │
    │ ✓ Access via public IP/ALB             │
    │ ✓ Check logs, metrics                  │
    └────────────┬────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
    STOP (keep data)   TERMINATE (delete)
        │                 │
        ↓                 ↓
    STOPPED            TERMINATED
    (EBS kept)        (All deleted)
        │                 │
        └─────────────────┘
              ↓
         (Data gone)
```

### State Details

| State | Duration | What's Happening | Cost | What's Kept |
|-------|----------|------------------|------|------------|
| **pending** | 1-2 min | OS booting, user data running | ❌ Free | - |
| **running** | Hours+ | Instance active, ready for traffic | ✅ Paid | Volume data |
| **stopping** | 1-2 min | Graceful shutdown | ✅ Paid | Volume data |
| **stopped** | Hours+ | Instance halted, can restart | ✅ Paid (storage only) | Volume data |
| **terminating** | 1-2 min | Instance shutting down | ✅ Paid | - |
| **terminated** | - | Instance deleted | ❌ Free | Deleted |

### Lifecycle Actions

```
Action: STOP
├── Instance halts (like turning off computer)
├── OS stops, but storage persists
├── Cost: Storage charged, compute not charged
├── Can restart later with same config
└── Use when: Want to pause temporarily, save costs

Action: TERMINATE
├── Instance is completely deleted
├── EBS volume deleted (unless "Delete on termination" is off)
├── ⚠️ PERMANENT - Can't undo
├── Cost: Nothing (deleted)
└── Use when: Done with instance, won't need it again

Action: REBOOT
├── Like Ctrl+Alt+Del on Windows
├── Instance stays RUNNING
├── Brief downtime (1-2 minutes)
├── All data kept
└── Use when: Need to apply kernel updates, restart services
```

### User Data Execution Timeline

```
1. Launch button clicked (t=0s)
   ↓
2. Instance state: pending (t=5-30s)
   ├── AWS allocates compute resources
   ├── Network interfaces attached
   ├── OS kernel starts loading
   └── Root volume attached
   ↓
3. User data script starts (t=30-60s)
   ├── Runs as root user
   ├── Has full internet access
   ├── Can install software, clone repos
   ├── Output logged to: /var/log/cloud-init-output.log
   └── ⚠️ Runs ONLY on first launch!
   ↓
4. User data completes (t=1-5 minutes)
   ├── Services started (Node.js, PM2, etc.)
   └── Instance ready to serve traffic
   ↓
5. Instance state: running (t=5+ minutes)
   ├── Cloud-init service finished
   ├── SSH available
   ├── Application running
   └── Accept traffic from ALB
```

**Critical Point:** User data runs **ONLY ONCE** at first launch!
- If you stop/start: User data does NOT run again
- If you reboot: User data does NOT run
- If you terminate and relaunch: User data runs again

---

## User Data vs Metadata

### User Data (Initialization Script)

```bash
#!/bin/bash
# USER DATA: Runs ONCE at instance launch

apt update
apt install -y nodejs
npm install pm2 -g
git clone https://github.com/user/repo.git
cd repo
npm install
pm2 start app.js
```

**Characteristics:**
- ✅ Runs only on **first launch**
- ✅ Runs as **root** user
- ✅ Can take 2-5 minutes to complete
- ✅ Output logged to `/var/log/cloud-init-output.log`
- ✅ Plain text or base64 encoded
- ✅ Can install software, configure OS, deploy code

**Use Case:** Setting up a brand new instance with all software/config

### EC2 Metadata (Read Instance Information)

```bash
# From inside running instance, query metadata service

# Get instance ID
curl http://169.254.169.254/latest/meta-data/instance-id
# Output: i-0abcd1234efgh5678

# Get availability zone
curl http://169.254.169.254/latest/meta-data/placement/availability-zone
# Output: us-east-1a

# Get security group IDs
curl http://169.254.169.254/latest/meta-data/security-groups
# Output: default, web-server-sg

# Get IAM role (if attached)
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
# Output: ec2-app-role

# Get IAM credentials (temp credentials for that role)
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/ec2-app-role
# Output: {AccessKeyId, SecretAccessKey, Token, Expiration}

# Get user data (if you provided it)
curl http://169.254.169.254/latest/user-data
# Output: #!/bin/bash...
```

**Metadata is available at:** `http://169.254.169.254/latest/`

**Characteristics:**
- ✅ Available at any time (instance running)
- ✅ Read-only information about the instance
- ✅ Special IP: `169.254.169.254` (link-local address)
- ✅ No credentials needed (only works from inside instance)
- ✅ Query using `curl`, Python `requests`, AWS CLI, SDKs
- ✅ Returns JSON or plain text

**Use Cases:**
- Get IAM role credentials for AWS API calls
- Discover instance properties dynamically
- Bootstrap configuration based on instance metadata
- Health checks that verify instance properties

### Comparison Table

| Feature | User Data | Metadata |
|---------|-----------|----------|
| **When Available** | First launch only | Always (while running) |
| **Purpose** | Initialize instance | Query instance info |
| **Who Runs It** | AWS (automatic) | Your application code |
| **Execution Time** | 2-5 minutes | Instant (~1-2 ms) |
| **Can Modify Later** | No | N/A |
| **Typical Use** | Install software | Get credentials, discover config |
| **Example** | Install Node.js | Get temporary AWS credentials |

### Real-World Example

```bash
#!/bin/bash
# USER DATA: Runs at first launch

# 1. Install Node.js
apt update
apt install -y nodejs npm

# 2. Create app directory
mkdir -p /app
cd /app

# 3. Create simple Node app
cat > app.js << 'EOF'
const http = require('http');

const server = http.createServer((req, res) => {
  // METADATA: Query instance info at runtime
  const metadata = {
    instance_id: 'i-xxxxx',  // Would fetch from metadata service
    az: 'us-east-1a',         // Would fetch from metadata service
    timestamp: new Date()
  };
  
  res.writeHead(200, {'Content-Type': 'application/json'});
  res.end(JSON.stringify(metadata));
});

server.listen(3000);
console.log('Server running on port 3000');
EOF

# 4. Start app
npm install
node app.js &
```

**Key Insight:** 
- User Data = **Setup** (runs once)
- Metadata = **Runtime Info** (query anytime)

---

## Key Pairs & SSH Access

### What is a Key Pair?

A **Key Pair** is two files:

```
Public Key   (stored on AWS EC2 instance)
    ↕
Private Key  (you download, keep secret)
```

Think of it like a physical lock and key:
- AWS EC2 instance has the **lock** (public key)
- You have the **key** (private key)
- You prove you have the correct key → you can unlock SSH access

### Creating a Key Pair

**Method 1: AWS Creates It (Easy)**

1. EC2 Dashboard → Key Pairs (under Network & Security)
2. Click "Create key pair"
3. Enter name: `my-app-key`
4. Select format: `.pem` (for Mac/Linux) or `.ppk` (for PuTTY on Windows)
5. Click "Create key pair"
6. Browser downloads: `my-app-key.pem`
7. Store safely: `~/.ssh/my-app-key.pem` (on Mac/Linux)

**Method 2: You Create It (Advanced)**

```bash
# Generate your own key pair locally
ssh-keygen -t rsa -b 4096 -f ~/.ssh/my-key

# This creates:
# ~/.ssh/my-key          (private key - KEEP SECRET)
# ~/.ssh/my-key.pub      (public key - upload to AWS)

# Upload public key to AWS EC2 → Import Key Pair
# Then use private key to SSH
```

### Using Key Pair to SSH

```bash
# Make private key readable only by you
chmod 400 ~/.ssh/my-app-key.pem

# SSH into instance
ssh -i ~/.ssh/my-app-key.pem ec2-user@54.123.45.67

# For Ubuntu AMI
ssh -i ~/.ssh/my-app-key.pem ubuntu@54.123.45.67

# For Amazon Linux 2
ssh -i ~/.ssh/my-app-key.pem ec2-user@54.123.45.67
```

### SSH Connection Troubleshooting

```
Error: "Permission denied (publickey)"
├── Reason 1: Wrong key file
│   └── Solution: Verify correct key with -i flag
├── Reason 2: Permissions too open on key file
│   └── Solution: chmod 400 ~/.ssh/my-key.pem
├── Reason 3: Instance in private subnet with no IGW/NAT
│   └── Solution: Use Bastion host or VPN
└── Reason 4: Security group doesn't allow SSH (port 22)
    └── Solution: Add inbound rule: SSH from your IP

Error: "Connection timeout"
├── Reason 1: EC2 still starting (pending state)
│   └── Solution: Wait 2-3 minutes
├── Reason 2: No public IP assigned
│   └── Solution: Assign Elastic IP
└── Reason 3: Network ACL blocking inbound/outbound port 22
    └── Solution: Add NACL rules for SSH
```

---

## Spot vs On-Demand Instances

### On-Demand Instances

```
On-Demand = Pay-per-hour, no commitment

Pricing:
├── t3.micro:  $0.01/hour (~$7/month)
├── t3.small:  $0.02/hour (~$15/month)
├── m5.large:  $0.10/hour (~$72/month)
└── m5.xlarge: $0.19/hour (~$138/month)

Characteristics:
✅ Instant launch
✅ No interruption
✅ Predictable availability
✅ Full reliability
❌ Most expensive option
❌ No discount for commitment

Best For:
├── Production workloads
├── Databases
├── Load balancers
├── Critical services (can't afford downtime)
└── Application tier in 3-tier architecture
```

### Spot Instances

```
Spot = Bid for unused AWS capacity, up to 90% discount

Pricing:
├── Same t3.micro:  $0.003/hour (~$2/month) ← 70% discount!
├── Same m5.large:  $0.030/hour (~$22/month) ← 70% discount!
└── Savings: 70-90% compared to on-demand

Characteristics:
✅ Dirt cheap (70-90% discount)
✅ Instant launch
❌ Can be interrupted anytime with 2-minute warning
❌ May not launch if capacity unavailable
❌ Bid can fail if your price too low

Interruption Reasons:
├── AWS needs capacity for on-demand customers
├── You bid lower than current spot price
└── Happens ~2-3 times per month (high availability zones)

Best For:
├── Batch processing jobs
├── CI/CD pipelines
├── Machine learning training
├── Testing/staging environments
├── Scalable workloads (spin up many, lose some)
└── NOT production critical workloads
```

### Spot vs On-Demand Decision

```
Decision Matrix:

Question 1: Is this production critical?
├── Yes (database, load balancer) → ON-DEMAND
└── No (batch job, CI/CD) → SPOT

Question 2: Can you tolerate 2-minute downtime?
├── No → ON-DEMAND
└── Yes → SPOT

Question 3: Does app auto-recover on restart?
├── No (needs manual intervention) → ON-DEMAND
└── Yes (stateless, can restart) → SPOT

Question 4: Budget constraints?
├── High budget → ON-DEMAND
└── Limited budget → SPOT

Question 5: Is this temporary (hours/days)?
├── Yes → SPOT (save money)
└── No (months/years) → ON-DEMAND or RESERVED
```

### Spot Instance Architecture

```
Production Setup using Spot:

┌─────────────────────────────────────────────┐
│ Application Load Balancer (ON-DEMAND)       │
│ - Must always be available                  │
│ - Cost: ~$16/month                          │
└────────────┬────────────────────────────────┘
             │
       ┌─────┴─────┐
       ↓           ↓
  ┌─────────┐  ┌─────────┐
  │SPOT-1   │  │SPOT-2   │  ← Spot instances
  │$0.03/hr │  │$0.03/hr │  ← 70% cheaper
  │Running  │  │Running  │
  └─────────┘  └─────────┘
       │           │
       └─────┬─────┘
             ↓
  (If one interrupted, ALB still routes to other)
  (New spot instance launched automatically via auto-scaling)
```

**When One Spot Instance Interrupted:**

```
User → ALB → SPOT-1 DIES (interrupted)
       ↓       
       SPOT-2 handles traffic (still running)
       
Auto-scaling detects SPOT-1 gone:
├── Terminates dead instance
├── Launches new SPOT-3
├── Registers with ALB
└── Full capacity restored in 2-3 minutes
```

### Cost Comparison (per month)

| Setup | Cost | Availability |
|-------|------|--------------|
| 1x m5.large On-Demand | $72 | 99.99% |
| 1x m5.large Spot | $22 | 95% (interruptions) |
| 3x m5.large Spot + 1x ALB On-Demand | $82 | 99.9% (2/3 can die) |

---

## Elastic IP & Public IP

### Public IP

```
Public IP = Temporary internet IP assigned by AWS

Characteristics:
✅ Assigned automatically if "Auto-assign public IP" enabled
✅ Free to use
✅ Persists as long as instance is running
❌ Lost when instance stops/terminates
❌ Not guaranteed to be the same after stop/start

Example: 54.123.45.67

Typical Flow:
1. Launch instance in public subnet
2. Auto-assign public IP enabled
3. AWS assigns: 54.123.45.67
4. SSH into it: ssh ec2-user@54.123.45.67
5. Stop instance → IP released
6. Start instance → New IP assigned: 54.234.56.78
```

### Elastic IP (EIP)

```
Elastic IP = Permanent IP you can assign to instances

Characteristics:
✅ Stays with instance even after stop/start
✅ You can move between instances
✅ Static (never changes unless you release)
❌ Costs $0.005/hour if NOT attached to instance
✅ Free when attached to running instance

Example: 52.12.34.56

Typical Flow:
1. Allocate Elastic IP: 52.12.34.56
2. Attach to EC2 instance
3. SSH into it: ssh ec2-user@52.12.34.56
4. Stop instance → IP stays attached
5. Start instance → Same IP: 52.12.34.56
6. Terminate instance → Detach IP
7. If not attached for 2+ hours → Charges $0.005/hour
```

### When to Use Each

```
Public IP (Temporary)
├── Dev/Test environments
├── One-time servers (spin up, test, delete)
├── Instances accessed via ALB (don't need direct IP)
└── Cost: Free

Elastic IP (Permanent)
├── Production servers needing stable IP
├── Hardcoded IP in configuration
├── Database servers with IP-based auth
├── Web servers accessed directly (not via ALB)
└── Cost: $0.005/hour if unused
```

### Real-World Scenarios

```
Scenario 1: Web Server Behind ALB
├── Instance in private subnet
├── No public IP needed
├── ALB handles internet traffic
└── Decision: No IP needed ✓

Scenario 2: Production API Server (Direct Access)
├── Clients connect directly to: api.myapp.com
├── DNS resolves to: 52.12.34.56
├── If that IP changes, DNS fails
├── Decision: Elastic IP required ✓

Scenario 3: Development Machine for SSH
├── You SSH into: 54.123.45.67
├── Server rebooted tomorrow, new IP: 54.234.56.78
├── You update SSH config
├── No critical dependency on IP
└── Decision: Public IP fine ✓

Scenario 4: Database with IP-based Firewall
├── Corporate firewall allows only: 52.12.34.56
├── Database backup connects from this IP
├── If IP changes, backups fail
└── Decision: Elastic IP required ✓
```

---

## EC2 Monitoring & CloudWatch

### What to Monitor

```
CPU Utilization
├── % of compute power being used
├── Alarm if > 80% → might need scaling
└── Check: CloudWatch → EC2 → Metrics

Memory Utilization
├── ⚠️ NOT tracked by default (need CloudWatch agent)
├── Install: Amazon CloudWatch agent
└── Track RAM usage for databases/caches

Disk I/O
├── Read/write operations per second
├── Alarm if very high → slow application
└── Check: CloudWatch → EBS Metrics

Network In/Out
├── Bytes received/sent over network
├── Alarm if unusual spike → potential DDoS
└── Check: CloudWatch → EC2 Network Metrics

Status Checks
├── System Status: AWS infrastructure health
├── Instance Status: OS-level checks
├── Alarm if either fails → instance or AWS issue
└── Check: EC2 Console → Status Checks tab
```

### CloudWatch Alarms

```
Example Alarm: CPU > 80%

1. Create Alarm:
   ├── Metric: EC2 CPU Utilization
   ├── Instance: web-server-1
   ├── Threshold: > 80%
   ├── Duration: For 5 minutes
   └── Action: Send SNS notification

2. Evaluation:
   t=00m: CPU = 60% (OK)
   t=01m: CPU = 75% (OK)
   t=02m: CPU = 85% (Above threshold)
   t=03m: CPU = 88% (Still above)
   t=04m: CPU = 85% (Still above)
   t=05m: CPU = 92% (Still above for 5 min)
   
   → TRIGGER ALARM → Send notification

3. When Threshold Drops:
   t=06m: CPU = 75% (Below threshold)
   t=10m: CPU = 60%
   
   → RECOVER ALARM → Send "OK" notification
```

### Custom Metrics (Application Level)

```bash
#!/bin/bash
# Monitor custom metrics from your application

# Example: Track requests per second in your app
requests=$(curl http://localhost:3000/stats | grep requests)

# Send to CloudWatch
aws cloudwatch put-metric-data \
  --metric-name "RequestsPerSecond" \
  --namespace "MyApp" \
  --value $requests \
  --unit Count
```

---

## Security Best Practices

### 1. Principle of Least Privilege

```
❌ Bad: Security group allows all traffic
Inbound Rules:
├── 0.0.0.0/0 All protocols All ports

✅ Good: Security group allows only what's needed
Inbound Rules:
├── 0.0.0.0/0 Port 80 (HTTP) - from anywhere
├── 0.0.0.0/0 Port 443 (HTTPS) - from anywhere
└── 10.0.0.0/8 Port 22 (SSH) - from internal only
```

### 2. Restrict SSH Access

```
❌ Bad: SSH from anywhere (0.0.0.0/0)
├── Anyone on internet can attempt SSH
├── Brute force attacks common
└── Compromised if weak password

✅ Good: SSH from specific IPs
├── Port 22 from: 203.0.113.45/32 (your IP only)
└── Use bastion host for other developers

✅ Best: SSH via Bastion Host
├── Only bastion on port 22 inbound (your IP)
├── Private EC2 accessible via bastion only
├── Audit trail of all SSH access
└── Single point of control
```

### 3. Use IAM Roles Instead of Access Keys

```
❌ Bad: Hardcoded AWS credentials in code
# app.js
const AWS = require('aws-sdk');
AWS.config.update({
  accessKeyId: 'AKIAIOSFODNN7EXAMPLE',     // ⚠️ Visible in code
  secretAccessKey: 'wJalrXUtnFEMI/K7MD'    // ⚠️ Visible in code
});

✅ Good: IAM Role on EC2 instance
# No credentials in code needed
# AWS SDK automatically finds credentials from metadata service

const AWS = require('aws-sdk');
const s3 = new AWS.S3();  // ← Uses instance role credentials
s3.listBuckets().promise();
```

### 4. Keep AMI Updated

```
❌ Old approach:
1. Create custom AMI with software
2. Use for 2 years
3. Accumulates 100+ unpatched security vulnerabilities

✅ Good approach:
1. Create custom AMI
2. Every 3-6 months:
   ├── Rebuild AMI with latest base OS version
   ├── Install latest security patches
   ├── Update all dependencies
   └── Delete old AMI
3. Always use latest version when launching
```

### 5. Enable Detailed Monitoring

```bash
# At launch or via CLI:
aws ec2 monitor-instances --instance-ids i-0abcd1234efgh5678

# Enables:
├── 1-minute CloudWatch metrics (vs default 5-minute)
├── Better visibility for performance issues
└── Slight extra cost (~$3.50/month per instance)
```

### 6. Use Security Groups as Virtual Firewall

```
Every layer should have its own SG:

┌──────────────────────────────┐
│ ALB Security Group            │
│ ├── Inbound: 0.0.0.0/0:80     │
│ └── Outbound: web-sg:80       │  ← Restricts to web servers
└──────────────────────────────┘
        │
        ↓
┌──────────────────────────────┐
│ Web Server Security Group     │
│ ├── Inbound: alb-sg:80        │  ← Only from ALB
│ ├── Outbound: db-sg:5432      │  ← Only to database
│ └── Outbound: 0.0.0.0/0:443   │  ← Can reach internet for updates
└──────────────────────────────┘
        │
        ↓
┌──────────────────────────────┐
│ Database Security Group       │
│ └── Inbound: web-sg:5432      │  ← Only from web servers
└──────────────────────────────┘
```

---

## Summary: EC2 Concepts at a Glance

```
EC2 = Virtual Server in AWS Cloud

AMI = Blueprint/Template with OS + Software
├── AWS-provided (Amazon Linux, Ubuntu, RHEL, Windows)
├── Community (use with caution)
├── Marketplace (pre-configured software)
└── Custom (create from your own instance)

Instance Type = Size and power level
├── t3.micro (burstable, free tier)
├── m5.large (general purpose)
├── c5.large (compute optimized)
└── r5.large (memory optimized)

Lifecycle:
pending → running → (stop/start loop) → terminated

User Data = Setup script at first launch (runs once)
Metadata = Query instance info at runtime (anytime)

Key Pair = SSH authentication (public key + private key)

Public IP = Temporary, free, lost on stop
Elastic IP = Permanent, costs if unused

Spot vs On-Demand:
├── Spot: 70% cheaper, can be interrupted
└── On-Demand: Reliable, normal price

Monitoring:
├── CPU, Memory, Disk I/O, Network
├── CloudWatch for metrics and alarms
└── Custom metrics from your app

Security:
├── Least privilege (open only needed ports)
├── SSH from specific IPs only
├── Use IAM roles instead of access keys
├── Update AMIs regularly
└── Separate security groups per tier
```

---

## Next Steps: Hands-On Tasks

1. ✅ Launch Ubuntu 20 EC2 instance with public IP
2. ✅ Use User Data to auto-install Node.js
3. ✅ Clone GitHub repo with sample Node app
4. ✅ Run app with PM2 for persistence
5. ✅ Test app in browser
6. ✅ Check CloudWatch metrics
7. ✅ SSH into instance and inspect logs
8. ✅ Create Elastic IP and reassign
9. ✅ Create custom AMI from instance
10. ✅ Launch new instance from custom AMI

See: `step-by-step-launch-guide.md` for detailed tasks.
