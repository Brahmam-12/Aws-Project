# VPC Testing & Validation Guide 🧪

## Your Current Setup (Verified ✅)

Based on your AWS Console screenshots, you have successfully created:

- ✅ **VPC**: `my-vpc-vpc` (10.0.0.0/20)
- ✅ **4 Subnets**: 
  - Public Subnet 1: 10.0.1.0/24 (ap-south-1a)
  - Public Subnet 2: 10.0.2.0/24 (ap-south-1b)
  - Private Subnet 1: 10.0.3.0/24 (ap-south-1a)
  - Private Subnet 2: 10.0.4.0/24 (ap-south-1b)
- ✅ **Internet Gateway**: Attached to VPC
- ✅ **NAT Gateway**: In place
- ✅ **Route Tables**: 
  - Public Route Table → Internet Gateway (0.0.0.0/0)
  - Private Route Table → NAT Gateway (0.0.0.0/0)

---

## 🎯 What You Need to Do Next

### Step 1: Create Security Groups (Required for Testing)

#### A. Web Server Security Group (For Public Subnet)

1. **Go to EC2 Console** → **Security Groups** (left sidebar)
2. Click **"Create security group"**
3. **Configure:**
   ```
   Security group name:    web-server-sg
   Description:            Allow HTTP, HTTPS, and SSH
   VPC:                    Select your VPC (my-vpc-vpc)
   ```

4. **Inbound Rules - Add 3 rules:**
   ```
   Rule 1:
   Type:        HTTP
   Protocol:    TCP
   Port:        80
   Source:      0.0.0.0/0 (Anywhere IPv4)
   Description: Allow web traffic
   
   Rule 2:
   Type:        HTTPS
   Protocol:    TCP
   Port:        443
   Source:      0.0.0.0/0 (Anywhere IPv4)
   Description: Allow secure web traffic
   
   Rule 3:
   Type:        SSH
   Protocol:    TCP
   Port:        22
   Source:      My IP (automatically detects your IP)
   Description: SSH access for admin
   ```

5. **Outbound Rules**: Leave default (Allow all)
6. Click **"Create security group"**

#### B. Private Server Security Group (For Private Subnet)

1. Click **"Create security group"** again
2. **Configure:**
   ```
   Security group name:    private-server-sg
   Description:            Allow traffic from public subnet only
   VPC:                    Select your VPC (my-vpc-vpc)
   ```

3. **Inbound Rules - Add 2 rules:**
   ```
   Rule 1:
   Type:        SSH
   Protocol:    TCP
   Port:        22
   Source:      Custom → 10.0.0.0/20 (your VPC CIDR)
   Description: SSH from VPC only
   
   Rule 2:
   Type:        All ICMP - IPv4
   Protocol:    ICMP
   Port:        All
   Source:      10.0.0.0/20
   Description: Ping from VPC
   ```

4. Click **"Create security group"**

---

## 🚀 Step 2: Launch Test EC2 Instances

### Test Instance 1: Public Subnet (Bastion Host)

1. **Go to EC2 Console** → **Instances** → **Launch instances**

2. **Configure:**
   ```
   Name:                      bastion-host
   
   AMI:                       Amazon Linux 2023 (Free tier)
   
   Instance type:             t2.micro (Free tier)
   
   Key pair:                  Create new key pair
                              - Name: my-vpc-key
                              - Type: RSA
                              - Format: .pem (for Windows use PuTTY: .ppk)
                              - DOWNLOAD AND SAVE IT!
   
   Network settings:          Click "Edit"
   VPC:                       my-vpc-vpc
   Subnet:                    Public Subnet 1 (10.0.1.0/24)
   Auto-assign public IP:     Enable
   Security group:            Select existing → web-server-sg
   
   Storage:                   8 GB (default)
   ```

3. Click **"Launch instance"**
4. Wait for instance state to be **"Running"** (2-3 minutes)

### Test Instance 2: Private Subnet

1. Click **"Launch instances"** again

2. **Configure:**
   ```
   Name:                      private-server
   
   AMI:                       Amazon Linux 2023 (Free tier)
   
   Instance type:             t2.micro (Free tier)
   
   Key pair:                  Select existing → my-vpc-key
   
   Network settings:          Click "Edit"
   VPC:                       my-vpc-vpc
   Subnet:                    Private Subnet 1 (10.0.3.0/24)
   Auto-assign public IP:     Disable (should be disabled by default)
   Security group:            Select existing → private-server-sg
   
   Storage:                   8 GB (default)
   ```

