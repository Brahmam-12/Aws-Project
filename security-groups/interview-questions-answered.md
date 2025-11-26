# DAY 2 - INTERVIEW QUESTIONS & ANSWERS 🎯

## Complete Interview Preparation Guide

---

## ❓ Question 1: Are Security Groups stateful or stateless?

### 📖 Answer:

**Security Groups are STATEFUL.**

### 🔍 Detailed Explanation:

**What "Stateful" Means:**

Security Groups **remember** (track) the state of connections. When you allow inbound traffic, the return (response) traffic is automatically allowed, WITHOUT needing an explicit outbound rule.

**Think of it like a smart doorman:**
- When someone enters (inbound), the doorman remembers them
- When they leave (outbound), the doorman automatically lets them out
- No need to tell the doorman twice

---

### 💡 Real-World Example:

```
Scenario: Web Server receiving HTTPS requests

Security Group Configuration:
┌──────────────────────────────────────┐
│  Inbound Rules:                      │
│  ├── HTTPS (443) from 0.0.0.0/0  ✅  │
│                                      │
│  Outbound Rules:                     │
│  ├── (Can be completely empty!)      │
└──────────────────────────────────────┘

Traffic Flow:

1. User Request (Inbound):
   User (203.0.113.5:52000) → Server (54.x.x.x:443)
   ✅ Allowed by inbound rule
   Security Group TRACKS this connection

2. Server Response (Outbound):
   Server (54.x.x.x:443) → User (203.0.113.5:52000)
   ✅ Automatically allowed (Security Group remembers step 1)
   NO outbound rule needed!

3. More User Requests (same connection):
   User → Server
   ✅ Automatically allowed (same connection state)

4. Server Responses:
   Server → User
   ✅ Automatically allowed (still same connection)
```

---

### 🎯 Interview Follow-up Questions:

**Q: "So we don't need any outbound rules?"**

**A:** "Not for return traffic, but you DO need outbound rules if your instance initiates NEW connections outbound."

```
Example: Your server needs to call external API

Security Group needs:
Inbound: HTTPS (443) from users
Outbound: HTTPS (443) to 0.0.0.0/0  ← For API calls YOU initiate

Why?
- User → Your server = Return traffic auto-allowed ✅
- Your server → External API = NEW connection, needs outbound rule ✅
```

---

**Q: "What's the benefit of stateful over stateless?"**

**A:**
```
Benefits of Stateful (Security Groups):
✅ Simpler configuration (fewer rules)
✅ Less chance of misconfiguration
✅ Automatically handles return traffic
✅ Tracks connection state (more intelligent)
✅ Perfect for most use cases

Drawbacks:
❌ Less granular control
❌ Can't explicitly deny return traffic
```

---

**Q: "Can you give an example where stateful behavior prevents problems?"**

**A:**
```
Problem with Stateless (NACL):

NACL Inbound: Allow HTTPS (443)
NACL Outbound: Forgot ephemeral ports (1024-65535)
Result: ❌ Users can't get responses!

Why? Responses use ephemeral ports (e.g., 52000)
Without outbound rule for ephemeral ports → Blocked

With Stateful (Security Group):

SG Inbound: Allow HTTPS (443)
SG Outbound: Empty
Result: ✅ Everything works!

Why? Security Group automatically allows responses
No need to worry about ephemeral ports
```

---

### 📊 Comparison: Stateful vs Stateless

| Aspect | Stateful (SG) | Stateless (NACL) |
|--------|--------------|------------------|
| **Remembers connections** | Yes ✅ | No ❌ |
| **Return traffic** | Auto-allowed | Must explicitly allow |
| **Rules needed** | Fewer | More |
| **Ephemeral ports** | Auto-handled | Must manually configure |
| **Complexity** | Simple | Complex |
| **Use case** | Normal operations | Advanced control |

---

### ✅ Key Points for Interview:

1. ✅ Security Groups are **stateful** - they track connection state
2. ✅ Return traffic is **automatically allowed**
3. ✅ **No need** for explicit outbound rules for responses
4. ✅ Simpler than stateless firewalls
5. ✅ But **do need** outbound rules if instance initiates connections

---

## ❓ Question 2: Which takes priority — Security Group or NACL?

### 📖 Answer:

**NACL takes priority (geographically), but BOTH must allow traffic for it to pass.**

### 🔍 Detailed Explanation:

**The correct way to think about it:**

```
It's not about "priority" - it's about ORDER of evaluation:

NACL = First checkpoint (subnet boundary)
Security Group = Second checkpoint (instance level)

BOTH must allow traffic for it to reach the instance.
```

---

### 💡 Traffic Flow:

```
INBOUND Traffic (Internet → EC2):

Internet
   ↓
┌──────────────────────────┐
│  Step 1: NACL            │
│  (Subnet boundary)       │
│  Checks inbound rules    │
└──────┬───────────────────┘
       │ If ALLOWED ✅
       ▼
┌──────────────────────────┐
│  Step 2: Security Group  │
│  (Instance level)        │
│  Checks inbound rules    │
└──────┬───────────────────┘
       │ If ALLOWED ✅
       ▼
┌──────────────────────────┐
│  EC2 Instance            │
└──────────────────────────┘

If NACL denies → Traffic never reaches Security Group
If NACL allows but SG denies → Traffic blocked at SG
Both must allow → Traffic reaches EC2

OUTBOUND Traffic (EC2 → Internet):

EC2 Instance
   ↓
Security Group (outbound rules)
   ↓ If ALLOWED
NACL (outbound rules)
   ↓ If ALLOWED
Internet
```

---

### 🎯 Real-World Scenarios:

#### Scenario 1: NACL Denies, SG Allows

```
NACL Inbound:
Rule #50: DENY TCP 22 from 203.0.113.5/32 ❌
Rule #100: ALLOW TCP 22 from 0.0.0.0/0

Security Group Inbound:
SSH (22) from 0.0.0.0/0 ✅

Test: SSH from 203.0.113.5
Result: ❌ BLOCKED

Why? NACL blocked it at subnet boundary.
Security Group never even evaluated.
```

#### Scenario 2: NACL Allows, SG Denies

```
NACL Inbound:
Rule #100: ALLOW TCP 80 from 0.0.0.0/0 ✅

Security Group Inbound:
(No HTTP rule) = DENY by default ❌

Test: HTTP access
Result: ❌ BLOCKED

Why? NACL allowed it through subnet,
but Security Group blocked at instance level.
```

#### Scenario 3: Both Allow

```
NACL Inbound:
Rule #100: ALLOW TCP 443 from 0.0.0.0/0 ✅

Security Group Inbound:
HTTPS (443) from 0.0.0.0/0 ✅

Test: HTTPS access
Result: ✅ WORKS

Why? Both checkpoints allowed the traffic.
```

---

### 🎯 Interview Follow-up Questions:

**Q: "So which one should I use?"**

**A:**
```
Use BOTH together (defense in depth):

Security Group (Primary):
└── Use for normal access control (99% of rules)
    Examples: Allow HTTP, SSH from specific IPs

Network ACL (Secondary):
└── Use for blocking bad actors or compliance
    Examples: Block known attacker IPs

Why both?
✅ Two independent layers of security
✅ NACL catches threats at subnet level (efficient)
✅ SG provides fine-grained instance control
✅ Attacker must bypass BOTH
```

---

**Q: "Can NACL override Security Group?"**

**A:** "No, it's not about 'override' - think of them as two separate gates:"

```
Analogy: Gated Community + House Security

NACL = Community Gate (suburb boundary)
├── Blocks unwanted visitors at entrance
├── Everyone in suburb affected
└── First line of defense

Security Group = House Alarm (individual house)
├── Additional protection for your house
├── Only affects your house
└── Second line of defense

To reach your house, visitors must:
1. Pass community gate (NACL) ✅
2. Pass house alarm (SG) ✅

Community gate DOESN'T override house alarm.
Both are independent security layers.
```

