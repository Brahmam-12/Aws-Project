# DAY 3 - EC2 ARCHITECTURE DIAGRAMS 📊

## Visual Representations of EC2 Concepts

---

## 1. EC2 INSTANCE LIFECYCLE

```
┌─────────────────────────────────────────────────────────┐
│             EC2 INSTANCE LIFECYCLE STATES                │
└─────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │   PENDING    │  (1-2 minutes)
                    │   (Booting)  │
                    └───────┬──────┘
                            │
          AWS ALLOCATING RESOURCES
          ├── Assign vCPU
          ├── Attach EBS volumes
          ├── Assign network interfaces
          ├── Load OS kernel
          └── User Data running
                            │
                            ↓
                    ┌──────────────┐
                    │   RUNNING    │  (hours/days)
                    │  (Ready!)    │
                    └───────┬──────┘
                            │
                ┌───────────┴───────────┐
                │                       │
            STOP (Pause)          TERMINATE (Delete)
                │                       │
                ↓                       ↓
            ┌──────────┐           ┌────────────┐
            │ STOPPED  │           │ TERMINATE  │
            │ (Halted) │           │  (Deleting)│
            └─────┬────┘           └──────┬─────┘
                  │                       │
                  │                       ↓
                  │              ┌──────────────┐
                  │              │ TERMINATED   │
                  │              │  (Deleted)   │
                  │              └──────────────┘
                  │
                  │ START (Resume)
                  │
                  ↓
            ┌──────────────┐
            │   PENDING    │  (2-3 minutes)
            │  (Restarting)│
            └───────┬──────┘
                    │
                    ↓
            ┌──────────────┐
            │   RUNNING    │  (Ready again)
            └──────────────┘

═══════════════════════════════════════════════════════════

STATE DETAILS:

pending (1-2 min)
├── OS kernel loading
├── Network setup
├── Disks attaching
├── ✅ User Data running
├── ❌ SSH NOT available yet
└── 💰 NOT charging yet

running (hours+)
├── ✅ OS booted
├── ✅ SSH available
├── ✅ Application ready
├── 💰 CHARGING per hour
└── ⚙️ Can SSH, deploy, test

stopping (1-2 min)
├── Graceful OS shutdown
├── Services stopping
├── Data flushing to disk
├── Instance halting
└── 💰 CHARGING until stopped

stopped (indefinite)
├── ✅ OS halted
├── ✅ All data preserved
├── ❌ Not running any workload
├── 💰 CHARGING storage only (~$0.01/hour)
└── ✅ Can be restarted

terminating (1-2 min)
├── OS shutting down
├── EBS volumes detaching
├── Data being deleted
└── 💰 Still charging

terminated (deleted)
├── ❌ Instance gone
├── ❌ Data deleted
├── ❌ Can't restart
├── ❌ Public/Elastic IP released
└── 💰 FREE (no charges)

═══════════════════════════════════════════════════════════

COST COMPARISON (Monthly):

Continuous Running (30 days × 24 hours):
├── t3.micro: 720 hours × $0.01/hour = $7.20

Stopped Nights (16 hours/day running):
├── t3.micro: 480 hours × $0.01 + 240 hours × $0 = $4.80
└── Savings: $2.40/month (33% cheaper)

Stopped Weekends (5 days working):
├── t3.micro: 120 hours × $0.01 = $1.20
└── Savings: $6/month (83% cheaper)

Setup: EventBridge + Lambda = Free! ✅
```

---

## 2. USER DATA EXECUTION TIMELINE

