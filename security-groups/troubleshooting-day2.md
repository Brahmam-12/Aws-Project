# DAY 2 - TROUBLESHOOTING GUIDE 🔧

## Security Groups & NACLs Debugging Reference

---

## 📋 Table of Contents

1. [Troubleshooting Decision Tree](#troubleshooting-decision-tree)
2. [Common Problem Scenarios](#common-problem-scenarios)
3. [Diagnostic Commands](#diagnostic-commands)
4. [Error Messages & Solutions](#error-messages--solutions)
5. [VPC Flow Logs Analysis](#vpc-flow-logs-analysis)

---

## 🌳 Troubleshooting Decision Tree

### Problem: Cannot Connect to EC2 Instance

```
START: Can't connect to EC2 instance
   ↓
Is the instance running?
├── NO → Start the instance ✅
└── YES → Continue
   ↓
Can you ping the instance?
├── NO → Check ICMP rules (see below)
└── YES → Continue
   ↓
Is it a public instance (public IP)?
├── YES → Check public connectivity (Branch A)
└── NO → Check private connectivity (Branch B)

BRANCH A: Public Instance
   ↓
Does Security Group allow your IP?
├── NO → Add inbound rule for your IP ✅
└── YES → Continue
   ↓
Does NACL allow your IP?
├── NO → Add NACL rule ✅
└── YES → Continue
   ↓
Does instance have public IP?
├── NO → Attach Elastic IP or recreate with public IP ✅
└── YES → Continue
   ↓
Is Internet Gateway attached?
├── NO → Attach IGW to VPC ✅
└── YES → Continue
   ↓
Does route table have IGW route?
├── NO → Add 0.0.0.0/0 → IGW route ✅
└── YES → Check VPC Flow Logs (rejected packets?)

BRANCH B: Private Instance
   ↓
Are you connecting from bastion/VPN?
├── NO → Must use bastion or VPN ✅
└── YES → Continue
   ↓
Does Security Group allow bastion SG?
├── NO → Add bastion SG to inbound rules ✅
└── YES → Continue
   ↓
Does NACL allow bastion subnet?
├── NO → Add NACL rule for bastion subnet ✅
└── YES → Check VPC Flow Logs
```

---

## 🚨 Common Problem Scenarios

### Problem 1: "Connection Timed Out"

**Symptom:**
```bash
$ ssh ec2-user@54.x.x.x
ssh: connect to host 54.x.x.x port 22: Connection timed out
```

**What it means:** Traffic is being **silently dropped** (no response)

**Likely Causes:**
1. ❌ Security Group doesn't have SSH rule
2. ❌ NACL is blocking inbound
3. ❌ No route to instance (route table issue)
4. ❌ Instance not running

**NOT the cause:**
- ✅ Wrong username (would get "Permission denied")
- ✅ Wrong key (would get "Permission denied")

---

#### Solution Steps:

**Step 1: Check Security Group**
```bash
# AWS Console
EC2 → Instances → Select instance → Security tab
├── Look for inbound rule: SSH (22) from your IP
│
# AWS CLI
aws ec2 describe-security-groups \
  --group-ids sg-xxxxxxxxx \
  --query 'SecurityGroups[0].IpPermissions'

Expected output:
[
  {
    "FromPort": 22,
    "ToPort": 22,
    "IpProtocol": "tcp",
    "IpRanges": [
      {
        "CidrIp": "YOUR-IP/32"
      }
    ]
  }
]

Fix if missing:
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 22 \
  --cidr YOUR-IP/32
```

**Step 2: Check NACL**
```bash
# Find subnet NACL
aws ec2 describe-network-acls \
  --filters "Name=association.subnet-id,Values=subnet-xxxxxx"

# Check inbound rules
Look for:
├── Rule allowing TCP 22 from your IP
└── Rule allowing ephemeral ports (1024-65535) for responses

Fix if missing:
aws ec2 create-network-acl-entry \
  --network-acl-id acl-xxxxxxxx \
  --rule-number 100 \
  --protocol tcp \
  --port-range From=22,To=22 \
  --cidr-block YOUR-IP/32 \
  --ingress \
  --rule-action allow
```

**Step 3: Check Route Table**
```bash
# AWS Console
VPC → Subnets → Select subnet → Route table tab

Expected routes:
├── 10.0.0.0/16 → local
└── 0.0.0.0/0 → igw-xxxxxxxx (for public subnet)

# AWS CLI
aws ec2 describe-route-tables \
  --route-table-ids rtb-xxxxxxxx \
  --query 'RouteTables[0].Routes'

Fix if IGW route missing:
aws ec2 create-route \
  --route-table-id rtb-xxxxxxxx \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-xxxxxxxx
```

---

### Problem 2: "Connection Refused"

**Symptom:**
```bash
$ ssh ec2-user@54.x.x.x
ssh: connect to host 54.x.x.x port 22: Connection refused
```

**What it means:** Traffic reaches instance, but service **actively rejects** connection

**Likely Causes:**
1. ❌ SSH service not running on instance
2. ❌ SSH listening on different port
3. ❌ Instance firewall blocking (iptables)

**NOT the cause:**
- ✅ Security Group (would timeout, not refuse)
- ✅ NACL (would timeout, not refuse)

---

#### Solution Steps:

**Step 1: Check SSH Service Status**
```bash
# Connect via Session Manager or console
aws ssm start-session --target i-xxxxxxxxx

# Check SSH status
sudo systemctl status sshd

Expected output:
Active: active (running)

Fix if not running:
sudo systemctl start sshd
sudo systemctl enable sshd
```

**Step 2: Check SSH Configuration**
```bash
# Check what port SSH is listening on
sudo netstat -tlnp | grep sshd

Expected output:
tcp  0  0  0.0.0.0:22  0.0.0.0:*  LISTEN  1234/sshd

If listening on different port (e.g., 2222):
└── Update Security Group to allow port 2222 instead of 22

# Check SSH config file
sudo cat /etc/ssh/sshd_config | grep Port
Port 22  ← Should be 22
```

**Step 3: Check Instance Firewall**
```bash
# Check iptables rules
sudo iptables -L -n -v

Look for rules blocking port 22

# If firewall blocking, add rule
sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT
sudo service iptables save

# Better: Disable iptables on AWS (Security Groups handle it)
sudo systemctl stop iptables
sudo systemctl disable iptables
```

---

### Problem 3: "Permission Denied (publickey)"

**Symptom:**
```bash
$ ssh ec2-user@54.x.x.x
Permission denied (publickey).
```

**What it means:** Connection successful, but **authentication failed**

**Likely Causes:**
1. ❌ Using wrong SSH key
2. ❌ Using wrong username
3. ❌ Key permissions too open (chmod issue)

**NOT the cause:**
- ✅ Security Group (connection successful = SG/NACL working)

---

#### Solution Steps:

**Step 1: Verify Correct Username**
```bash
Common usernames by AMI:
├── Amazon Linux 2: ec2-user
├── Ubuntu: ubuntu
├── Debian: admin
├── RHEL: ec2-user
└── CentOS: centos

Try:
ssh -i mykey.pem ubuntu@54.x.x.x  ← Ubuntu
ssh -i mykey.pem ec2-user@54.x.x.x  ← Amazon Linux
```

**Step 2: Verify Correct Key**
```bash
# Check which key was used to launch instance
aws ec2 describe-instances \
  --instance-ids i-xxxxxxxxx \
  --query 'Reservations[0].Instances[0].KeyName'

Output: "my-keypair"

# Use that specific key
ssh -i ~/.ssh/my-keypair.pem ec2-user@54.x.x.x
```

**Step 3: Fix Key Permissions**
```bash
# Key must have restrictive permissions
chmod 400 mykey.pem

# Verify
ls -l mykey.pem
-r-------- 1 user user 1675 Jan 1 10:00 mykey.pem
          ↑ Should be 400 or 600
```

---

### Problem 4: "Can SSH but Can't Access Application"

**Symptom:**
```bash
# SSH works
ssh ec2-user@54.x.x.x  ✅ Works

# But HTTP doesn't work
curl http://54.x.x.x
curl: (7) Failed to connect to 54.x.x.x port 80: Connection timed out
```

**What it means:** SSH allowed, but HTTP port blocked

---

#### Solution Steps:

**Step 1: Verify Application Running**
```bash
# SSH to instance
ssh ec2-user@54.x.x.x

# Check if web server running
sudo systemctl status httpd  # Amazon Linux
sudo systemctl status nginx  # Nginx
sudo systemctl status apache2  # Ubuntu

# Check what port application listening on
sudo netstat -tlnp | grep LISTEN

Example output:
tcp  0  0  0.0.0.0:80  0.0.0.0:*  LISTEN  5678/httpd
                   ↑ Application listening on port 80 ✅

If not listening on 0.0.0.0:
└── Application only listening on localhost (127.0.0.1)
└── Fix application config to listen on 0.0.0.0
```

**Step 2: Add HTTP Rule to Security Group**
```bash
# AWS Console
EC2 → Security Groups → Select SG → Inbound rules → Edit
Add rule:
├── Type: HTTP
├── Port: 80
├── Source: 0.0.0.0/0 (or your IP/32)

# AWS CLI
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

**Step 3: Check NACL**
```bash
# Verify NACL allows HTTP
NACL Inbound:
├── Rule #100: Allow TCP 80 from 0.0.0.0/0
└── If missing, add rule

NACL Outbound:
├── Rule #100: Allow TCP 1024-65535 to 0.0.0.0/0
│                     ↑ Ephemeral ports for HTTP responses
└── Critical: Don't forget ephemeral ports!
```

---

### Problem 5: "Private Instance Can't Reach Internet"

**Symptom:**
```bash
# From private instance
curl https://google.com
curl: (6) Could not resolve host: google.com

# Or
ping 8.8.8.8
Request timeout
```

**What it means:** Private instance can't reach internet for updates/packages

---

#### Solution Steps:

**Step 1: Verify NAT Gateway Exists**
```bash
# AWS Console
VPC → NAT Gateways

Check:
├── Status: Available ✅
├── State: Available ✅
├── Elastic IP: Assigned ✅
└── Subnet: Public subnet ✅

# AWS CLI
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=vpc-xxxxxxxx"

Expected:
"State": "available"
```

**Step 2: Check Private Subnet Route Table**
```bash
# AWS Console
VPC → Subnets → Select private subnet → Route table tab

Expected routes:
├── 10.0.0.0/16 → local
└── 0.0.0.0/0 → nat-xxxxxxxx  ← NAT Gateway

# AWS CLI
aws ec2 describe-route-tables \
  --route-table-ids rtb-private \
  --query 'RouteTables[0].Routes'

If NAT route missing:
aws ec2 create-route \
  --route-table-id rtb-private \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id nat-xxxxxxxx
```

**Step 3: Check Security Group Outbound Rules**
```bash
# Instance Security Group must allow outbound
Outbound rules:
├── Type: All traffic (or HTTPS 443)
├── Destination: 0.0.0.0/0
└── Purpose: Allow internet access via NAT

# If missing, add
aws ec2 authorize-security-group-egress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```

**Step 4: Check NACL Outbound Rules**
```bash
# NACL for private subnet
Outbound rules:
├── Rule #100: Allow TCP 443 to 0.0.0.0/0 (HTTPS)
├── Rule #110: Allow TCP 80 to 0.0.0.0/0 (HTTP)
└── Rule #*: Deny all

# Also check INBOUND for responses
Inbound rules:
├── Rule #120: Allow TCP 1024-65535 from 0.0.0.0/0
│                     ↑ Ephemeral ports for HTTPS responses
└── Critical!
```

**Step 5: Test DNS Resolution**
```bash
# Check if DNS working
nslookup google.com

If fails:
├── Check /etc/resolv.conf
│   nameserver 10.0.0.2  ← VPC DNS (VPC CIDR +2)
│
└── Security Group must allow DNS
    ├── Outbound: UDP 53 to 10.0.0.2
    └── Or: All traffic to 0.0.0.0/0
```

---

### Problem 6: "NACL Rule Not Working"

**Symptom:**
```bash
# Added NACL rule to allow SSH
Rule #100: Allow TCP 22 from 203.0.113.5/32

# But still can't connect
ssh ec2-user@54.x.x.x
Connection timed out
```

**What it means:** NACL rules have order/priority issues

---

#### Solution Steps:

**Step 1: Check Rule Order**
```bash
# NACLs are evaluated in ORDER (lowest number first)

Problem Example:
Inbound rules:
├── Rule #50: DENY ALL from 203.0.113.0/24  ← Evaluated first
└── Rule #100: ALLOW TCP 22 from 203.0.113.5/32  ← Never reached!

Result: Traffic from 203.0.113.5 denied by rule #50

Fix: Lower the allow rule number
├── Rule #40: ALLOW TCP 22 from 203.0.113.5/32  ← Evaluated first ✅
└── Rule #50: DENY ALL from 203.0.113.0/24  ← Evaluated second

Result: 203.0.113.5 allowed, rest of /24 denied ✅
```

**Step 2: Check Ephemeral Ports (Outbound)**
```bash
# Common mistake: Forgot outbound ephemeral ports

NACL Inbound:
└── Rule #100: Allow TCP 22 from 203.0.113.5/32 ✅

NACL Outbound:
└── Rule #100: Allow TCP 22 to 203.0.113.5/32  ❌ WRONG!

Problem: SSH responses use ephemeral ports (e.g., 52000)
         not port 22!

Fix:
NACL Outbound:
└── Rule #100: Allow TCP 1024-65535 to 203.0.113.5/32 ✅
                      ↑ Ephemeral port range

Now SSH works! ✅
```

**Step 3: Verify NACL Association**
```bash
# Make sure NACL is associated with correct subnet

# AWS Console
VPC → Network ACLs → Select NACL → Subnet associations tab

# AWS CLI
aws ec2 describe-network-acls \
  --network-acl-ids acl-xxxxxxxx \
  --query 'NetworkAcls[0].Associations'

Expected:
"SubnetId": "subnet-xxxxxxxx"  ← Your subnet

If wrong subnet:
aws ec2 replace-network-acl-association \
  --association-id aclassoc-xxxxxxxx \
  --network-acl-id acl-xxxxxxxx
```

---

### Problem 7: "Security Group Rule Not Working"

**Symptom:**
```bash
# Added Security Group rule to allow HTTP
Inbound: HTTP (80) from 0.0.0.0/0

# But still can't access
curl http://54.x.x.x
Connection timed out
```

---

#### Solution Steps:

**Step 1: Verify Rule Applied to Correct SG**
```bash
# Check instance's Security Groups
aws ec2 describe-instances \
  --instance-ids i-xxxxxxxxx \
  --query 'Reservations[0].Instances[0].SecurityGroups'

Expected:
[
  {
    "GroupName": "web-server-sg",
    "GroupId": "sg-xxxxxxxxx"
  }
]

# Make sure you edited web-server-sg, not another SG!

If wrong SG:
aws ec2 modify-instance-attribute \
  --instance-id i-xxxxxxxxx \
  --groups sg-correct-sg-id
```

**Step 2: Check for Conflicting NACL Rules**
```bash
# Even with SG allowing, NACL can block

# Check NACL
NACL Inbound:
├── Rule #50: DENY TCP 80 from 0.0.0.0/0  ← Blocks
└── Rule #100: ALLOW ALL  ← Never reached

Solution: Remove DENY rule #50, or add specific ALLOW before it
```

**Step 3: Verify Application Listening**
```bash
# SSH to instance
ssh ec2-user@54.x.x.x

# Check if app running
sudo systemctl status httpd

# Check listening ports
sudo netstat -tlnp | grep :80

Expected:
tcp  0  0  0.0.0.0:80  0.0.0.0:*  LISTEN  1234/httpd

If not running:
sudo systemctl start httpd
sudo systemctl enable httpd
```

---

## 🔍 Diagnostic Commands

### Quick Diagnostic Checklist

```bash
# 1. Check instance status
aws ec2 describe-instance-status \
  --instance-ids i-xxxxxxxxx

# 2. Check Security Groups attached
aws ec2 describe-instances \
  --instance-ids i-xxxxxxxxx \
  --query 'Reservations[0].Instances[0].SecurityGroups'

# 3. Check Security Group rules
aws ec2 describe-security-groups \
  --group-ids sg-xxxxxxxxx

# 4. Check NACL for subnet
aws ec2 describe-network-acls \
  --filters "Name=association.subnet-id,Values=subnet-xxxxxxxx"

# 5. Check route table
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=subnet-xxxxxxxx"

# 6. Check Internet Gateway
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=vpc-xxxxxxxx"

# 7. Check NAT Gateway
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=vpc-xxxxxxxx"
```

---

### Testing Connectivity

```bash
# Test from your machine

# 1. TCP connection test (telnet)
telnet 54.x.x.x 22
Connected to 54.x.x.x  ← Port open ✅
Connection refused  ← Port closed (service issue) ❌
Connection timed out  ← Firewall blocking ❌

# 2. TCP connection test (nc/netcat)
nc -zv 54.x.x.x 80
Connection succeeded  ← Port open ✅
Connection refused  ← Port closed ❌
Connection timed out  ← Firewall blocking ❌

# 3. HTTP test (curl)
curl -v http://54.x.x.x
*   Trying 54.x.x.x:80...
* Connected to 54.x.x.x (54.x.x.x) port 80  ← Success ✅

# 4. Test specific source IP
curl --interface 203.0.113.5 http://54.x.x.x
↑ Test from specific IP (if you have multiple)

# 5. Test timeout quickly
curl --connect-timeout 5 http://54.x.x.x
↑ Fail after 5 seconds instead of waiting
```

---

### From Instance (SSH'd in)

```bash
# 1. Check what's listening
sudo netstat -tlnp

# 2. Check instance metadata (public IP)
curl http://169.254.169.254/latest/meta-data/public-ipv4

# 3. Check instance routes
ip route show

# 4. Check DNS resolution
nslookup google.com
dig google.com

# 5. Test outbound connectivity
curl https://google.com
ping 8.8.8.8

# 6. Check Security Group (from inside)
# Instance can see its own SG in metadata
curl http://169.254.169.254/latest/meta-data/security-groups

# 7. Test specific port outbound
nc -zv google.com 443

# 8. Check iptables (instance firewall)
sudo iptables -L -n -v
```

---

## 📊 VPC Flow Logs Analysis

### Enable VPC Flow Logs

```bash
# Create CloudWatch Log Group
aws logs create-log-group --log-group-name /aws/vpc/flowlogs

# Create IAM role for Flow Logs
# (see full policy in AWS docs)

# Enable Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-xxxxxxxx \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /aws/vpc/flowlogs \
  --deliver-logs-permission-arn arn:aws:iam::123456789012:role/flowlogsRole
```

---

### Reading Flow Logs

**Flow Log Format:**
```
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status
```

**Example Log Entry:**
```
2 123456789012 eni-abc123de 203.0.113.5 10.0.1.5 45000 22 6 10 5000 1609459200 1609459260 ACCEPT OK
```

**Breakdown:**
```
version: 2
account-id: 123456789012
interface-id: eni-abc123de
srcaddr: 203.0.113.5 (Source IP)
dstaddr: 10.0.1.5 (Destination IP)
srcport: 45000 (Source port - ephemeral)
dstport: 22 (Destination port - SSH)
protocol: 6 (TCP)
packets: 10
bytes: 5000
start: 1609459200 (Unix timestamp)
end: 1609459260
action: ACCEPT (Traffic allowed)
log-status: OK
```

---

### Common Flow Log Patterns

#### Pattern 1: Rejected by Security Group
```
action: REJECT
log-status: OK

Meaning: Traffic reached instance but Security Group blocked it
Solution: Add inbound rule to Security Group
```

#### Pattern 2: Rejected by NACL
```
action: REJECT
srcaddr: Attacker IP
dstaddr: Your instance IP

Meaning: NACL blocked at subnet boundary
Solution: Check if this is intentional (DDoS protection) or misconfiguration
```

#### Pattern 3: No Return Traffic
```
Outbound: ACCEPT
Inbound (response): REJECT

Meaning: Request sent, but response blocked
Common cause: Forgot ephemeral ports in NACL outbound
Solution: Add TCP 1024-65535 to NACL outbound rules
```

---

### Query Flow Logs

```bash
# AWS CloudWatch Logs Insights

# Find all rejected connections
fields @timestamp, srcAddr, dstAddr, dstPort, action
| filter action = "REJECT"
| sort @timestamp desc
| limit 100

# Find connections to specific port (e.g., SSH port 22)
fields @timestamp, srcAddr, dstAddr, action
| filter dstPort = 22
| filter action = "REJECT"
| stats count() by srcAddr
| sort count desc

# Find top talkers (most traffic)
fields @timestamp, srcAddr, dstAddr, bytes
| stats sum(bytes) as totalBytes by srcAddr
| sort totalBytes desc
| limit 20

# Find all traffic from specific IP
fields @timestamp, srcAddr, dstAddr, dstPort, action
| filter srcAddr = "203.0.113.5"
| sort @timestamp desc
```

---

## 🎯 Troubleshooting Flowchart Summary

```
Issue: Can't connect to instance
   ↓
Check instance running → Start if stopped
   ↓
Check public IP exists → Assign Elastic IP
   ↓
Check Security Group inbound → Add rule
   ↓
Check NACL inbound → Add rule
   ↓
Check NACL outbound ephemeral → Add 1024-65535
   ↓
Check route table → Add IGW or NAT route
   ↓
Check application running → Start service
   ↓
Check application listening → Fix config (0.0.0.0)
   ↓
Enable VPC Flow Logs → Analyze rejected packets
   ↓
Still not working? → AWS Support
```

---

## ✅ Pre-Flight Checklist (Before Asking for Help)

- [ ] Instance is running (not stopped/terminated)
- [ ] Instance has public IP (for public access)
- [ ] Security Group allows your IP/port
- [ ] NACL allows your IP/port (inbound)
- [ ] NACL allows ephemeral ports (outbound)
- [ ] Route table has IGW route (public) or NAT route (private)
- [ ] Internet Gateway attached to VPC
- [ ] Application service is running
- [ ] Application listening on 0.0.0.0 (not 127.0.0.1)
- [ ] Tested with telnet/nc to verify port open
- [ ] Checked VPC Flow Logs for rejected packets
- [ ] Tried from different source IP (rule specific network issue)

---

**🎓 You're now equipped to troubleshoot any Security Groups & NACLs issue! 🚀**