3. Click **"Launch instance"**
4. Wait for instance state to be **"Running"**

---

## 🧪 Step 3: Test Your VPC (Simple Explained)

### Test 1: Connect to Public Instance (Bastion Host)

**What we're testing:** Can you reach a server in the public subnet from the internet?

#### Using Windows (CMD or PowerShell):

1. **Open Command Prompt or PowerShell**

2. **Navigate to where you saved the key:**
   ```powershell
   cd Downloads
   ```

3. **Connect via SSH:**
   ```powershell
   ssh -i my-vpc-key.pem ec2-user@<PUBLIC-IP-OF-BASTION>
   ```
   
   Replace `<PUBLIC-IP-OF-BASTION>` with the actual public IP from EC2 console

4. **If you get "permissions error":**
   - Right-click `my-vpc-key.pem` → Properties → Security
   - Remove all users except yourself
   - Give yourself Full Control

5. **Type "yes"** when asked about fingerprint

6. **You should see:**
   ```
   [ec2-user@ip-10-0-1-x ~]$
   ```
   
   ✅ **SUCCESS!** You're now connected to your public subnet server!

---

### Test 2: Verify Internet Access from Public Subnet

**What we're testing:** Can the public server access the internet?

**While connected to bastion host, run:**

```bash
# Test 1: Check internet connectivity
ping -c 4 google.com

# Test 2: Check your public IP (should show your public IP)
curl ifconfig.me

# Test 3: Download something from internet
curl https://www.google.com
```

**Expected Results:**
- ✅ Ping should work (packets received)
- ✅ Should show your instance's public IP
- ✅ Should download Google's homepage HTML

---

### Test 3: Connect to Private Instance (Through Bastion)

**What we're testing:** Can the private server be reached from the public server?

#### Step 3a: Copy your key to Bastion host

**From your Windows machine:**

```powershell
# In PowerShell (from your key location)
scp -i my-vpc-key.pem my-vpc-key.pem ec2-user@<BASTION-PUBLIC-IP>:~/.ssh/
```

**OR do it manually:**

1. On your Windows, open `my-vpc-key.pem` in Notepad
2. Copy all the content (including BEGIN and END lines)
3. SSH to bastion host
4. Create the key file:
   ```bash
   nano ~/.ssh/my-vpc-key.pem
   ```
5. Paste the key content
6. Press `Ctrl+X`, then `Y`, then `Enter`
7. Set permissions:
   ```bash
   chmod 400 ~/.ssh/my-vpc-key.pem
   ```

#### Step 3b: SSH from Bastion to Private Server

**While connected to bastion, run:**

```bash
# Get the private IP of your private instance from EC2 console
# It should be something like 10.0.3.x

ssh -i ~/.ssh/my-vpc-key.pem ec2-user@10.0.3.x
```

Replace `10.0.3.x` with actual private IP from console

**You should see:**
```
[ec2-user@ip-10-0-3-x ~]$
```

✅ **SUCCESS!** You've connected to your private server!

---

### Test 4: Verify NAT Gateway Works

**What we're testing:** Can the private server access internet (outbound only)?

**While connected to private server, run:**

```bash
# Test 1: Ping google (should work via NAT)
ping -c 4 google.com

# Test 2: Check your public IP (should show NAT Gateway's public IP)
curl ifconfig.me

# Test 3: Update packages (proves internet access)
sudo yum update -y
```

**Expected Results:**
- ✅ Ping works (through NAT Gateway)
- ✅ Should show **NAT Gateway's Elastic IP** (NOT your instance IP)
- ✅ Package updates work

**What this proves:**
- Private instance can reach internet
- But internet CANNOT reach private instance directly
- All traffic goes through NAT Gateway

---

### Test 5: Verify Isolation (Security Test)

**What we're testing:** Private server cannot be accessed from internet

#### Try to SSH directly to private instance (Should FAIL):

**From your Windows machine:**

```powershell
# This should TIMEOUT and FAIL
ssh -i my-vpc-key.pem ec2-user@10.0.3.x
```

✅ **Expected: Connection timeout** - This is CORRECT! Private servers should NOT be reachable from internet.

---

## 📊 How Your VPC Components Talk to Each Other

### Communication Flow Diagram (Simple Explanation)