```
┌───────────────────────────────────────────────────────────┐
│      USER DATA EXECUTION (First Launch Only)               │
└───────────────────────────────────────────────────────────┘

Time    Event                    User Data Status
────────────────────────────────────────────────────────────
t=0s    Launch clicked           ❌ Not started
        Instance ID: i-xxxxx
        
t=5s    AWS allocates resources  ❌ Not started
        vCPU assigned
        Memory initialized
        
t=30s   OS kernel loading        ⏳ Starting...
        Network interfaces ready
        Root filesystem mounted
        
t=60s   User Data script begins  ⏳ Running
        ├── Updates package list
        ├── Installing NodeJS
        ├── Installing PM2
        └── Running 2-5 minutes

t=180s  User Data almost done    ⏳ Nearly done
        ├── npm install complete
        ├── Application starting
        ├── PM2 registering app
        └── Services binding ports

t=240s  User Data complete       ✅ SUCCESS!
        ├── Cloud-init finished
        ├── App listening on 3000
        ├── PM2 shows status
        └── ready for traffic

t=300s  OS fully booted          ✅ READY
        ├── SSH now available
        ├── CloudWatch reporting
        ├── Application responding
        └── Browser can access

═══════════════════════════════════════════════════════════

IMPORTANT: User Data runs ONLY on FIRST launch!

REBOOT (Ctrl+Alt+Del):
├── User Data: ❌ Does NOT run
├── Services: Restarted by OS
├── Time: 1-2 minutes
└── Result: Application still running

STOP → START:
├── User Data: ❌ Does NOT run
├── Data: ✅ Preserved
├── Time: 2-3 minutes to boot
└── Result: Application stopped (must restart manually)

TERMINATE then RELAUNCH:
├── User Data: ✅ DOES run again!
├── Data: ❌ Lost from stopped instance
├── Time: 3-5 minutes total
└── Result: Fresh instance with new setup

═══════════════════════════════════════════════════════════

USER DATA LOG FILE:

/var/log/cloud-init-output.log

To debug:
├── SSH into instance
├── tail -f /var/log/cloud-init-output.log
├── Look for: ERROR, FAILED, not found
├── Check: Last lines show completion
└── Verify app running: ps aux | grep node
```

---

## 3. METADATA SERVICE ARCHITECTURE

```
┌──────────────────────────────────────────────────────────────┐
│        EC2 METADATA SERVICE (From Inside Instance)            │
└──────────────────────────────────────────────────────────────┘

Application Code
    │
    │ curl http://169.254.169.254/latest/meta-data/instance-id
    │
    ↓
┌─────────────────────────────────┐
│ Local Link (Link-Local Address) │
│ 169.254.169.254:80              │
│                                 │
│ AWS Metadata Service            │
│ (Only works from instance)      │
│ (No internet needed)            │
│ (No credentials needed)         │
└────────────────┬────────────────┘
                 │
        Returns (JSON or text):
        ├── i-0abcd1234efgh5678 ← Instance ID
        ├── us-east-1a ← Availability Zone
        ├── t3.micro ← Instance Type
        ├── 10.0.1.42 ← Private IP
        ├── 54.123.45.67 ← Public IP (if assigned)
        └── web-server-sg ← Security Groups

═══════════════════════════════════════════════════════════

METADATA HIERARCHY (Available at each path):

/latest/meta-data/
├── instance-id                  ← i-0abcd1234efgh5678
├── instance-type                ← t3.micro
├── ami-id                        ← ami-0c55b159...
├── availability-zone            ← us-east-1a
├── public-ipv4                   ← 54.123.45.67
├── local-ipv4                    ← 10.0.1.42
├── mac                           ← 02:d5:dd:a0:3f:41
├── security-groups              ← web-server-sg
├── network/
│   ├── interfaces/macs/02:d5.../
│   │   └── subnet-id            ← subnet-0abcd1234
│   └── interfaces/macs/02:d5.../
│       └── security-group-ids   ← sg-0abcd1234
├── iam/
│   ├── security-credentials/    ← ec2-app-role
│   │   └── ec2-app-role/        ← Credentials JSON
│   │       ├── AccessKeyId
│   │       ├── SecretAccessKey
│   │       ├── Token
│   │       └── Expiration
│   └── info                      ← IAM info
├── placement/
│   ├── availability-zone        ← us-east-1a
│   └── region                   ← us-east-1
├── hostname                      ← ip-10-0-1-42.ec2.internal
├── public-keys/0/
│   └── openssh-key              ← Your SSH key
└── user-data                     ← Your User Data script

═══════════════════════════════════════════════════════════

COMMON METADATA QUERIES:

# Get IAM credentials (for AWS SDK)
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/ec2-app-role
{
  "Code" : "Success",
  "LastUpdated" : "2024-01-28T10:05:03Z",
  "Type" : "AWS-HMAC",
  "AccessKeyId" : "ASIA...",
  "SecretAccessKey" : "...",
  "Token" : "...",
  "Expiration" : "2024-01-28T16:30:00Z"
}

# Check if EC2 Instance Connect (EC2 Instance Connect)
curl http://169.254.169.254/latest/meta-data/ec2-instance-connect

# Metrics (custom endpoint)
curl http://169.254.169.254/latest/dynamic/instance-identity/document
{
  "accountId" : "123456789012",
  "architecture" : "x86_64",
  "availabilityZone" : "us-east-1a",
  "instanceId" : "i-0abcd1234efgh5678",
  "instanceType" : "t3.micro",
  "region" : "us-east-1"
}

═══════════════════════════════════════════════════════════

REAL-WORLD USAGE (Application):

# Node.js
const http = require('http');
http.get('http://169.254.169.254/latest/meta-data/iam/security-credentials/ec2-app-role', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const creds = JSON.parse(data);
    console.log('AccessKeyId:', creds.AccessKeyId);
  });
});

# Python
import urllib.request
import json
url = 'http://169.254.169.254/latest/meta-data/iam/security-credentials/ec2-app-role'
creds = json.loads(urllib.request.urlopen(url).read())
print(creds['AccessKeyId'])

# Bash (simple)
curl -s http://169.254.169.254/latest/meta-data/instance-id
```