---

**Q: "What if they conflict?"**

**A:** "The most restrictive rule wins (Deny wins)"

```
Examples:

NACL: ALLOW port 22
SG: DENY port 22 (implicit - no allow rule)
Result: ❌ Denied (one deny = blocked)

NACL: DENY port 80
SG: ALLOW port 80
Result: ❌ Denied (NACL blocks first)

NACL: ALLOW port 443
SG: ALLOW port 443
Result: ✅ Allowed (both allow)

Rule: Traffic must pass BOTH checkpoints.
If either denies → Traffic blocked.
```

---

### 📊 Evaluation Order Table:

| Traffic | NACL | Security Group | Result | Reason |
|---------|------|----------------|--------|--------|
| HTTP | ALLOW | ALLOW | ✅ Allowed | Both allow |
| SSH | DENY | ALLOW | ❌ Blocked | NACL denied first |
| HTTPS | ALLOW | DENY | ❌ Blocked | SG denied second |
| MySQL | DENY | DENY | ❌ Blocked | Both deny |

---

### ✅ Key Points for Interview:

1. ✅ NACL is evaluated **first** (subnet boundary)
2. ✅ Security Group is evaluated **second** (instance level)
3. ✅ **BOTH must allow** for traffic to pass
4. ✅ It's not "priority" - it's **layers of security**
5. ✅ Use **both together** for defense in depth
6. ✅ Most restrictive rule wins (deny blocks traffic)

---

## ❓ Question 3: Can you block specific IPs using Security Groups?

### 📖 Answer:

**NO, you cannot explicitly block (deny) specific IPs using Security Groups.**

**Reason:** Security Groups only have ALLOW rules, no DENY rules.

**Solution:** Use Network ACLs to block specific IPs.

---

### 🔍 Detailed Explanation:

#### Why Security Groups Can't Block Specific IPs:

```
Security Group Rule Types:

✅ Can say: "ALLOW 203.0.113.5"
✅ Can say: "ALLOW 0.0.0.0/0" (everyone)
❌ Cannot say: "DENY 203.0.113.5"
❌ Cannot say: "DENY ANY IP"

Design Philosophy:
├── Security Groups are "whitelist only"
├── Everything denied by default
└── You explicitly allow what you want

No deny rules = Cannot explicitly block
```

---

#### Attempted Workarounds (Don't work!):

**❌ Workaround 1: "Just don't allow the IP"**

```
Problem:

Security Group:
└── Allow SSH (22) from 0.0.0.0/0

Goal: Block 203.0.113.5

Attempted Fix:
└── Allow SSH (22) from 0.0.0.0/0
    (Try to "not include" 203.0.113.5)

Result: ❌ Doesn't work!

Why? 0.0.0.0/0 = ALL IPs including 203.0.113.5
You cannot exclude one IP from "all IPs" in SG
```

**❌ Workaround 2: "Allow everyone except one IP"**

```
Attempted Fix:
├── Allow SSH from 0.0.0.0 - 203.0.113.4
├── Allow SSH from 203.0.113.6 - 255.255.255.255

Result: ❌ Too complex and still doesn't work perfectly

Why?
- Need hundreds of CIDR blocks
- Easy to miss ranges
- Hits rule limits (60 rules max)
- Unmaintainable
```

---

#### ✅ Correct Solution: Use Network ACL

```
Network ACL Configuration:

Inbound Rules:
Rule #10: DENY ALL from 203.0.113.5/32  ← Block specific IP
Rule #100: ALLOW TCP 22 from 0.0.0.0/0  ← Allow everyone else
Rule #*: DENY ALL (default)

How it works:
1. Traffic from 203.0.113.5 arrives
2. NACL checks rule #10 first → DENY ✅
3. Traffic blocked at subnet boundary
4. Never reaches Security Group
5. Never reaches EC2 instance

Perfect solution! ✅
```

