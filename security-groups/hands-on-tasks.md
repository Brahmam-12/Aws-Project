# DAY 2 - HANDS-ON TASKS & PRACTICAL GUIDE 🛠️

## 📋 Part 4: Step-by-Step Hands-On Tasks

---

## Task 1: Create Security Group for EC2 (Allow Only Your IP)

### 🎯 Goal
Create a security group that allows SSH access ONLY from your IP address (maximum security).

### 📝 Steps:

#### 1. Get Your Public IP Address

**From your Windows machine:**
```powershell
# Method 1: Use curl
curl ifconfig.me

# Method 2: Visit in browser
# Go to: https://whatismyipaddress.com/
```

**Note your IP:** For example: `203.0.113.45`

---

#### 2. Create the Security Group

1. **Go to EC2 Console** → **Security Groups** (left sidebar under "Network & Security")

2. Click **"Create security group"**

3. **Basic Details:**
   ```
   Security group name:    ec2-admin-sg
   Description:            SSH access only from my IP
   VPC:                    Select your VPC (my-vpc-vpc or the one from Day 1)
   ```

4. **Inbound Rules** - Click "Add rule":

   **Rule 1: SSH Access**
   ```
   Type:        SSH
   Protocol:    TCP
   Port:        22
   Source:      My IP (AWS auto-detects) OR enter manually: 203.0.113.45/32
   Description: SSH from my home/office only
   ```

5. **Outbound Rules:**
   ```
   Leave default:
   Type:        All traffic
   Destination: 0.0.0.0/0
   ```
   
   **Why?** Instance needs to download updates, call APIs, respond to your SSH connection.

6. Click **"Create security group"**

---

#### 3. Test the Security Group

**Launch a test EC2 instance:**

1. **EC2 Console** → **Instances** → **Launch instances**

2. **Configure:**
   ```
   Name: test-ec2-secure
   AMI: Amazon Linux 2023
   Instance type: t2.micro
   Key pair: Your existing key pair
   
   Network settings:
   ├── VPC: Your VPC
   ├── Subnet: Public Subnet 1
   ├── Auto-assign public IP: Enable
   └── Security group: ec2-admin-sg ← The one you just created
   ```

3. **Launch instance**