---

## 4. SECURITY GROUP FLOW (STATEFUL)

```
┌────────────────────────────────────────────────────────────┐
│       SECURITY GROUP FLOW (Stateful Firewall)               │
└────────────────────────────────────────────────────────────┘

INBOUND REQUEST:

Browser                      EC2 Instance
54.123.45.67:52000           10.0.1.42:80
      │
      │ HTTP request (SYN)
      │─────→ Port 80
              │
              ↓
         ┌─────────────────┐
         │  EC2 Instance   │
         │  ┌─────────────┐│
         │  │   ALB SG    ││ Inbound Rules:
         │  │             ││ ├─ Port 80: ✅ ALLOW
         │  │             ││ └─ Port 443: ✅ ALLOW
         │  └─────────────┘│
         │                 │
         │  ┌─────────────┐│
         │  │  App (SG)   ││ Inbound Rules:
         │  │             ││ ├─ Port 3000 from ALB: ✅ ALLOW
         │  │  Port 3000  ││ └─ Other: ❌ DENY
         │  └─────────────┘│
         └─────────────────┘
              │
              ↓
         Connection ESTABLISHED
         State: ESTABLISHED

═══════════════════════════════════════════════════════════

OUTBOUND RESPONSE:

EC2 Instance                Browser
10.0.1.42:52000             54.123.45.67:52000
      │
      │ HTTP response (ACK)
      │─────→
              │
              ↓
         ┌─────────────────┐
         │  App SG         │ Outbound Rules:
         │                 │ ├─ All traffic: ✅ ALLOW
         │  Response OK    │
         └─────────────────┘
              │
              ↓
         Response reaches browser
         Connection CLOSED

═══════════════════════════════════════════════════════════

STATEFUL BEHAVIOR (Key Difference):

Request 1 (Browser → ALB):
├── SG checks: INBOUND rules
├── Port 80 allowed? YES ✅
├── Connection ESTABLISHED
└── State remembered: Connection #1234

Response 1 (ALB → Browser):
├── SG checks: Outbound rules
├── But WAIT - Connection #1234 is ESTABLISHED
├── SG auto-allows response ✅ (even without explicit outbound rule!)
├── Response sent

Request 2 (Random IP → Port 1234):
├── SG checks: INBOUND rules
├── Port 1234 in rules? NO ❌
├── No established state for this port
├── Request DENIED ❌
└── SG silently drops packet

═══════════════════════════════════════════════════════════

REAL SCENARIO - 3-Tier Application:

User Request Flow:

1. Browser → ALB (Public IP)
   ├── SG check: INBOUND port 80/443
   ├── Result: ALLOW ✅
   └── ALB notes: Connection state

2. ALB → Web Server (Private IP 10.0.1.42)
   ├── Web-Server SG check: INBOUND port 3000 from ALB-SG
   ├── Result: ALLOW ✅ (sg-alb is referenced!)
   └── Connection ESTABLISHED

3. Web Server → Database (Private IP 10.0.2.50)
   ├── DB-Server SG check: INBOUND port 5432 from Web-SG
   ├── Result: ALLOW ✅ (sg-web-server is referenced!)
   └── SQL query sent

4. Database → Web Server
   ├── Web-Server SG check: OUTBOUND (default allow all)
   ├── Result: ALLOW ✅ (stateful, remember step 3)
   └── Query result sent

5. Web Server → ALB
   ├── ALB SG check: OUTBOUND (default allow all)
   ├── Result: ALLOW ✅ (stateful, remember step 2)
   └── Response data sent

6. ALB → Browser
   ├── Browser SG check: (browser has no SG)
   ├── NACL check: Ephemeral ports allowed
   ├── Result: ALLOW ✅
   └── Page loaded!

═══════════════════════════════════════════════════════════

SECURITY GROUP RULE FORMAT:

Inbound Rule:
├── Protocol: TCP
├── Port Range: 80 to 80
├── Source:
│   ├── Option 1: IP address (e.g., 203.0.113.45/32)
│   ├── Option 2: CIDR block (e.g., 10.0.0.0/16)
│   ├── Option 3: Security Group ID (e.g., sg-0abcd1234)
│   │            ← Allows instances in that SG
│   └── Option 4: 0.0.0.0/0 (anywhere, insecure)
└── Description: (optional, for documentation)

Example Rules for ALB:
├── Rule 1: Inbound TCP 80 from 0.0.0.0/0
├── Rule 2: Inbound TCP 443 from 0.0.0.0/0
└── Rule 3: Outbound TCP 3000 to sg-web-servers
             (ALB can send to web servers)

Example Rules for Web Server:
├── Rule 1: Inbound TCP 3000 from sg-alb-sg
           (Only ALB can send requests)
├── Rule 2: Inbound TCP 22 from 10.0.0.0/16
           (SSH from bastion/private network)
└── Rule 3: Outbound TCP 5432 to sg-database-sg
           (Can query database)
```