```
┌─────────────────────────────────────────────────────────┐
│                      INTERNET                           │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ (Anyone can access)
                 ▼
          ┌──────────────┐
          │ Internet     │
          │ Gateway      │
          │ (IGW)        │
          └──────┬───────┘
                 │
                 │ (Route: 0.0.0.0/0 → IGW)
                 ▼
    ┌────────────────────────────────┐
    │   PUBLIC SUBNET (10.0.1.0/24)  │
    │                                │
    │  ┌──────────────────────────┐  │
    │  │  Bastion Host            │  │
    │  │  (Public IP: x.x.x.x)    │◄─┼─── YOU SSH HERE
    │  │  (Private IP: 10.0.1.5)  │  │
    │  └──────────┬───────────────┘  │
    │             │                  │
    │  ┌──────────▼───────────────┐  │
    │  │  NAT Gateway             │  │
    │  │  (Elastic IP: y.y.y.y)   │  │
    │  └──────────┬───────────────┘  │
    └─────────────┼──────────────────┘
                  │
                  │ (Route: 0.0.0.0/0 → NAT)
                  ▼
    ┌────────────────────────────────┐
    │  PRIVATE SUBNET (10.0.3.0/24)  │
    │                                │
    │  ┌──────────────────────────┐  │
    │  │  Private Server          │  │
    │  │  (No Public IP)          │◄─┼─── Only accessible via Bastion
    │  │  (Private IP: 10.0.3.4)  │  │
    │  └──────────────────────────┘  │
    │                                │
    └────────────────────────────────┘
```

### Traffic Flow Explained:

#### 1. **Internet → Public Server (Inbound)**
```
Internet → Internet Gateway → Public Subnet → Bastion Host ✅
```
- Anyone can access (if security group allows)
- Direct path through Internet Gateway

#### 2. **Internet → Private Server (Inbound)**
```
Internet → ❌ BLOCKED ❌ → Private Server
```
- NO direct access possible
- Private server is completely isolated

#### 3. **Public Server → Private Server**
```
Bastion (10.0.1.5) → Route Table (local) → Private Server (10.0.3.4) ✅
```
- Internal VPC communication
- Uses private IPs
- No internet involved

#### 4. **Private Server → Internet (Outbound)**
```
Private Server → NAT Gateway → Internet Gateway → Internet ✅
```
- Can download updates
- Can call external APIs
- But return traffic comes back through NAT
- Internet sees NAT's IP, not server's IP

#### 5. **Public Server → Internet (Outbound)**
```
Bastion → Internet Gateway → Internet ✅
```
- Direct internet access
- Uses its own public IP

---

## 🔍 Quick Verification Commands

### Check Your Setup Status:

#### On Bastion Host (Public Subnet):
```bash
# Check your IPs
ip addr show                    # Shows: 10.0.1.x (private)
curl ifconfig.me               # Shows: Your public IP

# Check internet access
ping -c 2 google.com           # Should work

# Check connectivity to private subnet
ping -c 2 10.0.3.4             # Replace with your private IP
```

#### On Private Server (Private Subnet):
```bash
# Check your IPs
ip addr show                    # Shows: 10.0.3.x (private only)
curl ifconfig.me               # Shows: NAT Gateway's IP

# Check internet access via NAT
ping -c 2 google.com           # Should work (via NAT)

# Check route table
ip route                       # Should show default via 10.0.3.1
```

---

## ✅ Success Criteria Checklist

- [ ] Can SSH into bastion host from your laptop
- [ ] Bastion host can ping google.com
- [ ] Bastion host can SSH to private server
- [ ] Private server can ping google.com (via NAT)
- [ ] `curl ifconfig.me` on private server shows NAT Gateway IP
- [ ] Cannot SSH directly to private server from internet
- [ ] Both servers can communicate with each other

---

## 🐛 Troubleshooting Common Issues

### Issue 1: Can't SSH to Bastion Host

**Symptoms:** Connection timeout

**Solutions:**
1. Check Security Group allows SSH (port 22) from your IP
2. Verify instance has public IP assigned
3. Check public route table has IGW route (0.0.0.0/0 → igw-xxx)
4. Verify Internet Gateway is attached to VPC
5. Check key file permissions: `chmod 400 my-vpc-key.pem`

### Issue 2: Bastion Can't Reach Internet

**Symptoms:** `ping google.com` fails

