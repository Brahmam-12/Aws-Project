# IP RESOLUTION & DNS STRATEGY FOR 3-TIER APPLICATIONS 🌐

## Why Hardcoding IPs is Dangerous & How Route53 Solves It

---

## TABLE OF CONTENTS

1. [The Problem: Hardcoded IPs](#the-problem-hardcoded-ips)
2. [DNS Solution: Route53 & Private Zones](#dns-solution-route53)
3. [Complete DNS Architecture](#complete-dns-architecture)
4. [RDS Endpoint Discovery](#rds-endpoint-discovery)
5. [Service Discovery Patterns](#service-discovery-patterns)
6. [Multi-Region Strategy](#multi-region-strategy)
7. [Troubleshooting DNS Issues](#troubleshooting-dns-issues)

---

## THE PROBLEM: HARDCODED IPs

### Scenario 1: RDS Instance Restart

**Architecture:**
```
EC2 Instance (Private IP: 10.0.2.45)
    ↓ (Hardcoded connection string)
    ↓ "postgresql://postgres@10.0.5.42:5432/appdb"
    ↓
RDS Instance (Private IP: 10.0.5.42)
```

**What Happens:**
```
Day 1 (Monday, 10:00 AM):
├─ RDS instance: 10.0.5.42
├─ Application connects fine
└─ ✓ Everything works

Day 2 (Tuesday, 2:00 AM - Maintenance window):
├─ AWS RDS automatic patch applied
├─ RDS restarts
├─ RDS gets NEW private IP: 10.0.5.99 (old one released)
└─ ✗ Application code still uses 10.0.5.42

Result:
├─ "Connection refused" errors
├─ All traffic fails for 10-30 minutes
├─ Customer support gets flooded
├─ Incident declared, on-call engineer woken up
└─ Manual fix required (redeploy with new IP)
```

**Why This Happens:**
- RDS doesn't preserve private IPs across restarts
- Multi-AZ failover uses different servers
- Read replicas have different IPs
- Scaling operations require new server IPs

---

### Scenario 2: Multi-AZ Failover

**Architecture with Hardcoded IPs:**
```
Primary RDS (10.0.5.42)
    ↓
    ✗ Failure (network partition)
    ↓
Standby RDS (10.0.5.89) ← Different IP!
    ↓
But application code still has: 10.0.5.42
    ↓
Result: Connection fails, standby never used
```

---

### Scenario 3: ALB IP Changes

**Problem:**
```
EC2 Instance 1 (Private IP: 10.0.2.45)
    ↓ (Hardcoded)
    ↓ "http://10.1.1.50:80"  ← ALB IP
    ↓
ALB (Public IP: 10.1.1.50)  ← Elastic, but can change!

If ALB public IP is released/reassigned:
├─ New ALB IP: 10.1.1.99
├─ Old connections: "10.1.1.50" (dead)
└─ Application fails
```

---

## DNS SOLUTION: ROUTE53

### What is Route53?

```
Route53 = AWS's DNS Service
├─ Converts domain names to IP addresses
├─ Stores "phone book" of IP mappings
├─ Returns latest IP address for any service
└─ Automatically updates when IPs change
```

### The Right Way: DNS Names Instead of IPs

**BEFORE (Hardcoded IPs - ✗ Bad):**
```
Application Code:
  const pool = new Pool({
    host: '10.0.5.42',  // Hardcoded IP
    port: 5432,
    database: 'appdb'
  });

Problem:
  If IP changes → Connection fails
  If infrastructure rebuilt → Manual update required
  If RDS restarted → Disaster
```

**AFTER (DNS Names - ✓ Good):**
```
Application Code:
  const pool = new Pool({
    host: 'mydb.c123xyz.us-east-1.rds.amazonaws.com',
    port: 5432,
    database: 'appdb'
  });

Benefits:
  ✓ IP can change anytime
  ✓ DNS automatically resolves to current IP
  ✓ Multi-AZ failover works transparently
  ✓ Zero application code changes needed
```

---

## COMPLETE DNS ARCHITECTURE

### Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                │
│                      User Browser                               │
│                                                                 │
│  User types: https://myapp.com                                 │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
                    DNS Query
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│                    ROUTE53 (AWS DNS)                            │
│                                                                 │
│  Domain Records:                                               │
│  ├─ myapp.com → CloudFront                                    │
│  ├─ api.myapp.com → ALB                                       │
│  └─ internal.myapp.com → Internal services (private zone)    │
│                                                                 │
│  Returns: 12.34.56.78 (ALB IP) or d1234.cloudfront.net      │
└────────────────────────┬────────────────────────────────────────┘
                         ↓
                  Browser connects
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│                  ALB / CloudFront                               │
│                  (IP: 12.34.56.78)                              │
└─────────────────────────────────────────────────────────────────┘
```

### Route53 Record Types

#### 1. **A Record (Public DNS)**

```
Record Type: A
Name: myapp.com
Value: 12.34.56.78 (ALB public IP)
TTL: 300 seconds (5 minutes)

What happens:
├─ Browser asks: "What is myapp.com?"
├─ Route53 responds: "12.34.56.78"
├─ Browser caches for 300 seconds
└─ Browser connects to 12.34.56.78
```

**Use Cases:**
- Public API domain
- Website domain
- CDN aliases

---

#### 2. **CNAME Record (Alias)**

```
Record Type: CNAME
Name: api.myapp.com
Value: myapp-alb-1234.us-east-1.elb.amazonaws.com
TTL: 60 seconds

What happens:
├─ Browser asks: "What is api.myapp.com?"
├─ Route53 responds: "myapp-alb-1234.us-east-1.elb.amazonaws.com"
├─ Browser then asks: "What is myapp-alb-1234.us-east-1.elb.amazonaws.com?"
├─ Route53 responds: "12.34.56.78"
└─ Browser connects to 12.34.56.78
```

**Benefits:**
- ✓ If ALB IP changes, AWS updates automatically
- ✓ No application code changes needed
- ✓ Works with ALB, CloudFront, S3 aliases

**CloudFormation:**
```yaml
Resources:
  APIAlias:
    Type: AWS::Route53::RecordSet
    Properties:
      HostedZoneId: Z1234EXAMPLE
      Name: api.myapp.com
      Type: A
      AliasTarget:
        HostedZoneId: Z35SXDOTRQ7X7K  # ALB zone ID
        DNSName: myapp-alb-1234.us-east-1.elb.amazonaws.com
        EvaluateTargetHealth: true
```

---

#### 3. **Private Hosted Zone (Internal DNS)**

```
Use Case: Route traffic between EC2 instances internally

Setup:
├─ VPC: my-vpc (10.0.0.0/16)
├─ Private Hosted Zone: myapp.internal
└─ Records:
   ├─ db.myapp.internal → RDS endpoint
   ├─ api.myapp.internal → ALB (private IP for internal access)
   └─ cache.myapp.internal → ElastiCache endpoint

Benefits:
├─ ✓ No internet exposure
├─ ✓ DNS works only within VPC
├─ ✓ Can use short names (db instead of full RDS endpoint)
└─ ✓ DNS resolution is local (very fast)
```

**Example Record:**
```
Name: db.myapp.internal
Type: CNAME
Value: mydb.c123xyz.us-east-1.rds.amazonaws.com
TTL: 60 seconds

Usage in application:
├─ Instead of: "mydb.c123xyz.us-east-1.rds.amazonaws.com"
└─ Use: "db.myapp.internal" (shorter, cleaner)
```

---

### DNS Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│ STEP 1: Browser User Action                                 │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ User clicks "Create Account"                                │
│     ↓                                                        │
│ React app makes API call:                                  │
│     POST https://api.myapp.com/users                       │
│                                                              │
└──────────────────────────────────────┬───────────────────────┘
                                       ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 2: Browser DNS Resolution                              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Browser checks cache: "Do I know what api.myapp.com is?"   │
│     ↓                                                        │
│ If YES (cached):                                           │
│   └─ Use cached IP: 12.34.56.78                           │
│     ↓ ⏱️ 0ms                                                │
│ If NO (not cached):                                        │
│   └─ Send DNS query: "What is api.myapp.com?"             │
│     ↓ (To system resolver, ISP resolver)                   │
│     ↓ ⏱️ 50-100ms                                           │
│                                                              │
└──────────────────────────────────────┬───────────────────────┘
                                       ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 3: Route53 Query                                       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ ISP resolver asks Route53:                                 │
│ "I need the IP for api.myapp.com"                         │
│     ↓                                                        │
│ Route53 checks records:                                    │
│   └─ Found: CNAME myapp-alb-1234.us-east-1.elb.amazonaws.com
│     ↓                                                        │
│ Route53 then resolves ALB CNAME:                          │
│   └─ Found: A record 12.34.56.78                          │
│     ↓                                                        │
│ Route53 responds with:                                     │
│   └─ "api.myapp.com = 12.34.56.78"                       │
│     ↓                                                        │
│ ISP resolver caches for TTL (300 seconds)                │
│ ISP resolver sends back to browser                        │
│     ↓ ⏱️ 50-100ms (total)                                   │
│                                                              │
└──────────────────────────────────────┬───────────────────────┘
                                       ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 4: Browser Caches Result                               │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Browser receives: api.myapp.com = 12.34.56.78             │
│ Browser caches for TTL (usually 300 seconds)              │
│                                                              │
│ For next 5 minutes:                                       │
│   ├─ All requests use: 12.34.56.78                        │
│   ├─ No additional DNS queries needed                      │
│   └─ Response time includes zero DNS latency              │
│                                                              │
└──────────────────────────────────────┬───────────────────────┘
                                       ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 5: Browser Connects to ALB                             │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Browser: "Connect to 12.34.56.78:443 (HTTPS)"             │
│     ↓                                                        │
│ ALB receives request                                       │
│     ↓                                                        │
│ ALB forwards to Node.js (10.0.2.45:3000)                 │
│     ↓                                                        │
│ Node.js processes request                                 │
│     ↓                                                        │
│ Result sent back to browser                               │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## RDS ENDPOINT DISCOVERY

### RDS Endpoint Format

```
mydb.c123xyz.us-east-1.rds.amazonaws.com

├─ mydb                        ← Instance name (user-assigned)
├─ c123xyz                      ← AWS resource ID (unique per account)
├─ us-east-1                    ← Region
└─ .rds.amazonaws.com          ← AWS RDS domain
```

### Why RDS Endpoints Are Better Than IPs

**RDS Endpoint Benefits:**
```
1. Automatic Multi-AZ Failover
   ├─ Primary RDS fails → Endpoint automatically points to standby
   ├─ IP of endpoint stays same
   └─ Application works without restart

2. Read Replicas
   ├─ Create read-only replica in different region
   ├─ Different endpoint: mydb-replica.us-west-2.rds.amazonaws.com
   ├─ Same endpoint structure
   └─ Application just uses different DNS name for reads

3. DNS is Cached
   ├─ First query: 50-100ms
   ├─ Cached queries: <1ms
   ├─ OS/driver caches DNS results
   └─ Very little performance impact

4. Encrypted Connection
   ├─ Endpoint forces SSL/TLS
   ├─ Credentials can be enforced
   └─ Standard port: 5432
```

### Using RDS Endpoint in Application

**Node.js:**
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: 'mydb.c123xyz.us-east-1.rds.amazonaws.com',  // ← RDS endpoint
  port: 5432,
  database: 'appdb',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false }  // ← SSL required
});
```

**Python:**
```python
import psycopg2

conn = psycopg2.connect(
    host='mydb.c123xyz.us-east-1.rds.amazonaws.com',  # ← RDS endpoint
    port=5432,
    database='appdb',
    user=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD'),
    sslmode='require'  # ← SSL required
)
```

**Java:**
```
spring.datasource.url=jdbc:postgresql://mydb.c123xyz.us-east-1.rds.amazonaws.com:5432/appdb?sslmode=require
```

---

### RDS Endpoint Resolution

**Behind the Scenes:**
```
Application:
  host = 'mydb.c123xyz.us-east-1.rds.amazonaws.com'
                                    ↓
                    DNS Query (system resolver)
                                    ↓
                    Route53.us-east-1.rds.amazonaws.com
                    └─ Returns: 10.0.5.42 (current primary IP)
                                    ↓
                    Application connects to 10.0.5.42:5432
                                    ↓
                    If Primary RDS fails:
                    ├─ Route53 updates endpoint
                    ├─ Now returns: 10.0.5.99 (standby IP)
                    ├─ Next DNS query gets new IP
                    └─ Application connects to new IP automatically
```

---

## SERVICE DISCOVERY PATTERNS

### Pattern 1: Load Balancer Endpoint

**Use Case:** Scale-out API servers

```
┌────────────────────────────────────────┐
│ Application                            │
│ host = api.myapp.com                  │
└────────────────────────┬───────────────┘
                         ↓
              DNS: api.myapp.com
                         ↓
        Resolves to ALB IP: 12.34.56.78
                         ↓
┌────────────────────────────────────────┐
│ ALB (Load Balancer)                    │
│ IP: 12.34.56.78                       │
└─┬────────────────────────────┬────────┬┘
  │                            │        │
  ↓                            ↓        ↓
Node 1                    Node 2      Node 3
10.0.2.45:3000       10.0.3.67:3000  10.0.4.89:3000

If Node 1 crashes:
├─ ALB removes from rotation
├─ ALB IP stays: 12.34.56.78
├─ ALB routes only to Node 2, 3
└─ ✓ Application works, no DNS change needed
```

---

### Pattern 2: Direct Microservice DNS

**Use Case:** Service-to-service communication

```
Application Structure:
├─ user-service.internal → 10.0.2.45:8000
├─ product-service.internal → 10.0.3.67:8001
├─ order-service.internal → 10.0.4.89:8002
└─ db.internal → mydb.c123xyz.us-east-1.rds.amazonaws.com

User Service Code:
  const productAPI = 'http://product-service.internal:8001';
  const response = await fetch(`${productAPI}/products`);

Benefits:
├─ ✓ Can scale product service (new IPs)
├─ ✓ Can move service to different instance
├─ ✓ No hardcoded IPs
└─ ✓ DNS name stays same
```

---

### Pattern 3: Service Mesh Discovery

**Use Case:** Complex microservices with auto-discovery

```
Example: Istio, Consul, AWS App Mesh

Automatic Service Discovery:
├─ Service registers: "product-service at 10.0.3.67:8001"
├─ Central registry keeps track of all services
├─ Service gets new IP → Registry automatically updates
└─ Other services query registry, get latest IPs

Benefits:
├─ ✓ Zero manual DNS configuration
├─ ✓ Auto-scale services
├─ ✓ Blue-green deployments without DNS changes
└─ ✓ Automatic traffic routing
```

---

### Pattern 4: Environment-Specific Endpoints

**Use Case:** Development, Staging, Production

```
Development:
  api-dev.myapp.com → ALB-Dev (10.0.1.50)

Staging:
  api-staging.myapp.com → ALB-Staging (10.0.2.50)

Production:
  api.myapp.com → ALB-Prod (12.34.56.78)

Each endpoint:
├─ Has its own Route53 record
├─ Points to environment-specific ALB
├─ Has independent security groups
└─ Can be updated independently
```

---

## MULTI-REGION STRATEGY

### Setup: Primary + Backup Region

```
┌─────────────────────────────────────────────────┐
│           PRIMARY REGION (US-EAST-1)            │
│                                                 │
│  Route53 Health Check                          │
│  └─ Monitors api-prod-1.us-east-1.elb.amazonaws.com
│                                                 │
│  ALB-Primary                                   │
│  └─ IP: 12.34.56.78                           │
│  └─ Status: ✓ Healthy                         │
│                                                 │
└─────────────────────────────────────────────────┘

Route53 Geolocation Routing:
├─ North America → Send to US-EAST-1 (Primary)
├─ Europe → Send to EU-WEST-1 (Backup)
└─ Asia → Send to AP-SOUTHEAST-1 (Backup)

User in New York:
├─ Browser asks Route53: "Give me api.myapp.com"
├─ Route53: "You are in North America"
├─ Route53: "Use Primary: 12.34.56.78"
└─ Browser connects to Primary region

If Primary Region Fails:
├─ Route53 health check fails
├─ Route53 switches all traffic to Backup
├─ Users in US redirected to EU-WEST-1
├─ No DNS changes on user side
└─ ✓ Transparent failover
```

**AWS CLI Setup:**
```bash
# Create geolocation routing policy
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234EXAMPLE \
  --change-batch file://routing-policy.json

# routing-policy.json
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "api.myapp.com",
        "Type": "A",
        "SetIdentifier": "Primary-US",
        "GeoLocation": { "CountryCode": "US" },
        "AliasTarget": {
          "HostedZoneId": "Z35SXDOTRQ7X7K",
          "DNSName": "api-prod-1.us-east-1.elb.amazonaws.com",
          "EvaluateTargetHealth": true
        }
      }
    },
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "api.myapp.com",
        "Type": "A",
        "SetIdentifier": "Backup-EU",
        "GeoLocation": { "CountryCode": "DE" },
        "AliasTarget": {
          "HostedZoneId": "Z32O12XQLNTSW2",
          "DNSName": "api-backup.eu-west-1.elb.amazonaws.com",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}
```

---

## TROUBLESHOOTING DNS ISSUES

### Issue 1: "Cannot resolve host" Error

```
Error: getaddrinfo ENOTFOUND mydb.c123xyz.us-east-1.rds.amazonaws.com

Diagnosis:
1. Check DNS resolution:
   nslookup mydb.c123xyz.us-east-1.rds.amazonaws.com
   
   Expected output:
   Server: 8.8.8.8
   Address: 8.8.8.8#53
   
   Non-authoritative answer:
   Name: mydb.c123xyz.us-east-1.rds.amazonaws.com
   Address: 10.0.5.42

2. If fails, check:
   ├─ EC2 security group allows outbound on port 53 (DNS)
   ├─ NACL allows outbound on port 53
   ├─ VPC has DNS resolution enabled
   └─ Route53 private zone is associated with VPC

Solution:
├─ Add to EC2 security group:
│  └─ Outbound: UDP 53 to 0.0.0.0/0 (DNS queries)
├─ Add to VPC NACL:
│  └─ Outbound: UDP 53 to 0.0.0.0/0
├─ Enable in VPC settings:
│  ├─ Enable DNS hostnames
│  └─ Enable DNS resolution
└─ Associate private zone with VPC:
   └─ Route53 → Hosted Zones → Edit associations
```

---

### Issue 2: DNS Resolution Works But Connection Fails

```
Error: Cannot connect to mydb.c123xyz.us-east-1.rds.amazonaws.com:5432

nslookup works: mydb = 10.0.5.42 ✓

But telnet fails:
  telnet mydb.c123xyz.us-east-1.rds.amazonaws.com 5432
  Connection refused

Diagnosis:
├─ DNS works ✓ (resolved to 10.0.5.42)
├─ But TCP connection blocked ✗

Likely cause:
├─ Security group: database-sg doesn't allow port 5432
├─ Source SG: web-sg not in database-sg inbound rules
├─ NACL: doesn't allow port 5432
├─ RDS: not running or in wrong subnet

Solution:
1. Check RDS security group:
   └─ aws ec2 describe-security-groups --group-ids sg-database

2. Check inbound rules:
   └─ Protocol: TCP, Port: 5432, Source: sg-web-servers

3. Test from EC2 instance:
   └─ telnet 10.0.5.42 5432

4. If fails, check NACL:
   └─ Outbound rule: Allow TCP 5432 to 10.0.5.0/24
```

---

### Issue 3: Inconsistent DNS Resolution

```
Problem: Sometimes resolves, sometimes doesn't

Symptoms:
├─ First request works
├─ Second request fails (timeout)
├─ Third request works again
└─ Intermittent failures

Possible causes:
├─ Round-robin DNS (multiple IPs)
├─ Some IPs unreachable
├─ Failover not working
├─ DNS TTL very low (re-resolving constantly)
└─ Stale DNS cache in driver

Diagnosis:
dig api.myapp.com

Output might show multiple IPs:
  ;; ANSWER SECTION:
  api.myapp.com.  60  IN  A  10.0.5.42
  api.myapp.com.  60  IN  A  10.0.5.43
  api.myapp.com.  60  IN  A  10.0.5.44

Solution:
├─ Check application DNS caching TTL
├─ Increase Route53 health check interval
├─ Ensure all IP addresses are reachable
├─ Clear local DNS cache:
│  └─ Linux: systemctl restart systemd-resolved
│  └─ Windows: ipconfig /flushdns
└─ Use connection pooling (reuse connections, don't resolve every time)
```

---

### Issue 4: Very Slow DNS Resolution

```
Problem: DNS queries take 1-5 seconds (should be ~50-100ms)

Diagnosis:
time nslookup mydb.c123xyz.us-east-1.rds.amazonaws.com

Output:
real    0m5.234s  ← Way too slow!

Possible causes:
├─ EC2 DNS resolver misconfigured
├─ Network latency to DNS servers
├─ DNS servers overloaded
├─ Firewall blocking DNS
├─ VPC DNS resolution disabled

Solution:
1. Check EC2 DNS configuration:
   cat /etc/resolv.conf
   
   Should show:
   nameserver 169.254.169.253  (AWS VPC resolver)

2. Check VPC NACL:
   ├─ Outbound: UDP 53 to 0.0.0.0/0
   └─ Inbound: UDP 53 from 0.0.0.0/0 (for responses)

3. Use EC2 metadata service:
   curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/
   
4. Enable enhanced networking (for lower latency)

5. Reduce DNS query frequency:
   ├─ Increase TTL in Route53
   ├─ Use connection pooling
   └─ Cache DNS results in application
```

---

## BEST PRACTICES SUMMARY

### ✓ Always Use

```
1. DNS Names Instead of IPs
   ├─ RDS endpoint: mydb.c123xyz.us-east-1.rds.amazonaws.com
   ├─ ALB endpoint: myapp-alb-1234.us-east-1.elb.amazonaws.com
   └─ Custom domain: api.myapp.com

2. Private Hosted Zones for Internal Services
   ├─ db.myapp.internal → RDS endpoint
   ├─ cache.myapp.internal → ElastiCache endpoint
   └─ Shorter names, DNS only within VPC

3. Route53 Health Checks
   ├─ Monitor ALB availability
   ├─ Automatic failover to backup region
   └─ Transparent to applications

4. Low TTL (Time to Live) for Dynamic Services
   ├─ ALB endpoints: 60 seconds
   ├─ Load-balanced services: 60-120 seconds
   └─ Allows fast failover
```

---

### ✗ Never Do

```
1. Hardcoded IP Addresses in Code
   ❌ "host: '10.0.5.42'"
   ✓ "host: 'mydb.c123xyz.us-east-1.rds.amazonaws.com'"

2. Store IPs in Configuration Files
   ❌ config.json: {"database": "10.0.5.42"}
   ✓ config.json: {"database": "mydb.c123xyz.us-east-1.rds.amazonaws.com"}

3. Assume IPs Stay The Same
   ❌ "This RDS instance has had IP 10.0.5.42 for 2 years"
   ✓ "RDS can change IPs anytime, DNS handles it"

4. Forget to Enable VPC DNS Resolution
   ❌ VPC DNS disabled → All DNS queries fail
   ✓ VPC DNS enabled → Everything works

5. Use Very High TTL (Time to Live)
   ❌ TTL: 86400 (24 hours) → Can't failover for 24 hours
   ✓ TTL: 60 seconds → Failover happens in seconds
```

---

## QUICK REFERENCE

### RDS DNS Name Format

```
[DB-NAME].[RANDOM-ID].[REGION].rds.amazonaws.com

Examples:
├─ mydb.c123xyz.us-east-1.rds.amazonaws.com
├─ proddb.a9876xy.eu-west-1.rds.amazonaws.com
└─ testdb.z5432wx.ap-southeast-1.rds.amazonaws.com

How to find:
├─ AWS Console → RDS → Databases → [Select DB]
├─ Look for: "Endpoint"
└─ Copy the full endpoint URL
```

### Route53 CLI Commands

```bash
# Get all DNS records for a domain
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234EXAMPLE

# Create A record (public)
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234EXAMPLE \
  --change-batch file://changes.json

# Create private hosted zone
aws route53 create-hosted-zone \
  --name myapp.internal \
  --vpc VPCRegion=us-east-1,VPCId=vpc-12345

# Get hosted zone ID
aws route53 list-hosted-zones --query "HostedZones[*].[Name,Id]"
```

---

**Last Updated:** November 27, 2025  
**Best For:** Architects, DevOps Engineers, Full-Stack Developers  
**Applies To:** AWS RDS, ALB, CloudFront, Route53, Multi-region deployments