---

## 5. EC2 SCALING ARCHITECTURE

```
┌────────────────────────────────────────────────────────────┐
│          EC2 AUTO-SCALING GROUP (ASG) ARCHITECTURE          │
└────────────────────────────────────────────────────────────┘

NORMAL DAY (Morning 8 AM):

Traffic Spike! 📈
    │
    ↓
┌────────────────────────────────────────┐
│ Application Load Balancer              │
│ Distributing requests                  │
└─────────────────────┬──────────────────┘
                      │
          ┌───────────┼───────────┐
          ↓           ↓           ↓
    ┌─────────┐ ┌─────────┐ ┌─────────┐
    │Instance │ │Instance │ │Instance │
    │    1    │ │    2    │ │    3    │
    │Port 3000│ │Port 3000│ │Port 3000│
    │CPU: 85% │ │CPU: 82% │ │CPU: 88% │
    └─────────┘ └─────────┘ └─────────┘
        │           │           │
        └─────┬─────┴─────┬─────┘
              │           │
              ↓           ↓
      Instance avg CPU > 80% ❌
        For 2+ minutes
              │
              ↓
    ┌─────────────────────────────┐
    │ Auto-Scaling Group Triggered │
    │ SCALE UP Event              │
    └──────────────┬──────────────┘
                   │
                   ↓
        Launch 2 new instances:
        ├── Instance 4 (t3.small)
        ├── Instance 5 (t3.small)
        ├── User Data running (3 min)
        └── Added to ALB target group
                   │
         After 3-5 minutes:
                   ↓
          ┌───────────────────────────┐
          │ New Instances Ready       │
          └────────┬──────────────────┘
                   │
          ┌─────────┼─────────┬─────────┐
          ↓         ↓         ↓         ↓
      ┌────────┐┌────────┐┌────────┐┌────────┐
      │Instance││Instance││Instance││Instance│
      │  1     ││  2     ││  3     ││  4     │
      │CPU:45% ││CPU:42% ││CPU:48% ││CPU:40% │
      └────────┘└────────┘└────────┘└────────┘
         +              +              +
      ┌────────┐
      │Instance│
      │  5     │
      │CPU:38% │
      └────────┘

    Capacity doubled! ✅
    CPUs normalized
    All instances healthy
    Response time improved


EVENING LULL (5 PM):

Traffic Drops 📉
    │
    ↓
┌────────────────────────────────────────┐
│ Application Load Balancer              │
│ Fewer requests                         │
└─────────────────────┬──────────────────┘
                      │
          ┌───────────┼───────────┐
          ↓           ↓           ↓
    ┌─────────┐ ┌─────────┐ ┌─────────┐
    │Instance │ │Instance │ │Instance │
    │    1    │ │    2    │ │    3    │
    │CPU: 15% │ │CPU: 12% │ │CPU: 18% │
    └─────────┘ └─────────┘ └─────────┘
                  +
            ┌──────────┐
            │Instance 4│
            │CPU: 14%  │
            └──────────┘
                  +
            ┌──────────┐
            │Instance 5│
            │CPU: 16%  │
            └──────────┘

    Instance avg CPU < 30% ✅
        For 10+ minutes
              │
              ↓
    ┌─────────────────────────────┐
    │ Auto-Scaling Group Triggered │
    │ SCALE DOWN Event            │
    └──────────────┬──────────────┘
                   │
                   ↓
        Gracefully drain instances:
        ├── Instance 5: No new connections
        ├── Wait for existing requests (30 sec)
        ├── Terminate Instance 5
        ├── Instance 4: Same process
        └── Remove from target group
                   │
         After 1-2 minutes:
                   ↓
          ┌───────────────────────────┐
          │ Back to 3 Instances       │
          │ Minimum capacity          │
          └────────┬──────────────────┘
                   │
          ┌─────────┼─────────┐
          ↓         ↓         ↓
      ┌────────┐┌────────┐┌────────┐
      │Instance││Instance││Instance│
      │  1     ││  2     ││  3     │
      │CPU:25% ││CPU:22% ││CPU:28% │
      └────────┘└────────┘└────────┘

    Cost reduced! 💰
    Only paying for needed capacity
    Ready for next spike


═══════════════════════════════════════════════════════════

AUTO-SCALING GROUP CONFIGURATION:

Min Capacity:     2 instances (always running)
Desired Capacity: 4 instances (optimal baseline)
Max Capacity:    10 instances (peak limit)

Scaling Policies:

Policy 1: Scale UP
├── Metric: Average CPU > 70%
├── Duration: 2 minutes
├── Action: Add 2 instances
└── Cooldown: Wait 5 minutes before next scale

Policy 2: Scale DOWN
├── Metric: Average CPU < 30%
├── Duration: 10 minutes
├── Action: Remove 1 instance
└── Cooldown: Wait 10 minutes before next scale

═══════════════════════════════════════════════════════════

BENEFITS:

✅ High Availability
   ├── Min 2 instances
   ├── If one fails: Others handle traffic
   ├── ALB health checks detect failures
   └── Auto-launches replacement

✅ Cost Optimization
   ├── Only scale when needed
   ├── Scale down automatically
   ├── Save 40-60% vs fixed capacity
   └── Never pay for idle capacity

✅ Performance
   ├── Response time stays consistent
   ├── No throttling during spikes
   ├── Auto-adapt to demand
   └── Zero-downtime deployments

✅ Reliability
   ├── Automatic failover
   ├── Health checks every 30 seconds
   ├── Self-healing (replace bad instances)
   └── 99.9% uptime achievable
```

