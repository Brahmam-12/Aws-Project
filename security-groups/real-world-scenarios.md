# DAY 2 - REAL-WORLD SECURITY SCENARIOS 🏗️

## Production-Grade Security Architectures

---

## 📋 Table of Contents

1. [3-Tier Web Application Security](#scenario-1-3-tier-web-application)
2. [Multi-Environment Security (Dev/Staging/Prod)](#scenario-2-multi-environment-security)
3. [DDoS Protection Architecture](#scenario-3-ddos-protection)
4. [Microservices Security](#scenario-4-microservices-security)
5. [Database Security Layers](#scenario-5-database-security)
6. [Jump Server (Bastion) Security](#scenario-6-bastion-host-security)

---

## 🏢 Scenario 1: 3-Tier Web Application

### Architecture Overview:

```
Internet
   ↓
[NACL-Public]
   ↓
┌─────────────────────────────────────┐
│  PUBLIC SUBNET                      │
│  ┌──────────────────┐               │
│  │ Application Load  │               │
│  │ Balancer (ALB)    │               │
│  │ SG: alb-public-sg │               │
│  └──────────────────┘               │
└─────────────────┬───────────────────┘
                  │
[NACL-Private-App]
                  ↓
┌─────────────────────────────────────┐
│  PRIVATE SUBNET (App Tier)          │
│  ┌───────────┐    ┌───────────┐    │
│  │ Web Server│    │ Web Server│    │
│  │    EC2    │    │    EC2    │    │
│  │ SG: web-sg│    │ SG: web-sg│    │
│  └───────────┘    └───────────┘    │
└─────────────────┬───────────────────┘
                  │
[NACL-Private-DB]
                  ↓
┌─────────────────────────────────────┐
│  PRIVATE SUBNET (Database Tier)     │
│  ┌───────────────────────────────┐  │
│  │      RDS MySQL Primary         │  │
│  │      SG: database-sg           │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

### Security Group Configuration:

#### 1. ALB Security Group (alb-public-sg)

```bash
# INBOUND RULES
Rule 1: HTTP
├── Type: HTTP
├── Protocol: TCP
├── Port: 80
├── Source: 0.0.0.0/0
└── Purpose: Public web access

Rule 2: HTTPS
├── Type: HTTPS
├── Protocol: TCP
├── Port: 443
├── Source: 0.0.0.0/0
└── Purpose: Secure public web access

# OUTBOUND RULES
Rule 1: To Web Servers
├── Type: HTTP
├── Protocol: TCP
├── Port: 80
├── Destination: sg-web-servers (Security Group ID)
│               ↑ Reference web servers SG directly
└── Purpose: Forward requests to backend servers
```

**💡 Key Insight:**
> ALB references web server Security Group by ID (not CIDR). This creates dynamic relationship - if you add more web servers with web-sg, ALB automatically allows traffic to them!

---

#### 2. Web Servers Security Group (web-sg)

```bash
# INBOUND RULES
Rule 1: HTTP from ALB
├── Type: HTTP
├── Protocol: TCP
├── Port: 80
├── Source: sg-alb-public (Security Group ID)
│           ↑ Only ALB can reach web servers
└── Purpose: Accept traffic only from ALB

Rule 2: SSH from Bastion
├── Type: SSH
├── Protocol: TCP
├── Port: 22
├── Source: sg-bastion
└── Purpose: Admin access through bastion only

# OUTBOUND RULES
Rule 1: To Database
├── Type: MySQL/Aurora
├── Protocol: TCP
├── Port: 3306
├── Destination: sg-database
└── Purpose: Query database

Rule 2: To Internet (for updates)
├── Type: HTTPS
├── Protocol: TCP
├── Port: 443
├── Destination: 0.0.0.0/0
└── Purpose: Download security updates via NAT Gateway
```

**💡 Security Features:**
✅ **Security Group Chaining:** Web servers only accept traffic from ALB
✅ **No Direct Internet Access:** Internet users can't directly reach web servers
✅ **Controlled Admin Access:** SSH only through bastion
✅ **Minimal Outbound:** Only database and updates allowed

---

#### 3. Database Security Group (database-sg)

```bash
# INBOUND RULES
Rule 1: MySQL from Web Servers
├── Type: MySQL/Aurora
├── Protocol: TCP
├── Port: 3306
├── Source: sg-web-servers
│           ↑ Only web tier can access database
└── Purpose: Database queries from application

Rule 2: MySQL from Bastion (Optional for debugging)
├── Type: MySQL/Aurora
├── Protocol: TCP
├── Port: 3306
├── Source: sg-bastion
└── Purpose: DBA access for maintenance

# OUTBOUND RULES
Rule 1: None required
└── RDS doesn't initiate outbound connections
└── For RDS, outbound rules can be empty or allow all (default)
```

**💡 Security Features:**
✅ **Zero Internet Exposure:** No public subnet, no internet gateway route
✅ **Application-Only Access:** Only web servers can query database
✅ **Optional Admin Access:** Bastion for DBAs (can be removed for max security)

---

### Network ACL Configuration:

#### NACL-Public (ALB Subnet)

```bash
# INBOUND RULES
Rule #100: Allow HTTP
├── Rule: 100
├── Type: HTTP
├── Protocol: TCP
├── Port: 80
├── Source: 0.0.0.0/0
└── Action: ALLOW

Rule #110: Allow HTTPS
├── Rule: 110
├── Type: HTTPS
├── Protocol: TCP
├── Port: 443
├── Source: 0.0.0.0/0
└── Action: ALLOW

Rule #120: Allow Ephemeral Ports (return traffic)
├── Rule: 120
├── Type: Custom TCP
├── Port Range: 1024-65535
├── Source: 0.0.0.0/0
└── Action: ALLOW

Rule #*: Deny All
└── Default rule (implicit)

# OUTBOUND RULES
Rule #100: Allow to Web Servers
├── Rule: 100
├── Type: HTTP
├── Port: 80
├── Destination: 10.0.3.0/24 (Private subnet CIDR)
└── Action: ALLOW

Rule #110: Allow Ephemeral Ports (return traffic)
├── Rule: 110
├── Port Range: 1024-65535
├── Destination: 0.0.0.0/0
└── Action: ALLOW

Rule #*: Deny All
```

---

#### NACL-Private-App (Web Servers Subnet)

```bash
# INBOUND RULES
Rule #100: Allow HTTP from ALB
├── Rule: 100
├── Type: HTTP
├── Port: 80
├── Source: 10.0.1.0/24 (ALB subnet CIDR)
└── Action: ALLOW

Rule #110: Allow SSH from Bastion
├── Rule: 110
├── Type: SSH
├── Port: 22
├── Source: 10.0.1.0/24 (Bastion subnet)
└── Action: ALLOW

Rule #120: Allow Ephemeral Ports
├── Rule: 120
├── Port Range: 1024-65535
├── Source: 0.0.0.0/0
└── Action: ALLOW

# OUTBOUND RULES
Rule #100: Allow MySQL to Database
├── Rule: 100
├── Type: MySQL/Aurora
├── Port: 3306
├── Destination: 10.0.5.0/24 (Database subnet)
└── Action: ALLOW

Rule #110: Allow HTTPS for Updates
├── Rule: 110
├── Type: HTTPS
├── Port: 443
├── Destination: 0.0.0.0/0
└── Action: ALLOW

Rule #120: Allow Ephemeral Ports
├── Rule: 120
├── Port Range: 1024-65535
├── Destination: 0.0.0.0/0
└── Action: ALLOW
```

---

#### NACL-Private-DB (Database Subnet)

```bash
# INBOUND RULES
Rule #100: Allow MySQL from App Tier
├── Rule: 100
├── Type: MySQL/Aurora
├── Port: 3306
├── Source: 10.0.3.0/24 (App tier subnet)
└── Action: ALLOW

Rule #110: Allow MySQL from Bastion (optional)
├── Rule: 110
├── Type: MySQL/Aurora
├── Port: 3306
├── Source: 10.0.1.0/24 (Bastion subnet)
└── Action: ALLOW

Rule #*: Deny All

# OUTBOUND RULES
Rule #100: Allow Ephemeral Ports
├── Rule: 100
├── Port Range: 1024-65535
├── Destination: 0.0.0.0/0
└── Action: ALLOW

Rule #*: Deny All
```

---

### 🎯 Defense in Depth Analysis:

#### Traffic Flow: User → Database

```
Step 1: User Request (Internet → ALB)
├── NACL-Public Inbound: Allow HTTPS (443) ✅
├── SG-ALB Inbound: Allow HTTPS (443) from 0.0.0.0/0 ✅
└── Result: ALB receives request ✅

Step 2: ALB → Web Server
├── SG-ALB Outbound: Allow HTTP to sg-web-servers ✅
├── NACL-Public Outbound: Allow HTTP to 10.0.3.0/24 ✅
├── NACL-Private-App Inbound: Allow HTTP from 10.0.1.0/24 ✅
├── SG-Web Inbound: Allow HTTP from sg-alb-public ✅
└── Result: Web server receives request ✅

Step 3: Web Server → Database
├── SG-Web Outbound: Allow MySQL to sg-database ✅
├── NACL-Private-App Outbound: Allow MySQL to 10.0.5.0/24 ✅
├── NACL-Private-DB Inbound: Allow MySQL from 10.0.3.0/24 ✅
├── SG-Database Inbound: Allow MySQL from sg-web-servers ✅
└── Result: Database query succeeds ✅

Step 4: Database → Web Server (Response)
├── SG-Database: Stateful - auto-allows response ✅
├── NACL-Private-DB Outbound: Ephemeral ports ✅
├── NACL-Private-App Inbound: Ephemeral ports ✅
├── SG-Web: Stateful - auto-allows response ✅
└── Result: Data returned ✅

Step 5: Web Server → ALB (Response)
├── SG-Web: Stateful - auto-allows response ✅
├── NACL-Private-App Outbound: Ephemeral ports ✅
├── NACL-Public Inbound: Ephemeral ports ✅
├── SG-ALB: Stateful - auto-allows response ✅
└── Result: ALB receives data ✅

Step 6: ALB → User (Response)
├── SG-ALB: Stateful - auto-allows response ✅
├── NACL-Public Outbound: Ephemeral ports ✅
└── Result: User sees webpage ✅

Total Security Checks: 24 checkpoints
Single point of failure: NONE ✅
```

---

### ✅ Best Practices Demonstrated:

1. ✅ **Security Group Chaining**
   - Web servers only accept from ALB SG
   - Database only accepts from Web SG
   - Self-documenting security relationships

2. ✅ **Defense in Depth**
   - 4 security layers per request
   - NACL + SG at each tier
   - Multiple failure points before breach

3. ✅ **Principle of Least Privilege**
   - Each tier only has required access
   - No unnecessary ports open
   - Minimal outbound rules

4. ✅ **Network Segmentation**
   - Public, Private-App, Private-DB subnets
   - Different NACLs per subnet
   - Blast radius containment

---

## 🌍 Scenario 2: Multi-Environment Security

### Problem Statement:
> "We have Dev, Staging, and Production environments. Developers need access to Dev, limited access to Staging, and no access to Production. How do we configure Security Groups?"

---

### Architecture:

```
VPC: 10.0.0.0/16

├── PRODUCTION (10.0.0.0/20)
│   ├── Public: 10.0.1.0/24, 10.0.2.0/24
│   ├── Private: 10.0.3.0/24, 10.0.4.0/24
│   └── Database: 10.0.5.0/24, 10.0.6.0/24
│
├── STAGING (10.0.16.0/20)
│   ├── Public: 10.0.17.0/24, 10.0.18.0/24
│   ├── Private: 10.0.19.0/24, 10.0.20.0/24
│   └── Database: 10.0.21.0/24, 10.0.22.0/24
│
└── DEV (10.0.32.0/20)
    ├── Public: 10.0.33.0/24, 10.0.34.0/24
    ├── Private: 10.0.35.0/24, 10.0.36.0/24
    └── Database: 10.0.37.0/24, 10.0.38.0/24
```

---

### Security Group Strategy:

#### Production Environment (STRICT)

```bash
# PRODUCTION WEB SERVERS (prod-web-sg)

Inbound Rules:
├── HTTP from prod-alb-sg only
├── SSH from prod-bastion-sg only (no direct developer access)
└── NO access from Dev or Staging

Outbound Rules:
├── MySQL to prod-db-sg
├── HTTPS for updates
└── NO cross-environment access

# PRODUCTION DATABASE (prod-db-sg)

Inbound Rules:
├── MySQL from prod-web-sg only
├── MySQL from prod-bastion-sg (DBA access only)
└── NO access from Dev or Staging
└── NO developer access

Outbound Rules:
└── None required
```

**🔒 Security Features:**
- ✅ Zero developer direct access
- ✅ All access through bastion (auditable)
- ✅ Isolated from other environments
- ✅ DBA approval required for database access

---

#### Staging Environment (MODERATE)

```bash
# STAGING WEB SERVERS (staging-web-sg)

Inbound Rules:
├── HTTP from staging-alb-sg
├── SSH from staging-bastion-sg
├── SSH from specific developer IPs (limited team)
│   Example: 203.0.113.10/32 (Lead Developer)
└── NO access from Dev environment

Outbound Rules:
├── MySQL to staging-db-sg
├── HTTPS for updates
├── HTTPS to external APIs (for testing)
└── NO access to Production

# STAGING DATABASE (staging-db-sg)

Inbound Rules:
├── MySQL from staging-web-sg
├── MySQL from staging-bastion-sg
├── MySQL from specific DBA IPs
│   Example: 203.0.113.20/32 (DBA laptop)
└── NO access from Dev or Production

Outbound Rules:
└── None required
```

**🔒 Security Features:**
- ✅ Limited developer SSH access
- ✅ DBA can access for testing
- ✅ Similar to production (testing parity)
- ✅ Isolated from Dev and Production

---

#### Dev Environment (RELAXED)

```bash
# DEV WEB SERVERS (dev-web-sg)

Inbound Rules:
├── HTTP from dev-alb-sg
├── SSH from anywhere in office network
│   Example: 203.0.113.0/24 (Office CIDR)
├── HTTP/HTTPS from anywhere in office (for testing)
├── Custom ports for debugging (e.g., 8080, 3000)
└── NO access from Staging or Production

Outbound Rules:
├── MySQL to dev-db-sg
├── HTTPS for updates
├── All traffic to internet (for package installs)
└── NO access to Staging or Production

# DEV DATABASE (dev-db-sg)

Inbound Rules:
├── MySQL from dev-web-sg
├── MySQL from office network
│   Example: 203.0.113.0/24 (All developers)
└── MySQL from developer laptops (for local testing)
└── NO access from Staging or Production

Outbound Rules:
└── None required
```

**🔒 Security Features:**
- ✅ Open developer access for productivity
- ✅ Still isolated from Staging and Production
- ✅ Supports rapid development
- ✅ Can be rebuilt easily if compromised

---

### 📊 Environment Comparison:

| Feature | Production | Staging | Dev |
|---------|-----------|---------|-----|
| **Developer SSH** | ❌ No | ⚠️ Lead Dev only | ✅ All developers |
| **Database Access** | ❌ DBA only | ⚠️ DBA + Leads | ✅ All developers |
| **Cross-Environment** | ❌ Isolated | ❌ Isolated | ❌ Isolated |
| **Bastion Required** | ✅ Yes | ✅ Yes | ⚠️ Optional |
| **Internet Access** | ⚠️ Minimal | ⚠️ Testing only | ✅ Full access |
| **Audit Logging** | ✅ All access logged | ✅ All access logged | ⚠️ Optional |

---

### 🎯 Access Control Matrix:

```
Role: Junior Developer
├── Production: NO ACCESS ❌
├── Staging: NO ACCESS ❌
└── Dev: Full access ✅

Role: Senior Developer
├── Production: Bastion + read-only ⚠️
├── Staging: SSH + database read ✅
└── Dev: Full access ✅

Role: DevOps Engineer
├── Production: Bastion + deployment ✅
├── Staging: Full access ✅
└── Dev: Full access ✅

Role: DBA
├── Production: Database full access ✅
├── Staging: Database full access ✅
└── Dev: Database full access ✅

Role: Security Team
├── Production: Audit + emergency access ✅
├── Staging: Audit access ✅
└── Dev: Audit access ✅
```

---

### 🚨 Incident Response Scenario:

**Problem:** Production database breach suspected

**Response Steps:**

```bash
1. Immediate Lockdown (T+0 minutes):
   └── Remove all non-essential rules from prod-db-sg
   └── Keep only prod-web-sg access
   └── Block all external IPs

2. Investigation (T+5 minutes):
   └── Add Security Team IP to prod-bastion-sg
   └── Access through bastion only
   └── Review CloudWatch Logs
   └── Check VPC Flow Logs

3. Verification (T+30 minutes):
   └── False alarm: Developer accessed from home IP
   └── Home IP not in approved list
   └── Add developer home IP to staging-bastion-sg (not prod)
   └── Remind team of access policies

4. Restore (T+60 minutes):
   └── Re-enable normal prod-db-sg rules
   └── Update documentation
   └── Send team reminder about VPN usage

Time to lockdown: < 30 seconds (remove one SG rule)
No service disruption to users ✅
```

---

## 🛡️ Scenario 3: DDoS Protection

### Problem Statement:
> "We're experiencing DDoS attack with 10,000 requests/second from multiple IPs. How do we use Security Groups and NACLs to mitigate?"

---

### Attack Patterns:

#### Pattern 1: SYN Flood Attack
```
Attack: Sending thousands of TCP SYN packets
Goal: Exhaust server connection table
Source: 1,000+ attacking IPs
```

**Mitigation Strategy:**

```bash
Step 1: Identify Attack Pattern
├── CloudWatch Metrics show spike in connections
├── VPC Flow Logs show thousands of IPs
└── Attack IPs from specific countries/ranges

Step 2: NACL Block (Subnet-Level)
├── Create NACL rule for each attacker range
├── Example:
│   Rule #10: DENY ALL from 198.51.100.0/24
│   Rule #15: DENY ALL from 203.0.113.0/24
│   Rule #20: DENY ALL from 192.0.2.0/24
└── Blocks before reaching instances (efficient)

Step 3: AWS Shield Standard (Free)
├── Automatically enabled
├── Protects against common DDoS
└── No configuration needed

Step 4: AWS Shield Advanced (Optional - $3,000/month)
├── 24/7 DDoS Response Team
├── Real-time attack notifications
└── Cost protection for scaling
```

---

#### Pattern 2: HTTP Flood Attack
```
Attack: Legitimate-looking HTTP requests
Goal: Overwhelm application
Source: Botnet with rotating IPs
```

**Mitigation Strategy:**

```bash
Step 1: Application Load Balancer + AWS WAF

WAF Web ACL Rules:
├── Rule 1: Rate Limiting
│   └── Block if > 100 requests/5 minutes from same IP
│
├── Rule 2: Geo-Blocking
│   └── Block requests from non-customer countries
│
├── Rule 3: Known Bad IPs (IP Set)
│   └── Automatically updated threat intelligence
│
└── Rule 4: Bot Control
    └── Challenge suspicious user agents

Step 2: ALB Connection Draining
├── Gracefully handle legitimate connections
├── Drop new connections from attackers
└── Maintain service for real users

Step 3: Auto Scaling
├── Scale out to handle increased load
├── Distribute attack across more instances
└── AWS Shield Advanced covers extra costs

Cost Example:
Normal: 2 instances ($100/month)
During Attack: 10 instances ($500/month)
Shield Advanced: Reimburses extra $400 ✅
```

---

### 🎯 DDoS Defense Architecture:

```
Internet (Attack Source)
   ↓
[CloudFront] ← Optional: Edge caching, absorbs attack
   ↓
[AWS Shield Standard] ← Automatic DDoS protection
   ↓
[AWS WAF] ← Rules: Rate limit, geo-block, bot control
   ↓
[Application Load Balancer]
   ├── SG: alb-public-sg
   └── Connection draining enabled
   ↓
[NACL-Public] ← Block known attacker IPs/ranges
   ↓
[Target Group - Web Servers]
   ├── Auto Scaling (2-10 instances)
   ├── SG: web-sg (only allows from ALB)
   └── Health checks (unhealthy = removed)

Defense Layers: 6 independent checkpoints ✅
```

---

### 📊 Attack Mitigation Comparison:

| Method | Response Time | Cost | Effectiveness | Use Case |
|--------|---------------|------|---------------|----------|
| **NACL Rules** | < 1 second | Free | ⭐⭐⭐ Good | Block specific IPs/ranges |
| **Security Groups** | < 1 second | Free | ⭐⭐ Limited | Not ideal for DDoS (allow-only) |
| **AWS WAF** | Real-time | ~$5-20/mo | ⭐⭐⭐⭐ Excellent | HTTP/HTTPS attacks |
| **AWS Shield Standard** | Automatic | Free | ⭐⭐⭐ Good | Common DDoS |
| **AWS Shield Advanced** | < 1 minute | $3,000/mo | ⭐⭐⭐⭐⭐ Best | Large-scale DDoS |
| **CloudFront** | Edge-level | ~$10-50/mo | ⭐⭐⭐⭐ Excellent | Global distribution |

---

### ✅ DDoS Response Checklist:

**Phase 1: Detection (0-5 minutes)**
- [ ] Monitor CloudWatch alarms trigger
- [ ] Check VPC Flow Logs for abnormal patterns
- [ ] Identify attack type (SYN flood, HTTP flood, etc.)
- [ ] Confirm legitimate traffic still working

**Phase 2: Immediate Mitigation (5-15 minutes)**
- [ ] Create NACL rules to block top attacker IPs
- [ ] Enable AWS WAF rules if not already active
- [ ] Scale out application (increase instance count)
- [ ] Enable CloudFront if not already in use

**Phase 3: Advanced Mitigation (15-60 minutes)**
- [ ] Contact AWS Support (Shield Advanced customers: DRT team)
- [ ] Analyze attack pattern in detail
- [ ] Create custom WAF rules for specific attack
- [ ] Update NACL rules with additional ranges

**Phase 4: Post-Attack (After mitigation)**
- [ ] Document attack details
- [ ] Review and improve monitoring
- [ ] Update incident response playbook
- [ ] Consider Shield Advanced if not already subscribed

---

## 🔧 Scenario 4: Microservices Security

### Problem Statement:
> "We have 5 microservices that need to communicate. How do we secure service-to-service communication?"

---

### Microservices Architecture:

```
Internet
   ↓
[API Gateway]
   ↓
┌────────────────────────────────────────────────────┐
│                                                    │
│  [User Service] → [Auth Service]                  │
│       ↓                                            │
│  [Order Service] → [Payment Service]              │
│       ↓                                            │
│  [Inventory Service]                              │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

### Security Group Strategy:

#### 1. API Gateway Security Group (api-gateway-sg)

```bash
Inbound Rules:
├── HTTPS (443) from 0.0.0.0/0
└── Purpose: Public API access

Outbound Rules:
├── HTTP (8080) to sg-user-service
├── HTTP (8080) to sg-auth-service
├── HTTP (8080) to sg-order-service
└── Purpose: Route requests to appropriate services
```

---

#### 2. User Service Security Group (user-service-sg)

```bash
Inbound Rules:
├── HTTP (8080) from sg-api-gateway
├── HTTP (8080) from sg-order-service
│   ↑ Order service needs user info
└── Purpose: Accept requests from API Gateway and Order Service

Outbound Rules:
├── HTTP (8080) to sg-auth-service
│   ↑ User service checks authentication
├── MySQL (3306) to sg-users-db
│   ↑ User service reads user database
└── Purpose: Call auth service and database
```

---

#### 3. Auth Service Security Group (auth-service-sg)

```bash
Inbound Rules:
├── HTTP (8080) from sg-api-gateway
├── HTTP (8080) from sg-user-service
├── HTTP (8080) from sg-order-service
├── HTTP (8080) from sg-payment-service
│   ↑ ALL services need authentication
└── Purpose: Centralized authentication

Outbound Rules:
├── Redis (6379) to sg-auth-cache
│   ↑ Cache tokens for performance
└── Purpose: Session management
```

---

#### 4. Order Service Security Group (order-service-sg)

```bash
Inbound Rules:
├── HTTP (8080) from sg-api-gateway
└── Purpose: Create orders from API

Outbound Rules:
├── HTTP (8080) to sg-user-service
│   ↑ Get user details
├── HTTP (8080) to sg-auth-service
│   ↑ Verify user is authenticated
├── HTTP (8080) to sg-payment-service
│   ↑ Process payment
├── HTTP (8080) to sg-inventory-service
│   ↑ Check stock availability
├── MySQL (3306) to sg-orders-db
│   ↑ Store order data
└── Purpose: Orchestrate order process
```

---

#### 5. Payment Service Security Group (payment-service-sg)

```bash
Inbound Rules:
├── HTTP (8080) from sg-order-service
│   ↑ ONLY Order Service can call Payment
└── Purpose: Restricted access to sensitive service

Outbound Rules:
├── HTTP (8080) to sg-auth-service
│   ↑ Verify payment authorization
├── HTTPS (443) to 0.0.0.0/0
│   ↑ Call external payment gateway (Stripe, PayPal)
├── MySQL (3306) to sg-payments-db
│   ↑ Store payment transactions
└── Purpose: Process payments securely
```

---

#### 6. Inventory Service Security Group (inventory-service-sg)

```bash
Inbound Rules:
├── HTTP (8080) from sg-order-service
│   ↑ ONLY Order Service can check inventory
└── Purpose: Controlled inventory access

Outbound Rules:
├── MySQL (3306) to sg-inventory-db
│   ↑ Read/update stock levels
└── Purpose: Manage inventory
```

---

### 🔒 Security Principles Demonstrated:

#### 1. Service-to-Service Authentication
```
Every microservice MUST:
├── Validate caller identity (JWT token)
├── Check authorization (role-based access)
├── Only accept from allowed Security Groups
└── Log all access attempts

Example Flow:
1. API Gateway → User Service (with JWT token)
2. User Service validates JWT
3. User Service checks sg-api-gateway
4. Both pass → Request processed ✅
```

---

#### 2. Least Privilege per Service
```
Payment Service Example:
├── Inbound: ONLY Order Service ← Restricted
├── Outbound: Auth, Payment Gateway, Database
└── Result: Cannot be called by other services

Benefit:
✅ If User Service compromised → Cannot access Payment
✅ Attacker must compromise Order Service too
✅ Additional hurdle for attackers
```

---

#### 3. Database Isolation per Service
```
Traditional (Bad):
└── All services → One database ❌

Microservices (Good):
├── User Service → Users Database
├── Order Service → Orders Database
├── Payment Service → Payments Database
└── Inventory Service → Inventory Database

Benefits:
✅ Database breach doesn't expose all data
✅ Each database has different credentials
✅ Services can't access each other's data
```

---

### 📊 Service Communication Matrix:

| Service | Can Call | Called By |
|---------|----------|-----------|
| **API Gateway** | All services | Internet |
| **User Service** | Auth, Users DB | API Gateway, Order Service |
| **Auth Service** | Auth Cache | All services |
| **Order Service** | User, Auth, Payment, Inventory, Orders DB | API Gateway |
| **Payment Service** | Auth, External Gateway, Payments DB | Order Service ONLY |
| **Inventory Service** | Inventory DB | Order Service ONLY |

---

### ✅ Microservices Security Checklist:

- [ ] Each microservice has its own Security Group
- [ ] Security Groups use SG IDs (not CIDRs) for service references
- [ ] Sensitive services (Payment, Inventory) have restricted callers
- [ ] All services validate JWT tokens
- [ ] Each service has its own database
- [ ] Database Security Groups only allow their service
- [ ] All cross-service calls logged and monitored
- [ ] Rate limiting implemented per service
- [ ] Circuit breakers for cascading failures
- [ ] No service has direct internet access (except via NAT)

---

## 📦 Scenario 5: Database Security Layers

### Problem Statement:
> "Our RDS database stores credit card information. What are ALL the security layers we should implement?"

---

### Complete Database Security Architecture:

```
Layer 7: Application
   ↓
Layer 6: IAM Database Authentication
   ↓
Layer 5: Security Group
   ↓
Layer 4: Network ACL
   ↓
Layer 3: Private Subnet (No Internet)
   ↓
Layer 2: Encryption in Transit (SSL/TLS)
   ↓
Layer 1: Encryption at Rest (KMS)
   ↓
[RDS MySQL Database]
```

---

### Layer 1: Network Isolation

#### Private Subnet Configuration:

```bash
Database Subnet: 10.0.5.0/24
├── Route Table:
│   ├── 10.0.0.0/16 → local (VPC only)
│   └── NO Internet Gateway route ❌
│
├── Purpose:
│   └── Database physically isolated from internet
│
└── Result:
    └── Even if SG/NACL misconfigured, database unreachable from internet ✅
```

---

### Layer 2: Network ACL (Subnet Level)

```bash
NACL-Database Inbound Rules:

Rule #100: Allow MySQL from App Tier
├── Protocol: TCP
├── Port: 3306
├── Source: 10.0.3.0/24 (App subnet)
└── Action: ALLOW

Rule #110: Allow MySQL from Bastion (for DBA)
├── Protocol: TCP
├── Port: 3306
├── Source: 10.0.1.0/24 (Bastion subnet)
└── Action: ALLOW

Rule #*: DENY ALL (default)
└── Everything else blocked

NACL-Database Outbound Rules:

Rule #100: Allow Ephemeral Ports
├── Port Range: 1024-65535
├── Destination: 10.0.0.0/16 (VPC)
└── Purpose: Return traffic

Rule #*: DENY ALL
```

**🔒 Protection:** Even if Security Group has wrong rule, NACL blocks at subnet boundary

---

### Layer 3: Security Group (Instance Level)

```bash
database-sg Inbound Rules:

Rule 1: MySQL from Application Tier
├── Type: MySQL/Aurora
├── Port: 3306
├── Source: sg-app-servers (Security Group ID)
│           ↑ References SG, not CIDR
└── Purpose: Application database access

Rule 2: MySQL from Bastion
├── Type: MySQL/Aurora
├── Port: 3306
├── Source: sg-bastion
└── Purpose: DBA access only

Rule 3: MySQL from Read Replica (if any)
├── Type: MySQL/Aurora
├── Port: 3306
├── Source: sg-database-replica
└── Purpose: Replication traffic

database-sg Outbound Rules:
└── ALL traffic to 0.0.0.0/0 (default)
    └── RDS manages backups, snapshots to S3
```

**🔒 Protection:** Fine-grained instance-level control

---

### Layer 4: IAM Database Authentication

```bash
Enable IAM Authentication for RDS:

Traditional (Password):
├── Username: admin
├── Password: stored somewhere ❌
└── Risk: Password can be stolen

IAM Authentication:
├── No password stored
├── Application uses IAM role
├── AWS generates temporary token (15 minutes)
└── Token rotates automatically ✅

Configuration:

# Enable on RDS instance
aws rds modify-db-instance \
  --db-instance-identifier my-database \
  --enable-iam-database-authentication

# Grant IAM policy to application role
{
  "Effect": "Allow",
  "Action": "rds-db:connect",
  "Resource": "arn:aws:rds-db:region:account:dbuser:db-id/db-user"
}

# Application connects with token (not password)
TOKEN=$(aws rds generate-db-auth-token \
  --hostname mydatabase.region.rds.amazonaws.com \
  --port 3306 \
  --username dbuser)

mysql -h mydatabase.region.rds.amazonaws.com \
  --ssl-ca=rds-ca-2019-root.pem \
  --enable-cleartext-plugin \
  --user=dbuser \
  --password=$TOKEN
```

**✅ Benefits:**
- No passwords in code
- Automatic rotation (15-minute tokens)
- IAM audit trail
- Centralized access control

---

### Layer 5: Encryption in Transit (SSL/TLS)

```bash
Require SSL Connections:

# MySQL Parameter Group
[mysqld]
require_secure_transport = 1
 ↑ Forces all connections to use SSL

# Application connection string
mysql -h mydatabase.region.rds.amazonaws.com \
  --ssl-ca=/path/to/rds-ca-2019-root.pem \
  --ssl-mode=REQUIRED \
  -u dbuser -p

Verification:
mysql> SHOW STATUS LIKE 'Ssl_cipher';
+---------------+--------------------+
| Variable_name | Value              |
+---------------+--------------------+
| Ssl_cipher    | DHE-RSA-AES256-SHA |
+---------------+--------------------+
✅ Encrypted connection confirmed
```

**🔒 Protection:** Data encrypted in transit, protects against:
- Packet sniffing
- Man-in-the-middle attacks
- Network eavesdropping

---

### Layer 6: Encryption at Rest (KMS)

```bash
Enable at RDS Creation:

Storage Encryption:
├── Encryption: Enabled ✅
├── KMS Key: aws/rds (default) or custom CMK
└── Effect:
    ├── Database files encrypted
    ├── Automated backups encrypted
    ├── Read replicas encrypted
    ├── Snapshots encrypted
    └── Logs encrypted

Key Management:
├── AWS Managed Key (aws/rds): Free
│   └── AWS rotates automatically
│
└── Customer Managed Key (CMK): $1/month
    ├── You control rotation policy
    ├── You control access policies
    └── Audit key usage in CloudTrail

Verification:
aws rds describe-db-instances \
  --db-instance-identifier my-database \
  --query 'DBInstances[0].StorageEncrypted'

Output: true ✅
```

**🔒 Protection:** Data encrypted at rest, protects against:
- Disk theft
- Unauthorized snapshots
- Backup theft

**⚠️ IMPORTANT:** Cannot enable encryption after creation! Must create new encrypted RDS and migrate data.

---

### Layer 7: Database Auditing & Monitoring

```bash
Enable RDS Enhanced Monitoring:
├── CPU, memory, disk, network metrics
├── Process list (what queries running)
├── 1-second granularity
└── CloudWatch Logs integration

Enable RDS Performance Insights:
├── Top SQL queries
├── Database load analysis
├── Wait events
└── Free tier: 7 days retention

Enable MySQL Audit Plugin:
├── Log all database connections
├── Log all SQL queries
├── Log all user changes
└── Store in CloudWatch Logs

Example Audit Log:
{
  "timestamp": "2024-01-01T10:00:00Z",
  "user": "app_user@10.0.3.45",
  "query": "SELECT * FROM credit_cards WHERE user_id = 12345",
  "database": "production",
  "result": "Success"
}

Alert on suspicious activity:
├── Multiple failed login attempts
├── Access from unexpected IPs
├── Large data exports
├── Schema changes
└── Privilege escalation attempts
```

---

### Layer 8: Backup & Disaster Recovery

```bash
Automated Backups:
├── Retention: 30 days (max)
├── Backup window: 3:00-4:00 AM UTC
├── Encrypted backups
└── Point-in-time recovery

Manual Snapshots:
├── Before major changes
├── Before deployments
├── Monthly compliance snapshots
└── Can be shared across accounts

Snapshot Sharing (for DR):
aws rds modify-db-snapshot-attribute \
  --db-snapshot-identifier my-snapshot \
  --attribute-name restore \
  --values-to-add 123456789012
  ↑ DR account ID

Cross-Region Replication:
├── Primary: us-east-1
├── Read Replica: us-west-2
└── Failover time: < 5 minutes
```

---

### 🎯 Complete Security Checklist:

**Network Security:**
- [ ] Database in private subnet (no internet route)
- [ ] NACL allows only app subnet and bastion
- [ ] Security Group references SG IDs (not CIDRs)
- [ ] No 0.0.0.0/0 access in database SG

**Authentication & Authorization:**
- [ ] IAM database authentication enabled
- [ ] No passwords in code
- [ ] Least privilege IAM policies
- [ ] MFA for DBA accounts

**Encryption:**
- [ ] Encryption at rest enabled (KMS)
- [ ] SSL/TLS required for connections
- [ ] Custom KMS key for compliance
- [ ] Encrypted backups and snapshots

**Monitoring & Auditing:**
- [ ] Enhanced Monitoring enabled
- [ ] Performance Insights enabled
- [ ] Audit plugin enabled
- [ ] CloudWatch alarms for suspicious activity
- [ ] VPC Flow Logs enabled

**Backup & Recovery:**
- [ ] Automated backups: 30 days retention
- [ ] Manual snapshots before changes
- [ ] Cross-region read replica
- [ ] Tested restore procedure

**Compliance:**
- [ ] PCI DSS compliance (if credit cards)
- [ ] HIPAA compliance (if healthcare)
- [ ] Regular security audits
- [ ] Documented access procedures

---

### 📊 Security Layers Summary:

| Layer | Protection Against | Implementation |
|-------|-------------------|----------------|
| **Private Subnet** | Internet exposure | No IGW route |
| **NACL** | Subnet-level threats | DENY rules |
| **Security Group** | Instance-level threats | ALLOW rules, SG references |
| **IAM Auth** | Password theft | Token-based, no passwords |
| **SSL/TLS** | Transit sniffing | Force SSL parameter |
| **KMS Encryption** | Disk theft | Enable at creation |
| **Audit Logs** | Unauthorized access | Enhanced Monitoring + Audit plugin |
| **Backups** | Data loss | Automated + manual snapshots |

**Defense in Depth:** 8 independent security layers ✅

---

## 🚀 Scenario 6: Bastion Host Security

### Problem Statement:
> "How do we securely allow DBAs and developers to access private instances?"

---

### Bastion Architecture:

```
Internet
   ↓
[NACL-Public]
   ↓
┌────────────────────────────┐
│  PUBLIC SUBNET             │
│  ┌──────────────────────┐  │
│  │  Bastion Host         │  │
│  │  (Hardened EC2)       │  │
│  │  SG: bastion-sg       │  │
│  └──────────────────────┘  │
└──────────┬─────────────────┘
           │
[NACL-Private]
           ↓
┌────────────────────────────┐
│  PRIVATE SUBNET            │
│  ┌──────────────────────┐  │
│  │  App Server           │  │
│  │  SG: app-sg           │  │
│  └──────────────────────┘  │
│  ┌──────────────────────┐  │
│  │  Database             │  │
│  │  SG: db-sg            │  │
│  └──────────────────────┘  │
└────────────────────────────┘
```

---

### Security Configuration:

#### Bastion Security Group (bastion-sg)

```bash
Inbound Rules:

Rule 1: SSH from Company Office
├── Type: SSH
├── Protocol: TCP
├── Port: 22
├── Source: 203.0.113.0/24 (Office IP range)
└── Purpose: Employees from office

Rule 2: SSH from VPN
├── Type: SSH
├── Port: 22
├── Source: 198.51.100.0/24 (VPN IP range)
└── Purpose: Remote employees on VPN

❌ NO 0.0.0.0/0 access (never!)

Outbound Rules:

Rule 1: SSH to Private Instances
├── Type: SSH
├── Port: 22
├── Destination: sg-app-servers
└── Purpose: Admin access to app servers

Rule 2: MySQL to Database
├── Type: MySQL/Aurora
├── Port: 3306
├── Destination: sg-database
└── Purpose: DBA access

Rule 3: HTTPS for Updates
├── Type: HTTPS
├── Port: 443
├── Destination: 0.0.0.0/0
└── Purpose: Security updates only
```

---

#### Private Instance Security Groups

```bash
App Server SG (app-sg):

Inbound Rules:
├── SSH from sg-bastion (Admin access)
└── HTTP from sg-alb (Application traffic)

Database SG (db-sg):

Inbound Rules:
├── MySQL from sg-app-servers (Application queries)
└── MySQL from sg-bastion (DBA access)
```

---

### 🔒 Bastion Hardening:

#### 1. Operating System Hardening

```bash
# Disable password authentication (SSH keys only)
sudo vi /etc/ssh/sshd_config
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no

# Install fail2ban (block brute force)
sudo yum install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Automatic security updates
sudo yum install yum-cron -y
sudo systemctl enable yum-cron
sudo systemctl start yum-cron

# Minimal software (remove unnecessary packages)
sudo yum remove httpd* php* mysql* -y

# Audit logging
sudo yum install audit -y
sudo systemctl enable auditd
sudo systemctl start auditd
```

---

#### 2. SSH Key Management

```bash
# Each user has their own key
Employee 1: ssh-keygen -t ed25519 -C "john@company.com"
Employee 2: ssh-keygen -t ed25519 -C "jane@company.com"

# Add to bastion authorized_keys
~/.ssh/authorized_keys:
ssh-ed25519 AAAAC3NzaC1lZ... john@company.com
ssh-ed25519 AAAAC3NzaC1lZ... jane@company.com

# Key rotation policy
├── Rotate keys every 90 days
├── Remove keys when employee leaves
└── Audit key usage monthly

# Connection example
ssh -i ~/.ssh/id_ed25519 ec2-user@bastion-ip
```

---

#### 3. Session Manager (Alternative to Bastion)

```bash
AWS Systems Manager Session Manager:

Benefits over traditional bastion:
✅ No need for SSH keys
✅ No need for bastion public IP
✅ Fully audited in CloudTrail
✅ Session recordings
✅ No Security Group SSH rules
✅ Supports IAM policies

Setup:
1. Attach IAM role to instances:
   └── AmazonSSMManagedInstanceCore policy

2. Connect via console or CLI:
   aws ssm start-session --target i-1234567890abcdef0

3. Access is controlled via IAM:
   {
     "Effect": "Allow",
     "Action": "ssm:StartSession",
     "Resource": "arn:aws:ec2:region:account:instance/*",
     "Condition": {
       "StringEquals": {
         "ssm:resourceTag/Environment": "production"
       }
     }
   }

Audit Trail:
└── Every command logged to S3
└── Who, what, when, where

Result: More secure than bastion ✅
```

---

### 🎯 Bastion Best Practices:

1. ✅ **Restrict Source IPs**
   - Only office and VPN ranges
   - Never 0.0.0.0/0

2. ✅ **SSH Keys Only**
   - No passwords
   - Unique key per user
   - Regular rotation

3. ✅ **Minimal Software**
   - No web servers
   - No databases
   - Only SSH and tools

4. ✅ **Automatic Updates**
   - Security patches daily
   - OS updates weekly

5. ✅ **Full Auditing**
   - CloudWatch Logs
   - All SSH sessions logged
   - Regular reviews

6. ✅ **MFA (Multi-Factor Authentication)**
   - Require MFA for SSH
   - Use Google Authenticator

7. ✅ **Consider Session Manager**
   - More secure than bastion
   - No public IP needed
   - Better auditing

---

**🎓 You now have complete production-ready security scenarios! Ready for Day 2 hands-on? 🚀**