---

### 💡 Real-World Scenario:

**Problem:**
```
Situation:
└── Hacker at IP 198.51.100.50 attacking your server
└── Making thousands of SSH attempts
└── Need to block immediately

Can't use Security Group because:
❌ SG only has allow rules
❌ Your SSH rule allows 0.0.0.0/0
❌ Can't exclude one IP from 0.0.0.0/0
```

**Solution:**
```
Step 1: Create NACL rule
├── Rule #10: DENY ALL from 198.51.100.50/32
└── Takes effect immediately (< 1 second)

Step 2: Hacker blocked at subnet level
├── Before reaching Security Group
├── Before consuming instance resources
└── Entire subnet protected

Step 3: Monitor and adjust
├── Add more IPs if needed
├── Remove rule when threat passes
└── Keep Security Group unchanged
```

---

### 🎯 Interview Follow-up Questions:

**Q: "Why did AWS design Security Groups without deny rules?"**

**A:**
```
AWS Design Philosophy:

1. Principle of Least Privilege:
   └── "Deny by default, allow explicitly"
   └── Nothing works unless you explicitly allow it
   └── Safer: Accidental exposure less likely

2. Simplicity:
   └── One rule type (ALLOW) = Easier to understand
   └── Less confusion than mixing ALLOW and DENY
   └── Fewer configuration errors

3. Stateful Benefit:
   └── Automatically handles return traffic
   └── Don't need ALLOW + DENY for same connection

4. Separation of Concerns:
   └── Security Groups = Positive control ("who CAN access")
   └── Network ACLs = Negative control ("who CAN'T access")
   └── Use right tool for right job

Result:
✅ Security Groups for normal operations
✅ Network ACLs for blocking bad actors
✅ Clearer security architecture
```

---

**Q: "When would I need to block specific IPs?"**

**A:**
```
Common Scenarios:

1. DDoS Attack:
   └── Attacker IP or range attacking your server
   └── Block at NACL immediately

2. Brute Force Attempts:
   └── Multiple failed SSH login attempts from one IP
   └── Block to prevent account compromise

3. Malicious Traffic:
   └── Known botnet IPs
   └── Threat intelligence feeds
   └── Block proactively

4. Compliance Requirements:
   └── Restrict access to certain countries
   └── Geo-blocking for regulatory compliance

5. Internal Policy:
   └── Block former employee's home IP
   └── Block contractor after project ends

Solution for all: Network ACL DENY rules ✅
```

---

**Q: "What if I need to block hundreds of IPs?"**

**A:**
```
Strategies:

1. Network ACL (up to 20 rules by default):
   ├── Request limit increase from AWS
   ├── Can go up to 40 inbound + 40 outbound
   └── Use CIDR blocks to cover ranges

2. AWS WAF (Web Application Firewall):
   ├── Attach to ALB, API Gateway, or CloudFront
   ├── Can block thousands of IPs
   ├── Advanced rules (rate limiting, geo-blocking)
   ├── Integration with threat intelligence
   └── Best for web applications

3. AWS Shield (DDoS Protection):
   ├── Automatic DDoS protection
   ├── Shield Standard (free)
   ├── Shield Advanced (paid, 24/7 response team)
   └── Best for DDoS scenarios

4. Third-party Security Groups:
   ├── Use AWS Firewall Manager
   ├── Centralized security policy
   └── Manage across multiple accounts

For web traffic: WAF > NACL
For non-web traffic: NACL + Shield
For massive scale: Combination of all
```

---

### 📊 Blocking Methods Comparison:

| Method | Can Block IP? | Max IPs | Use Case | Cost |
|--------|---------------|---------|----------|------|
| **Security Group** | ❌ No | N/A | Normal access control | Free |
| **Network ACL** | ✅ Yes | ~20-40 IPs | Block specific attackers | Free |
| **AWS WAF** | ✅ Yes | Thousands | Web application protection | ~$5-10/month base |
| **AWS Shield** | ✅ Yes | Automatic | DDoS protection | Standard: Free<br>Advanced: $3,000/month |