---

## 6. EC2 WITH RDS COMMUNICATION

```
┌────────────────────────────────────────────────────────────┐
│        EC2 TO RDS DATABASE CONNECTION FLOW                  │
└────────────────────────────────────────────────────────────┘

Application Architecture:

User
 │
 ├─→ Browser (Angular/React)
 │     │
 │     └─→ API Endpoint
 │          │
 │          ├─→ ALB (Port 80/443)
 │          │    └─→ EC2 Instance (Port 3000)
 │          │         └─→ RDS (Port 5432)
 │          │              └─→ PostgreSQL
 │          │
 │          └─→ S3 Bucket (Static assets, images)
 │
 └─→ Static Content
      └─→ CloudFront / S3


DETAILED FLOW:

1️⃣ Browser Request
   User: http://myapp.com/api/users
   │
   ├── Browser: DNS lookup for myapp.com
   ├── Route53: Returns ALB IP
   └── Browser: HTTP GET /api/users

2️⃣ Load Balancer Processing
   ALB (10.0.1.10:80)
   │
   ├── Receives request on port 80
   ├── Security Group ALB-SG checks:
   │   └── Port 80 from 0.0.0.0/0? ✅ YES
   ├── Selects target instance:
   │   └── Instance-1 (10.0.1.42)
   └── Forwards to 10.0.1.42:3000

3️⃣ Application Instance Processing
   EC2 Instance (10.0.1.42:3000)
   │
   ├── Receives request on port 3000
   ├── Security Group Web-SG checks:
   │   └── Port 3000 from ALB-SG? ✅ YES
   ├── Node.js route handler processes
   ├── Needs to query database
   └── Makes DB connection request

4️⃣ Network Routing to RDS
   EC2 → RDS Connection
   │
   ├── EC2 looks up RDS endpoint:
   │   └── rds-primary.c9akciq32.us-east-1.rds.amazonaws.com
   ├── DNS resolves to: 10.0.2.50 (RDS Private IP)
   ├── EC2 creates TCP connection:
   │   └── Source: 10.0.1.42:52000 (random port)
   │   └── Dest: 10.0.2.50:5432 (PostgreSQL port)
   └── Packet routed through VPC

5️⃣ Security Group Checks (RDS)
   Database SG checks inbound:
   │
   ├── Protocol: TCP
   ├── Port: 5432 (PostgreSQL)
   ├── Source: Web-SG (10.0.1.42)
   ├── Rule: "Allow port 5432 from Web-SG"
   ├── Evaluation: ✅ YES, allowed
   └── Connection established

6️⃣ Database Query Execution
   RDS PostgreSQL receives:
   │
   ├── Query: SELECT * FROM users WHERE id = 1
   ├── Executes on primary instance
   ├── Returns results
   └── Sends response to EC2

7️⃣ Response Path (Reverse)
   RDS → EC2 → ALB → Browser
   │
   ├── RDS sends data: 10.0.2.50 → 10.0.1.42:52000
   ├── EC2 Security Group: ✅ Stateful, allows response
   ├── EC2 formats JSON response
   ├── Sends to ALB: 10.0.1.42:3000 → 10.0.1.10:80
   ├── ALB forwards to browser
   └── Browser receives and renders

═══════════════════════════════════════════════════════════

CONNECTION STRING FORMAT:

Node.js (sequelize/typeorm):
───────────────────────────
{
  host: 'rds-primary.c9akciq32.us-east-1.rds.amazonaws.com',
  port: 5432,
  username: 'postgres',
  password: process.env.DB_PASSWORD,
  database: 'myapp_db'
}

Connection string:
postgresql://postgres:password@rds-primary.c9akciq32.us-east-1.rds.amazonaws.com:5432/myapp_db

Python (psycopg2):
──────────────────
import psycopg2
conn = psycopg2.connect(
  host='rds-primary.c9akciq32.us-east-1.rds.amazonaws.com',
  port=5432,
  user='postgres',
  password=os.environ['DB_PASSWORD'],
  database='myapp_db'
)

Java (JDBC):
────────────
String url = "jdbc:postgresql://rds-primary.c9akciq32.us-east-1.rds.amazonaws.com:5432/myapp_db";
Properties props = new Properties();
props.setProperty("user", "postgres");
props.setProperty("password", System.getenv("DB_PASSWORD"));
Connection conn = DriverManager.getConnection(url, props);

═══════════════════════════════════════════════════════════

SECURITY GROUPS CONFIGURATION:

ALB Security Group (alb-sg):
┌──────────────────────────────┐
│ Inbound:                     │
│ • TCP 80 from 0.0.0.0/0      │
│ • TCP 443 from 0.0.0.0/0     │
│                              │
│ Outbound:                    │
│ • TCP 3000 to Web-SG         │
└──────────────────────────────┘

Web Server SG (web-sg):
┌──────────────────────────────┐
│ Inbound:                     │
│ • TCP 3000 from ALB-SG       │
│ • TCP 22 from Bastion-SG     │
│                              │
│ Outbound:                    │
│ • TCP 5432 to Database-SG    │
│ • TCP 443 to 0.0.0.0/0       │
│   (for npm packages, APIs)   │
└──────────────────────────────┘

Database SG (db-sg):
┌──────────────────────────────┐
│ Inbound:                     │
│ • TCP 5432 from Web-SG       │
│ • TCP 5432 from Backup-SG    │
│                              │
│ Outbound:                    │
│ • (Usually deny all)         │
│   (Passive only)             │
└──────────────────────────────┘

═══════════════════════════════════════════════════════════

COMMON ISSUES & FIXES:

Issue: "Connection timeout" to RDS
└─ Cause 1: RDS security group doesn't allow port 5432
   └─ Fix: Add inbound rule for port 5432 from Web-SG
└─ Cause 2: RDS not in same VPC
   └─ Fix: RDS must be in private subnet of VPC
└─ Cause 3: NACL blocks ephemeral ports
   └─ Fix: Inbound 1024-65535 for response

Issue: "Connection refused" immediately
└─ Cause: RDS not running or deleted
   └─ Fix: Check RDS console, restore from backup

Issue: "Too many connections" error
└─ Cause: Connection pool exhausted
   └─ Fix: Increase max connections, use read replicas

Issue: Long latency
└─ Cause 1: Network hops (instance in different AZ)
   └─ Fix: Place EC2 and RDS in same AZ
└─ Cause 2: Slow queries
   └─ Fix: Add database indexes, analyze query plans
```

All diagrams ASCII-formatted for clarity and easy reference during interviews! 📚