4. **Test SSH from your machine:**
   ```powershell
   ssh -i your-key.pem ec2-user@<public-ip>
   ```
   
   ✅ **Should work!** (You're connecting from allowed IP)

5. **Test SSH from different IP (optional):**
   - Use mobile hotspot (different IP)
   - Try to SSH
   
   ❌ **Should timeout!** (Different IP blocked)

---

### ✅ Success Criteria:
- [ ] Can SSH from your IP
- [ ] Cannot SSH from different IP
- [ ] Instance can reach internet (outbound works)

---

## Task 2: Create Security Group for ALB (Allow Port 80 from All)

### 🎯 Goal
Create a security group for Application Load Balancer that accepts HTTP traffic from anywhere.

### 📝 Steps:

#### 1. Create ALB Security Group

1. **Security Groups** → **Create security group**

2. **Basic Details:**
   ```
   Security group name:    alb-public-sg
   Description:            Allow HTTP/HTTPS from internet
   VPC:                    Your VPC
   ```

3. **Inbound Rules** - Add 2 rules:

   **Rule 1: HTTP**
   ```
   Type:        HTTP
   Protocol:    TCP
   Port:        80
   Source:      0.0.0.0/0 (Anywhere IPv4)
   Description: Public HTTP traffic
   ```

   **Rule 2: HTTPS**
   ```
   Type:        HTTPS
   Protocol:    TCP
   Port:        443
   Source:      0.0.0.0/0 (Anywhere IPv4)
   Description: Public HTTPS traffic
   ```

4. **Outbound Rules:**
   ```
   Type:        HTTP
   Protocol:    TCP
   Port:        80
   Destination: Custom → We'll use a security group reference
   Description: Forward to web servers
   ```
   
   **Note:** We'll update this later to reference web server SG.

5. Click **"Create security group"**

---

#### 2. Create Web Server Security Group (for instances behind ALB)

1. **Create security group**

2. **Basic Details:**
   ```
   Security group name:    web-servers-sg
   Description:            Allow HTTP from ALB only
   VPC:                    Your VPC
   ```

3. **Inbound Rules:**

   **Rule 1: HTTP from ALB**
   ```
   Type:        HTTP
   Protocol:    TCP
   Port:        80
   Source:      Custom → Select "alb-public-sg"
                         ↑ Security group as source!
   Description: Accept traffic from ALB only
   ```

4. **Outbound Rules:** Leave default (all traffic)

5. Click **"Create security group"**

---

#### 3. Update ALB Security Group Outbound Rule

1. Go back to **alb-public-sg**
2. **Outbound rules** → **Edit outbound rules**
3. Update the rule:
   ```
   Type:        HTTP
   Protocol:    TCP
   Port:        80
   Destination: Select "web-servers-sg"
   Description: Forward to web servers
   ```
4. **Save rules**

---

#### 4. Architecture Result

```
Internet (0.0.0.0/0)
   ↓ HTTP/HTTPS
┌──────────────────────┐
│  ALB                 │
│  SG: alb-public-sg   │
│  IN: 80/443 from all │
│  OUT: 80 to web-sg   │
└──────────┬───────────┘
           │ HTTP (80)
           ▼
┌──────────────────────┐
│  Web Servers         │
│  SG: web-servers-sg  │
│  IN: 80 from alb-sg  │
└──────────────────────┘

Benefits:
✅ Web servers NOT directly accessible from internet
✅ Only ALB can reach web servers
✅ Web servers auto-scale → Still protected (SG reference)
✅ Security group chaining
```

---

### 🧪 Test (Optional - requires ALB setup):

1. Create Application Load Balancer with `alb-public-sg`
2. Create EC2 instances with `web-servers-sg`
3. Register instances with ALB
4. **Test 1:** Access ALB DNS → Should work ✅
5. **Test 2:** Access EC2 public IP directly → Should timeout ❌

---

## Task 3: Create NACL to Block Continuous Pings

### 🎯 Goal
Create a Network ACL that blocks ICMP (ping) from specific IP while allowing other traffic.

### 📝 Steps:

#### 1. Identify Target IP to Block

**Scenario:** A specific IP (203.0.113.100) is continuously pinging your server.

```
Attacker: 203.0.113.100
Action: Sending continuous ICMP pings (DDoS attempt)
Goal: Block this IP at subnet level
```

---

#### 2. Create Custom NACL

1. **VPC Console** → **Network ACLs** (left sidebar)

2. Click **"Create network ACL"**

3. **Configure:**
   ```
   Name: custom-nacl-block-ping
   VPC: Your VPC
   ```

4. Click **"Create network ACL"**

---

#### 3. Configure Inbound Rules

**Important:** Custom NACLs start with DENY ALL. We need to:
1. Deny the attacker
2. Allow legitimate traffic

1. Select your NACL → **Inbound rules** → **Edit inbound rules**

2. **Add rules in this order:**

   **Rule #10: Block the attacker**
   ```
   Rule number: 10
   Type:        Custom ICMP Rule - IPv4
   Protocol:    ICMP
   ICMP type:   Echo Request (8)
   Source:      203.0.113.100/32
   Allow/Deny:  DENY
   ```

   **Rule #100: Allow HTTP**
   ```
   Rule number: 100
   Type:        HTTP (80)
   Protocol:    TCP
   Port range:  80
   Source:      0.0.0.0/0
   Allow/Deny:  ALLOW
   ```

   **Rule #110: Allow HTTPS**
   ```
   Rule number: 110
   Type:        HTTPS (443)
   Protocol:    TCP
   Port range:  443
   Source:      0.0.0.0/0
   Allow/Deny:  ALLOW
   ```

   **Rule #120: Allow SSH**
   ```
   Rule number: 120
   Type:        SSH (22)
   Protocol:    TCP
   Port range:  22
   Source:      Your-IP/32
   Allow/Deny:  ALLOW
   ```

   **Rule #130: Allow ephemeral ports (return traffic)**
   ```
   Rule number: 130
   Type:        Custom TCP Rule
   Protocol:    TCP
   Port range:  1024-65535
   Source:      0.0.0.0/0
   Allow/Deny:  ALLOW
   ```

   **Rule #140: Allow ping from everyone else**
   ```
   Rule number: 140
   Type:        Custom ICMP Rule - IPv4
   Protocol:    ICMP
   ICMP type:   Echo Request (8)
   Source:      0.0.0.0/0
   Allow/Deny:  ALLOW
   ```

3. **Save changes**

---

#### 4. Configure Outbound Rules

1. **Outbound rules** → **Edit outbound rules**

2. **Add rules:**

   **Rule #100: Allow HTTP**
   ```
   Rule number: 100
   Type:        HTTP (80)
   Protocol:    TCP
   Port range:  80
   Destination: 0.0.0.0/0
   Allow/Deny:  ALLOW
   ```

   **Rule #110: Allow HTTPS**
   ```
   Rule number: 110
   Type:        HTTPS (443)
   Protocol:    TCP
   Port range:  443
   Destination: 0.0.0.0/0
   Allow/Deny:  ALLOW
   ```

   **Rule #120: Allow ephemeral ports (responses)**
   ```
   Rule number: 120
   Type:        Custom TCP Rule
   Protocol:    TCP
   Port range:  1024-65535
   Destination: 0.0.0.0/0
   Allow/Deny:  ALLOW
   ```

   **Rule #130: Allow ping responses**
   ```
   Rule number: 130
   Type:        Custom ICMP Rule - IPv4
   Protocol:    ICMP
   ICMP type:   Echo Reply (0)
   Destination: 0.0.0.0/0
   Allow/Deny:  ALLOW
   ```

3. **Save changes**

---

#### 5. Associate NACL with Subnet

1. **Subnet associations** tab
2. **Edit subnet associations**
3. **Select:** Public Subnet 1 (or your test subnet)
4. **Save changes**

---

#### 6. Test the NACL

**Setup test environment:**

1. Launch EC2 in the subnet with this NACL
2. Note the public IP: `54.x.x.x`

**Test from attacker IP (203.0.113.100):**
```bash
# If you can simulate from this IP
ping 54.x.x.x
# Result: ❌ Should timeout or show "Request timeout"
```

**Test from your IP (different IP):**
```bash
ping 54.x.x.x
# Result: ✅ Should work! Shows "64 bytes from..."
```

**Test HTTP access (from any IP including attacker):**
```bash
curl http://54.x.x.x
# Result: ✅ Should work (only ICMP blocked for attacker)
```

---

### 📊 How It Works:

```
Traffic from 203.0.113.100:

ICMP Ping:
→ NACL checks rules in order
→ Rule #10: DENY ICMP from 203.0.113.100 ✅ MATCH!
→ Denied immediately (rules #100-140 not checked)
Result: ❌ Ping blocked

HTTP Request:
→ NACL checks rules in order
→ Rule #10: No match (different protocol)
→ Rule #100: ALLOW HTTP ✅ MATCH!
→ Allowed immediately
Result: ✅ HTTP works

Traffic from other IPs:

ICMP Ping:
→ Rule #10: No match (different source IP)
→ Rule #100-130: No match (wrong protocol/port)
→ Rule #140: ALLOW ICMP ✅ MATCH!
→ Allowed
Result: ✅ Ping works
```

---

### ✅ Success Criteria:
- [ ] NACL created and associated with subnet
- [ ] Attacker IP (203.0.113.100) cannot ping
- [ ] Other IPs can ping normally
- [ ] HTTP/HTTPS traffic works for all
- [ ] SSH works from your IP

---

## Task 4: Launch EC2 and Test Everything

### 🎯 Goal
Launch EC2 instance with proper security groups and test all scenarios.

### 📝 Steps:

#### 1. Launch Secure EC2 Instance

1. **EC2 Console** → **Launch instances**

2. **Configure:**
   ```
   Name: day2-test-instance
   AMI: Amazon Linux 2023
   Instance type: t2.micro
   Key pair: Your key pair
   
   Network settings:
   ├── VPC: Your VPC
   ├── Subnet: Public Subnet 1 (with custom NACL)
   ├── Auto-assign public IP: Enable
   └── Security group: ec2-admin-sg
   
   Advanced details (scroll down):
   └── User data (optional - installs web server):
   ```

   **User data script:**
   ```bash
   #!/bin/bash
   yum update -y
   yum install -y httpd
   systemctl start httpd
   systemctl enable httpd
   echo "<h1>Day 2 - Security Groups Test</h1>" > /var/www/html/index.html
   echo "<p>Server: $(hostname -f)</p>" >> /var/www/html/index.html
   echo "<p>Private IP: $(hostname -I)</p>" >> /var/www/html/index.html
   ```

3. **Launch instance**

4. **Wait for "Running" state**

---

#### 2. Test SSH Access (Security Group Test)

**From your IP (allowed):**
```powershell
ssh -i your-key.pem ec2-user@<public-ip>
```

✅ **Expected:** Connection successful!

**Verify you're connected:**
```bash
# You should see:
[ec2-user@ip-10-0-1-x ~]$

# Check instance details
hostname
ip addr show
```

---

#### 3. Test ICMP Blocking (NACL Test)

**From your machine (not the blocked IP):**
```powershell
ping <instance-public-ip>
```

✅ **Expected:** Ping works! (You're not the blocked IP)

```
Reply from 54.x.x.x: bytes=32 time=2ms TTL=242
Reply from 54.x.x.x: bytes=32 time=2ms TTL=242
```

**From the blocked IP (if you can simulate):**
```bash
ping <instance-public-ip>
```

❌ **Expected:** Ping times out (blocked by NACL rule #10)

---

#### 4. Test HTTP Access

**Update Security Group to allow HTTP:**

1. Go to **ec2-admin-sg**
2. **Inbound rules** → **Edit inbound rules**
3. **Add rule:**
   ```
   Type:        HTTP
   Protocol:    TCP
   Port:        80
   Source:      0.0.0.0/0
   Description: Public web access
   ```
4. **Save rules**

**Test from browser:**
```
http://<instance-public-ip>
```

✅ **Expected:** See webpage with instance info!

---

#### 5. Test Security Group Changes (Live Effect)

**Remove HTTP rule:**
1. Edit inbound rules
2. Delete the HTTP rule
3. Save

**Test immediately:**
```
http://<instance-public-ip>
```

❌ **Expected:** Connection timeout (rule removed)

**Add it back:**
```
http://<instance-public-ip>
```

✅ **Expected:** Works again immediately!

**Observation:** Security group changes apply INSTANTLY (no restart needed)

---

## Task 5: Try Blocking Specific Ports & Verify

### 🎯 Goal
Understand how to block specific ports using both SG and NACL.

### 📝 Scenario Tests:

#### Test 1: Block Port 8080 Using Security Group

1. **Install test service on port 8080:**

   SSH to instance:
   ```bash
   # Create simple Python web server on port 8080
   cat > /tmp/test-server.py << 'EOF'
   import http.server
   import socketserver
   
   PORT = 8080
   Handler = http.server.SimpleHTTPRequestHandler
   
   with socketserver.TCPServer(("", PORT), Handler) as httpd:
       print(f"Server running on port {PORT}")
       httpd.serve_forever()
   EOF
   
   # Run in background
   nohup python3 /tmp/test-server.py &
   ```

2. **Add SG rule to allow 8080:**
   ```
   Type:        Custom TCP
   Port:        8080
   Source:      0.0.0.0/0
   ```

3. **Test - should work:**
   ```
   http://<instance-ip>:8080
   ```
   ✅ Works!

4. **Remove the rule**

5. **Test - should fail:**
   ```
   http://<instance-ip>:8080
   ```
   ❌ Timeout! (Security Group blocked it)

---

#### Test 2: Block Port 8080 Using NACL

1. **Add SG rule** (allow 8080 at SG level)

2. **Add NACL DENY rule:**
   ```
   Rule number: 50
   Type:        Custom TCP
   Protocol:    TCP
   Port:        8080
   Source:      0.0.0.0/0
   Allow/Deny:  DENY
   ```

3. **Test:**
   ```
   http://<instance-ip>:8080
   ```
   ❌ Timeout! (NACL blocked it before reaching SG)

**Key Learning:**
- NACL processed first (subnet boundary)
- Then Security Group (instance level)
- Both must allow for traffic to pass

---

#### Test 3: Priority - SG vs NACL

**Setup:**
```
Security Group: ALLOWS port 8080
Network ACL: DENIES port 8080
```

**Test:**
```
http://<instance-ip>:8080
```

❌ **Blocked!**

**Why?**
```
Traffic flow:
Internet → NACL (DENY) ❌ → Never reaches SG

Conclusion: NACL takes priority (geographically first)
```

---

## 📸 Task 6: Document Your Configuration

### Screenshot Checklist:

#### 1. **sg-rules.png** - Capture:
- ec2-admin-sg inbound rules
- ec2-admin-sg outbound rules
- alb-public-sg rules
- web-servers-sg rules

#### 2. **nacl-rules.png** - Capture:
- Custom NACL inbound rules
- Custom NACL outbound rules
- Rule numbers clearly visible
- Deny rule for ICMP highlighted

#### 3. **Test Results** - Capture:
- Successful SSH session
- Ping test (working from your IP)
- HTTP test in browser
- Security group changes taking effect

---

## ✅ Day 2 Tasks Completion Checklist

- [ ] Task 1: Created ec2-admin-sg (SSH from my IP only)
- [ ] Task 2: Created alb-public-sg (HTTP from all)
- [ ] Task 2: Created web-servers-sg (HTTP from ALB only)
- [ ] Task 3: Created custom NACL (block specific ping)
- [ ] Task 4: Launched test EC2 instance
- [ ] Task 4: Tested SSH access
- [ ] Task 4: Tested HTTP access
- [ ] Task 5: Tested blocking port 8080
- [ ] Task 5: Verified SG changes instant
- [ ] Task 5: Verified NACL priority
- [ ] Task 6: Captured screenshots
- [ ] Task 6: Documented findings

---

## 🧪 Bonus Challenges (Optional)

### Challenge 1: Multi-SG Instance
- Launch instance with 2 security groups
- Verify combined permissions
- Remove one SG and test

### Challenge 2: NACL Ordering
- Create multiple DENY rules
- Test rule number priority
- Swap rule numbers and retest

### Challenge 3: Ephemeral Ports
- Remove ephemeral port range from NACL
- Test HTTP access (breaks!)
- Understand why return traffic fails

---

## 💡 Key Takeaways from Tasks

1. ✅ **Security Groups are your primary defense** - Use them for normal access control
2. ✅ **NACLs are for emergencies** - Block specific bad actors quickly
3. ✅ **Stateful vs Stateless matters** - SG simpler, NACL more powerful
4. ✅ **Layer your security** - Use both SG and NACL together
5. ✅ **Test your rules** - Always verify changes work as expected
6. ✅ **Document everything** - Screenshots help troubleshoot later

---

**Next:** Move to interview-questions-answered.md for complete interview prep! 🚀