---

### ✅ Key Points for Interview:

1. ❌ Security Groups **cannot** block specific IPs
2. ✅ Security Groups only have **ALLOW** rules (no DENY)
3. ✅ Use **Network ACLs** to block specific IPs
4. ✅ NACL blocks at **subnet level** (before reaching SG)
5. ✅ For web apps, consider **AWS WAF** for advanced blocking
6. ✅ Design philosophy: SG = allow, NACL = deny

---

## ❓ Question 4: What is the default behavior of Security Groups?

### 📖 Answer:

**Default Behavior:**
- **Inbound:** Deny ALL traffic (implicit)
- **Outbound:** Allow ALL traffic to 0.0.0.0/0 (explicit default rule)

### 🔍 Detailed Explanation:

```
When you create a new Security Group:

Inbound Rules:
└── (EMPTY) = Deny everything
    No traffic can reach instance by default

Outbound Rules:
└── Rule: All traffic to 0.0.0.0/0
    Instance can reach anywhere by default
```

---

### 💡 Why This Design?

**1. Security by Default (Inbound):**
```
Problem without default deny:
└── New EC2 instance exposed to internet
└── All ports open = Immediate attack
└── Database, SSH, everything accessible

Solution with default deny:
└── New EC2 instance isolated
└── Must explicitly allow traffic
└── Intentional security configuration
└── Prevents accidental exposure

Result: ✅ Secure by default!
```

**2. Convenience (Outbound):**
```
Why allow all outbound by default:

Instances need to:
├── Download security updates (HTTPS)
├── Install packages (HTTP/HTTPS)
├── Call AWS APIs
├── Reach internet services
└── Function normally

If outbound denied by default:
├── Updates wouldn't work
├── Packages couldn't install
├── AWS CLI wouldn't work
└── New users frustrated

Result: ✅ Functional by default!
```

---

### 📊 Default SG vs Modified SG:

| Aspect | Default (New) SG | After You Configure |
|--------|------------------|---------------------|
| **Inbound** | Deny all (implicit) | Allow specific (explicit) |
| **Outbound** | Allow all (explicit) | Usually keep allow all |
| **Effect** | Instance isolated | Instance accessible as configured |

---

**Key Interview Point:**
> "Security Groups follow the principle of '**Deny by default, allow explicitly**' for inbound traffic, ensuring security. Outbound is permissive by default for operational convenience."

---

## ❓ Question 5: Can you attach multiple Security Groups to one EC2 instance?

### 📖 Answer:

**YES! You can attach up to 5 Security Groups per EC2 instance (per ENI).**

### 🔍 How It Works:

```
All rules from all attached Security Groups are COMBINED:

EC2 Instance
├── SG-1: web-server-sg
│   ├── Allow HTTP (80) from 0.0.0.0/0
│   └── Allow HTTPS (443) from 0.0.0.0/0
│
├── SG-2: ssh-access-sg
│   └── Allow SSH (22) from 10.0.0.0/16
│
└── SG-3: database-client-sg
    └── Allow MySQL (3306) to sg-database

Combined Effect:
├── HTTP (80) from 0.0.0.0/0 ✅
├── HTTPS (443) from 0.0.0.0/0 ✅
├── SSH (22) from 10.0.0.0/16 ✅
└── MySQL (3306) to sg-database ✅

Rule: If ANY Security Group allows traffic → ALLOWED
```

---

### 💡 Use Cases:

**1. Role-based Access:**
```
Base SG for all instances:
├── monitoring-sg (CloudWatch agent access)
├── backup-sg (backup service access)
└── admin-sg (SSH from bastion)

Application-specific SG:
├── web-servers: Add web-server-sg
├── databases: Add database-sg
└── workers: Add worker-sg

Benefits:
✅ Reusable security rules
✅ Easier management
✅ Consistent security policies
```