**Solutions:**
1. Check route table: `ip route` (should show default via 10.0.1.1)
2. Verify public route table has IGW route
3. Check security group allows outbound traffic
4. Verify DNS resolution: `nslookup google.com`

### Issue 3: Can't SSH from Bastion to Private Server

**Symptoms:** Connection timeout or refused

**Solutions:**
1. Verify private server's private IP: Check EC2 console
2. Check private-server-sg allows SSH from VPC CIDR (10.0.0.0/20)
3. Verify key file is on bastion: `ls -la ~/.ssh/`
4. Check key permissions: `chmod 400 ~/.ssh/my-vpc-key.pem`
5. Try ping first: `ping 10.0.3.x`

### Issue 4: Private Server Can't Reach Internet

**Symptoms:** `ping google.com` fails from private server

**Solutions:**
1. Verify NAT Gateway is in **Available** state (AWS Console)
2. Check NAT Gateway is in **Public Subnet**
3. Check private route table has route: 0.0.0.0/0 → nat-xxx
4. Verify NAT Gateway has Elastic IP attached
5. Check subnet association: Private subnets → Private route table

### Issue 5: Wrong IP Showing on Private Server

**Symptoms:** `curl ifconfig.me` shows private IP instead of NAT IP

**Solutions:**
1. Wait 1-2 minutes (NAT takes time)
2. Verify private route table has NAT route
3. Check security group allows outbound HTTPS
4. Try: `curl -4 ifconfig.me` (force IPv4)

---

## 💡 Understanding What Each Component Does

### Internet Gateway (IGW)
- **Job:** Gateway between VPC and internet
- **Like:** Front door of your house
- **Allows:** Two-way traffic (in and out)

### NAT Gateway
- **Job:** Allows private servers to access internet
- **Like:** One-way mirror - you can see out, but they can't see in
- **Allows:** Only outbound traffic (downloads, updates)

### Route Tables
- **Job:** Traffic directions/GPS for your network
- **Like:** Road signs telling traffic where to go
- **Public RT:** "To reach internet (0.0.0.0/0), go to IGW"
- **Private RT:** "To reach internet (0.0.0.0/0), go to NAT"

### Security Groups
- **Job:** Firewall for individual servers
- **Like:** Bouncer at a club checking IDs
- **Stateful:** If you allow traffic in, return traffic is automatic

### Subnets
- **Job:** Divide VPC into smaller networks
- **Like:** Different floors in a building
- **Public:** Exposed to internet (with IGW)
- **Private:** Hidden from internet (with NAT)

---

## 🎓 Real-World Use Case Explanation

**Imagine you're running a website with a database:**

1. **Public Subnet (Bastion + Load Balancer)**
   - Your website's front door
   - Users access your website here
   - Load balancer distributes traffic

2. **Private Subnet (App Servers + Database)**
   - Your website's backend code runs here
   - Database stores user data here
   - Hackers can't directly access this

3. **Internet Gateway**
   - Allows users to reach your website

4. **NAT Gateway**
   - Allows your servers to download security updates
   - But prevents hackers from connecting to them

**Result:** 
- ✅ Users can access website
- ✅ Servers can download updates
- ❌ Hackers cannot directly attack your database

---

## 📚 Next Learning Steps

After mastering this, try:

1. **Add Application Load Balancer** (Day 2)
2. **Deploy a simple web app** on public instance
3. **Create RDS database** in private subnet
4. **Set up Auto Scaling**
5. **Configure CloudWatch monitoring**

---

## 💰 Cost Warning

**Don't forget to clean up!**

**Running Costs:**
- NAT Gateway: ~$1/day (~$32/month)
- EC2 instances: Free tier covers t2.micro
- Elastic IP: Free when attached

**To Save Money (After Testing):**
1. Stop EC2 instances (not terminate yet)
2. Can delete NAT Gateway (recreate when needed)
3. Keep VPC and subnets (they're free)

---

## 🎉 Congratulations!

You've successfully:
- ✅ Built a production-ready VPC
- ✅ Configured multi-tier networking
- ✅ Implemented security best practices
- ✅ Tested all connectivity paths

**You now understand:**
- How VPCs isolate workloads
- Why public and private subnets matter
- How NAT enables outbound internet
- How bastion hosts provide secure access

---

**Created:** November 24, 2025  
**Region:** ap-south-1 (Mumbai)  
**Your VPC:** my-vpc-vpc (10.0.0.0/20)

🚀 **You're ready for Day 2!**