**2. Separation of Concerns:**
```
Instance with 3 SGs:
├── network-sg: Network-level rules
├── application-sg: App-specific rules
└── compliance-sg: Audit requirements

Different teams manage different SGs:
├── Network team → network-sg
├── Dev team → application-sg
└── Security team → compliance-sg
```

---

### ✅ Key Points for Interview:

1. ✅ **Up to 5 Security Groups** per instance (per ENI)
2. ✅ Rules are **combined** (aggregated)
3. ✅ If **ANY** SG allows → Traffic allowed
4. ✅ Use for **modular security** configuration
5. ✅ Better than one huge Security Group

---

## ❓ Question 6: What are ephemeral ports and why do they matter for NACLs?

### 📖 Answer:

**Ephemeral ports are temporary ports (1024-65535) used for return traffic in TCP/UDP connections.**

**Why they matter:** Network ACLs (stateless) must explicitly allow ephemeral ports for return traffic to work.

---

### 🔍 Detailed Explanation:

**How Connections Work:**

```
Client → Server Connection:

Step 1: Client Initiates
├── Source: Client IP, Port 52000 (ephemeral)
│           ↑ Randomly chosen by OS
├── Destination: Server IP, Port 443 (well-known)
└── Request: "GET /index.html"

Step 2: Server Responds
├── Source: Server IP, Port 443 (well-known)
├── Destination: Client IP, Port 52000 (ephemeral)
│                        ↑ Same port client used
└── Response: "Here's your webpage"

Key Point: Response goes to EPHEMERAL PORT (52000)
```

---

### 🚨 Problem with NACLs (Stateless):

```
NACL Inbound:
Rule #100: Allow TCP 443 from 0.0.0.0/0 ✅

NACL Outbound:
Rule #100: Allow TCP 443 to 0.0.0.0/0 ❌ WRONG!

What happens:
1. Request IN: Port 443 ✅ Allowed
2. Response OUT: Port 52000 ❌ BLOCKED!

Why? Outbound rule only allows port 443,
but response uses ephemeral port 52000!

Result: Connection hangs, no response received
```

---

### ✅ Correct NACL Configuration:

```
NACL Outbound:
Rule #100: Allow TCP 1024-65535 to 0.0.0.0/0 ✅ CORRECT!
           ↑ Ephemeral port range

Now:
1. Request IN: Port 443 ✅ Allowed
2. Response OUT: Port 52000 ✅ Allowed (in ephemeral range)

Result: Connection works! ✅
```

---

### 📊 Ephemeral Port Ranges by OS:

| Operating System | Ephemeral Port Range | AWS Recommendation |
|------------------|---------------------|-------------------|
| Linux (modern) | 32768-60999 | Use 1024-65535 |
| Windows Server | 49152-65535 | Use 1024-65535 |
| AWS NAT Gateway | 1024-65535 | Use 1024-65535 |
| Old Linux | 1024-4999 | Use 1024-65535 |

**AWS Best Practice:** Use 1024-65535 (covers all scenarios)

---

### ✅ Key Points for Interview:

1. ✅ Ephemeral ports = **Temporary return ports** (1024-65535)
2. ✅ Security Groups (stateful) **handle automatically**
3. ❌ Network ACLs (stateless) **must explicitly allow**
4. ✅ AWS recommends: **Allow 1024-65535** outbound in NACL
5. ✅ Forgetting ephemeral ports = **Broken connections**

---

## ❓ Question 7: How quickly do Security Group changes take effect?

### 📖 Answer:

**Security Group changes take effect IMMEDIATELY (within seconds) without restarting instances.**

### 🔍 Key Points:

```
Characteristics:
✅ No instance restart required
✅ No downtime
✅ Applies to existing connections (usually)
✅ Changes propagate in < 1 second typically
✅ No additional cost

Example:
1. 10:00 AM: Add HTTP rule to SG
2. 10:00:01 AM: Rule active
3. Immediate: Users can access on port 80

No waiting, no restart, no downtime! ✅
```

---

### 💡 Real-World Use:

**Emergency Security Response:**
```
Scenario: Attack detected on port 8080

10:00:00 - Attack detected
10:00:05 - Remove port 8080 rule from SG
10:00:06 - Traffic blocked immediately
10:00:10 - Attack mitigated

Total response time: 10 seconds
No service interruption for legitimate traffic
```

---

**Compare to Traditional Firewall:**
```
Traditional Firewall:
├── Update rules
├── Apply configuration
├── Reload firewall
├── Possible brief downtime
└── Time: Minutes

AWS Security Group:
├── Update rule in console
├── Immediate effect
└── Time: < 1 second ✅
```

---

### ✅ Interview Key Point:
> "Security Group changes are near-instantaneous, enabling rapid security responses without downtime or instance restarts."

---

## 🎓 Bonus Interview Questions

### ❓ Q8: What's the difference between Security Group and Firewall?

**Answer:**
```
Security Group = Virtual firewall (software-defined)
Traditional Firewall = Physical/virtual appliance

Key Differences:

Security Group:
✅ AWS-managed (no maintenance)
✅ Instance-level (granular)
✅ Stateful (automatic return traffic)
✅ Changes instant
✅ Free
✅ Scales automatically
✅ No single point of failure

Traditional Firewall:
❌ You manage updates
❌ Network-level (coarse)
⚠️ Can be stateful or stateless
❌ Changes require reload
❌ Expensive
❌ Manual scaling
❌ Can fail

Security Group is superior for cloud ✅
```

---

### ❓ Q9: Can Security Groups span VPCs?

**Answer:**
```
❌ NO. Security Groups are VPC-specific.

Each VPC has its own Security Groups.
Cannot reference SG from different VPC.

Workaround:
1. VPC Peering + Reference CIDR blocks
2. Transit Gateway
3. PrivateLink
4. Duplicate SG in each VPC (manual)

Best Practice:
Use IaC (Terraform) to create identical SGs across VPCs
```

---

### ❓ Q10: What happens to existing connections when you remove a Security Group rule?

**Answer:**
```
Depends on protocol:

TCP Connections (established):
├── Usually continue working
├── Security Group remembers state
└── Existing SSH session survives

New Connections:
├── Immediately blocked
└── No new connections allowed

Best Practice:
- Remove rules during maintenance window
- Warn users of potential disruption
- Test in non-production first
```

---

## 📚 Interview Preparation Summary

### Must-Know Concepts:

1. ✅ **Stateful vs Stateless**
   - SG = Stateful (remembers connections)
   - NACL = Stateless (doesn't remember)

2. ✅ **Rule Types**
   - SG = ALLOW only
   - NACL = ALLOW and DENY

3. ✅ **Evaluation Order**
   - NACL first (subnet boundary)
   - SG second (instance level)
   - Both must allow

4. ✅ **Blocking IPs**
   - SG cannot block
   - NACL can block with DENY rules

5. ✅ **Default Behavior**
   - SG inbound: Deny all
   - SG outbound: Allow all
   - Secure by default

6. ✅ **Ephemeral Ports**
   - 1024-65535
   - Critical for NACL outbound rules
   - SG handles automatically

7. ✅ **Changes**
   - Take effect immediately
   - No restart needed
   - No downtime

---

### 🎯 Interview Success Tips:

1. **Use Analogies:** "Security Group is like a smart doorman..."
2. **Draw Diagrams:** Show traffic flow on whiteboard
3. **Give Examples:** Real-world scenarios demonstrate understanding
4. **Compare:** SG vs NACL table shows deep knowledge
5. **Best Practices:** Defense in depth, use both SG and NACL

---

**You're now ready to ace any Security Groups & NACLs interview! 🚀**
