# DAY 3 - EC2 TROUBLESHOOTING GUIDE 🔧

## Complete Debugging & Problem-Solving Reference

---

## 📋 Table of Contents

1. [SSH Connection Issues](#ssh-connection-issues)
2. [Instance Launch Problems](#instance-launch-problems)
3. [User Data Failures](#user-data-failures)
4. [Application Issues](#application-issues)
5. [Performance Problems](#performance-problems)
6. [Network & Routing Issues](#network--routing-issues)
7. [Debugging Toolkit](#debugging-toolkit)
8. [Prevention Best Practices](#prevention-best-practices)

---

## SSH Connection Issues

### Problem 1: "Connection timed out" when SSH

**Error:**
```
$ ssh -i my-key.pem ec2-user@54.123.45.67
ssh: connect to host 54.123.45.67 port 22: Connection timed out
```

**Root Causes & Fixes:**

```
CHECKLIST:

1. ✅ Is instance running?
   Check:  EC2 Dashboard → Instance state
   Fix:    If stopped → Click Start
   
2. ✅ Does instance have public IP?
   Check:  EC2 Dashboard → Public IPv4 address column
   Fix:    If empty → Allocate Elastic IP or enable auto-assign
   
3. ✅ Is security group allowing SSH?
   Check:  EC2 Dashboard → Security groups (right-click)
   Fix:    Add inbound rule:
           ├── Protocol: TCP
           ├── Port: 22
           ├── Source: YOUR_PUBLIC_IP/32 (or 0.0.0.0/0 for testing)
           └── Save
   
4. ✅ Is NACL allowing SSH?
   Check:  VPC → Network ACLs → Inbound rules
   Fix:    Must allow:
           ├── TCP 22 inbound
           ├── TCP 1024-65535 outbound (ephemeral)
           └── Save
   
5. ✅ Is instance fully booted?
   Check:  Status checks = 2/2 passed? (takes 2-3 min)
   Fix:    If pending → Wait 3 minutes
   
6. ✅ Is SSH enabled on instance?
   Check:  Not usually the issue, but for custom AMI
   Fix:    Make sure sshd service is running
```

**Testing Incrementally:**

```bash
# Step 1: Can you reach the IP at all?
ping 54.123.45.67
# If timeout: Network/SG issue

# Step 2: Is port 22 open?
nc -zv 54.123.45.67 22
# If fails: Security group blocks port 22

# Step 3: SSH with verbose output (see where it hangs)
ssh -vvv -i my-key.pem ec2-user@54.123.45.67
# Look for: where it stops responding

# Step 4: Check key permissions
ls -la ~/.ssh/my-key.pem
# Should show: -r--r--r-- (400) or -rw------- (600)
# Fix if wrong: chmod 400 ~/.ssh/my-key.pem
```

---

### Problem 2: "Permission denied (publickey)"

**Error:**
```
$ ssh -i my-key.pem ubuntu@54.123.45.67
Permission denied (publickey).
```

**Root Causes:**

```
1. Wrong Key File
   └─ You have multiple keys, using wrong one
   
2. Key Permissions Too Open
   └─ Key is readable by others (chmod issue)
   
3. Wrong Username
   └─ Using ec2-user@ for Ubuntu (should be ubuntu@)
   └─ Using ubuntu@ for Amazon Linux (should be ec2-user@)
   
4. Key Mismatch
   └─ Instance has different public key
   └─ Happens if key pair deleted/recreated
```

**Fixes:**

```bash
# Fix 1: Check correct username for AMI
# Ubuntu AMI:       ssh ubuntu@IP
# Amazon Linux AMI: ssh ec2-user@IP
# Red Hat:          ssh ec2-user@IP
# Debian:           ssh admin@IP

# Fix 2: Make sure key has correct permissions
chmod 400 ~/.ssh/my-key.pem
# Verify:
ls -la ~/.ssh/my-key.pem
# Should show: -r--r--r-- (mode 400)

# Fix 3: Try with verbose to see key loading
ssh -vvv -i ~/.ssh/my-key.pem ubuntu@54.123.45.67
# Look for: "Offering public key" - confirms key is offered

# Fix 4: If still failing, verify key on instance
# (Need different access method - Bastion, EC2 Instance Connect)
cat ~/.ssh/authorized_keys
# Should contain: ssh-rsa AAAA... (your public key)

# Fix 5: As last resort, use EC2 Instance Connect (AWS console)
# EC2 Dashboard → Instance → Connect → EC2 Instance Connect
# Opens web-based terminal (no SSH key needed)
```

---

### Problem 3: "Host key verification failed"

**Error:**
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@  WARNING: POSSIBLE DNS SPOOFING DETECTED! @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

**Cause:** First time connecting to host, SSH doesn't recognize it

**Fix:**

```bash
# Option 1: Accept and continue (simple)
# Press: yes
# Then continue

# Option 2: Pre-accept the key (scripting)
ssh-keyscan -H 54.123.45.67 >> ~/.ssh/known_hosts

# Option 3: Disable check (not recommended, less secure)
ssh -o StrictHostKeyChecking=no -i my-key.pem ubuntu@54.123.45.67
```

---

## Instance Launch Problems

### Problem 4: Instance never reaches "running" state

**Status:** Stuck in "pending" for 10+ minutes

**Causes:**

```
1. AWS Service Disruption
   └─ Rare, but AWS infrastructure issue
   
2. Instance Type Unavailable
   └─ t3.micro not available in your AZ
   
3. AMI Not Available
   └─ AMI deleted or not accessible
   
4. Insufficient Capacity
   └─ AWS has no capacity for that instance type
```

**Fixes:**

```bash
# Step 1: Check instance status
aws ec2 describe-instances --instance-ids i-0abcd1234efgh5678 \
  --query 'Reservations[0].Instances[0].[State.Name,StateReason.Message]'

# Step 2: If stuck in pending > 15 min, terminate and try again
aws ec2 terminate-instances --instance-ids i-0abcd1234efgh5678

# Step 3: Try different instance type
# Instead of: t3.micro
# Try:       t2.micro or m5.large

# Step 4: Try different AZ
# Instead of: us-east-1a
# Try:        us-east-1b or us-east-1c
```

---

### Problem 5: Instance terminates immediately

**Status:** Running for 2-5 seconds, then terminated

**Causes:**

```
1. User Data Script Failed
   └─ Script errors → Instance killed
   
2. Instance Limit Exceeded
   └─ You hit AWS quota for that instance type
   
3. Subnet has no available IPs
   └─ CIDR block full, no IP for instance
```

**Debugging:**

```bash
# Check cloud-init logs
cat /var/log/cloud-init-output.log
# Look for ERROR, FAILED keywords

# Or if instance terminated, check:
aws ec2 describe-instances --instance-ids i-0abcd1234efgh5678 \
  --query 'Reservations[0].Instances[0].StateTransitionReason'

# Example output:
# "User initiated (2024-01-28 10:05:03 GMT)"
# means manual termination or script error

# OR output:
# "Client.InstanceLimitExceeded"
# means you hit quota
```

---

## User Data Failures

### Problem 6: User Data script didn't run

**Symptoms:**
```
✓ Instance is running
✗ Node.js not installed
✗ Application not running
✗ /var/log/cloud-init-output.log not found (or minimal)
```

**Debugging:**

```bash
# SSH into instance
ssh -i my-key.pem ubuntu@54.123.45.67

# Check if cloud-init is still running
sudo systemctl status cloud-init
# Status: active (running) or active (exited)

# Check cloud-init logs
sudo tail -100 /var/log/cloud-init.log
# Look for: Started Execute cloud user/root

# Check cloud-init-output.log
sudo cat /var/log/cloud-init-output.log
# Should show: Your script output

# If logs are empty:
# → Likely passed to instance but not executed
# → Check User Data in instance details
aws ec2 describe-instances --instance-ids i-0abcd1234efgh5678 \
  --query 'Reservations[0].Instances[0].UserData'
```

**Common Reasons:**

```
1. User Data Base64 Decoded Wrong
   └─ If copied from AWS console, sometimes malformed
   └─ Re-paste from your script file directly

2. Script Syntax Error
   └─ Missing #!/bin/bash
   └─ Syntax error in bash
   └─ Fix: Test locally: bash -x your-script.sh

3. Network Issue During Execution
   └─ Can't reach GitHub/NPM during package install
   └─ Check: curl https://github.com (from instance)

4. Permissions Issues
   └─ Can't write to directory
   └─ Fix: Ensure running as root or sudo
```

---

### Problem 7: User Data runs but exits with error

**Symptoms:**
```
✓ /var/log/cloud-init-output.log exists
✗ Shows ERROR or failed command
✗ Application not running
```

**Debugging:**

```bash
# Read the log file
ssh -i my-key.pem ubuntu@54.123.45.67
tail -50 /var/log/cloud-init-output.log

# Look for error lines like:
# E: Unable to locate package nodejs
# npm ERR! 404 Not Found
# fatal: Could not read Username
# etc.

# Test commands manually
apt update
apt install -y nodejs
npm install -g pm2
git clone https://your-repo.git

# See which command fails
# Then fix the script
```

**Common Errors:**

```
1. apt/yum fails (wrong OS)
   └─ Script for Ubuntu but instance is Amazon Linux
   └─ Fix: Use correct package manager

2. git clone fails (auth issue)
   └─ Repository is private
   └─ Fix: Add SSH key or use GitHub token in URL

3. npm install fails (node_modules)
   └─ Permission denied
   └─ Fix: Run as correct user or with sudo

4. Port already in use
   └─ Something else listening on 3000
   └─ Fix: Change port or kill conflicting process

5. Dependency missing
   └─ "command not found"
   └─ Fix: Add missing package install step
```

---

## Application Issues

### Problem 8: Application crashes after launching

**Symptoms:**
```
✓ User Data runs successfully
✓ pm2 status shows: online
5 minutes later...
✓ pm2 status shows: crashed or exited
```

**Debugging:**

```bash
# SSH into instance
ssh -i my-key.pem ubuntu@54.123.45.67

# Check PM2 status
pm2 status
# Shows: online, errored, stopped, one-launch-status

# View crash reason
pm2 logs app-name --lines 50
# Shows: Recent logs and error

# Common app errors:
# "Cannot find module 'express'"
# "RDS_ENDPOINT undefined"
# "Port 3000 already in use"
# "EACCES: permission denied"
# "Out of memory"
```

**Fixes by Error Type:**

```
Error: "Cannot find module 'express'"
└─ Solution: npm install (dependencies not installed)

Error: "RDS_ENDPOINT undefined"
└─ Solution: Set environment variables
   export RDS_ENDPOINT=rds-instance.xxx.us-east-1.rds.amazonaws.com
   export DB_USER=postgres
   export DB_PASS=password
   pm2 restart app

Error: "EADDRINUSE: Port 3000 already in use"
└─ Solution: Kill other process
   lsof -i :3000
   kill -9 <PID>
   pm2 restart app

Error: "Out of memory"
└─ Solution: Check memory
   free -h
   Upgrade instance type: t3.micro → t3.small

Error: "Connection refused" (DB)
└─ Solution: Verify RDS
   1. RDS is running
   2. Security group allows connection
   3. Credentials are correct
   4. Check RDS endpoint
```

**How to Monitor:**

```bash
# Watch logs in real-time
pm2 logs app-name -f

# Monitor resource usage
pm2 monit

# Restart app
pm2 restart app-name

# Check if app starts on reboot
pm2 startup
sudo systemctl restart pm2-ubuntu
pm2 status
```

---

### Problem 9: Application runs but not accessible via browser

**Symptoms:**
```
✓ Application running (pm2 status = online)
✓ Local test works: curl http://localhost:3000
✗ Browser can't reach: http://54.123.45.67:3000
```

**Debugging:**

```bash
# Step 1: Verify app listening locally
ssh -i my-key.pem ubuntu@54.123.45.67
curl http://localhost:3000
# Should return: JSON or HTML (not connection refused)

# Step 2: Verify app listening on all interfaces (not just localhost)
netstat -tuln | grep 3000
# Should show: tcp 0 0 0.0.0.0:3000 LISTEN
# NOT: tcp 0 0 127.0.0.1:3000 LISTEN

# Step 3: If only 127.0.0.1:3000, need to fix app
# In app code:
# app.listen(3000, '0.0.0.0')  // ← Correct (listen on all IPs)
# app.listen(3000)             // ← Also correct (default 0.0.0.0)
# app.listen(3000, 'localhost')// ← Wrong (only local)

# Step 4: Check security group
aws ec2 describe-security-groups --group-ids sg-0abcd1234 \
  --query 'SecurityGroups[0].IpPermissions' | grep -A5 3000
# Should show: Port 3000 allowed from 0.0.0.0/0

# If not, add rule:
aws ec2 authorize-security-group-ingress \
  --group-id sg-0abcd1234 \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0
```

---

## Performance Problems

### Problem 10: Application responds slowly

**Symptoms:**
```
$ curl http://54.123.45.67:3000
(takes 10+ seconds to respond)
```

**Debugging:**

```bash
# Check CPU usage
top
# Look for: %CPU column
# If high (> 80%): App is CPU-bound or infinite loop

# Check memory usage
free -h
# Look for: Available memory
# If low: App has memory leak or system is swapping

# Check disk I/O
iostat -x 1 5
# Look for: %util (if > 90%: slow disk)

# Check network
iftop
# Look for: High bandwidth usage

# Application-specific
ps aux | grep node
# Check command: Is it running with correct parameters?

# Check app logs
pm2 logs app-name | tail -100
# Look for: Errors, slow queries, timeout warnings
```

**Common Causes & Fixes:**

```
Cause 1: High CPU (> 80%)
├── Reason: Inefficient code, infinite loop, N+1 query
├── Check: App logs for errors
├── Fix: Profile code, optimize queries
└── Temporary: Upgrade instance type

Cause 2: High Memory (> 85%)
├── Reason: Memory leak, large dataset loaded
├── Check: pm2 monit (watch memory over time)
├── Fix: Find memory leak, restart app periodically
└── Temporary: Upgrade instance type

Cause 3: Slow Disk (I/O wait > 30%)
├── Reason: Large files, slow database queries
├── Check: app logs for slow operations
├── Fix: Add caching, optimize DB queries
└── Temporary: Use SSD or add EBS optimization

Cause 4: Database Connection Timeout
├── Reason: Connection pool exhausted, RDS slow
├── Check: curl RDS endpoint from EC2
├── Fix: Increase pool size, upgrade RDS instance
└── Monitoring: Check RDS metrics in CloudWatch

Cause 5: Under-provisioned Instance
├── Reason: t3.micro not enough for load
├── Check: Auto-scaling metrics
├── Fix: Upgrade to t3.small, m5.large, or enable auto-scaling
└── Cost: ~2x more but better performance
```

---

## Network & Routing Issues

### Problem 11: Can't reach RDS from EC2

**Error:**
```
Error: Unable to connect to RDS endpoint
Connection timeout
```

**Debugging:**

```bash
# Step 1: Verify RDS is running
aws rds describe-db-instances --db-instance-identifier my-db \
  --query 'DBInstances[0].DBInstanceStatus'
# Should return: "available"

# Step 2: Get RDS endpoint
aws rds describe-db-instances --db-instance-identifier my-db \
  --query 'DBInstances[0].Endpoint.Address'
# Returns: mydb.c9akciq32.us-east-1.rds.amazonaws.com

# Step 3: DNS resolution from EC2
ssh -i my-key.pem ubuntu@54.123.45.67
nslookup mydb.c9akciq32.us-east-1.rds.amazonaws.com
# Should return: Private IP like 10.0.2.50

# Step 4: Ping RDS (ICMP)
ping -c 4 10.0.2.50
# May timeout (ICMP blocked), but that's OK

# Step 5: Try to connect on port 5432
telnet 10.0.2.50 5432
# Should show: Connected (not connection refused)

# Step 6: Try actual database connection
psql -h 10.0.2.50 -U postgres -d mydb
# Prompts for password: DB working!
```

**Troubleshooting Steps:**

```
1. Security Group Mismatch
   └─ EC2 SG: Does it have outbound to 5432?
   └─ RDS SG: Does it allow inbound from EC2 SG?
   └─ Fix: Update security group rules

2. Wrong Port
   └─ PostgreSQL: 5432
   └─ MySQL: 3306
   └─ MariaDB: 3306
   └─ Fix: Use correct port

3. Different VPC
   └─ EC2 in VPC-A, RDS in VPC-B
   └─ Can't reach across VPCs (without peering)
   └─ Fix: Place both in same VPC

4. NACL Blocking
   └─ Outbound rule missing port 5432
   └─ Or ephemeral ports 1024-65535
   └─ Fix: Add NACL rules

5. RDS in Private Subnet (intended)
   └─ Make sure EC2 can reach (right routing)
   └─ Check route table
```

---

### Problem 12: S3 bucket not accessible from EC2

**Error:**
```
Error: Access Denied to S3 bucket
or
NoCredentialsError: Unable to locate credentials
```

**Debugging:**

```bash
# SSH into EC2
ssh -i my-key.pem ubuntu@54.123.45.67

# Check if IAM role attached
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
# Should return role name, not error

# Get credentials from role
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/ec2-app-role
# Should return JSON with AccessKeyId

# Try S3 access
aws s3 ls s3://my-bucket
# If works: Credentials OK
# If fails: IAM permissions missing
```

**Fixes:**

```
1. IAM Role Not Attached
   └─ EC2 instance has no role
   └─ Fix: Attach IAM role to EC2 instance
   
2. IAM Policy Missing S3 Permissions
   └─ Role attached but no S3 access
   └─ Fix: Add policy to role:
      {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "*"
      }
   
3. Bucket Policy Blocking
   └─ Bucket has restrictive policy
   └─ Fix: Update bucket policy to allow role
   
4. VPC Endpoint Missing
   └─ EC2 in private subnet, can't reach S3
   └─ Fix: Create VPC Endpoint for S3
```

---

## Debugging Toolkit

### Essential Commands

```bash
# Instance Status
aws ec2 describe-instances --instance-ids i-xxxxx \
  --query 'Reservations[0].Instances[0].[State.Name,PrivateIpAddress,PublicIpAddress]' \
  --output table

# Security Group Rules
aws ec2 describe-security-groups --group-ids sg-xxxxx \
  --query 'SecurityGroups[0].[IpPermissions,IpPermissionsEgress]' \
  --output json | jq

# Instance Logs
cat /var/log/cloud-init-output.log
tail -f /var/log/syslog
journalctl -xe

# Network Diagnostics
netstat -tuln                    # Show listening ports
netstat -tnp | grep ESTABLISHED  # Show connections
ss -tuln                         # Faster netstat
lsof -i :3000                    # What's using port 3000

# DNS Resolution
nslookup mydb.rds.amazonaws.com
dig mydb.rds.amazonaws.com

# Connectivity Tests
curl http://localhost:3000       # Local test
curl http://169.254.169.254/latest/meta-data/instance-id  # Metadata
telnet 10.0.2.50 5432           # Port connectivity
ping 10.0.2.50                   # ICMP (may not work)

# Resource Usage
top                              # CPU and memory
free -h                          # Memory detail
df -h                            # Disk space
iostat -x 1 5                    # Disk I/O

# Process Management (PM2)
pm2 status                       # Show processes
pm2 logs app-name                # View logs
pm2 logs app-name --lines 100 -f # Follow logs
pm2 monit                        # Monitor resources
pm2 describe app-name            # Detailed info
pm2 restart app-name             # Restart app

# AWS CLI
aws ec2 stop-instances --instance-ids i-xxxxx
aws ec2 start-instances --instance-ids i-xxxxx
aws ec2 reboot-instances --instance-ids i-xxxxx
aws ec2 terminate-instances --instance-ids i-xxxxx

# IAM Role Check
curl http://169.254.169.254/latest/meta-data/iam/info
aws sts get-caller-identity
```

---

## Prevention Best Practices

### 1. Avoid Common Mistakes

```
❌ Don't do this:
├── Hardcode AWS credentials in code
├── Ignore security group rules
├── Use same key pair for all instances
├── Skip backup of important data
├── Leave SSH open to 0.0.0.0/0
├── Use micro instances for production
├── Ignore CloudWatch alarms
└── Keep instances running 24/7 (test servers)

✅ Do this instead:
├── Use IAM roles for credentials
├── Plan security groups carefully
├── Use different key pairs
├── Enable EBS snapshots
├── SSH only from specific IPs
├── Right-size instances
├── Set up CloudWatch alarms
└── Stop instances when not in use
```

### 2. Monitoring Setup

```bash
# Create CloudWatch alarm
aws cloudwatch put-metric-alarm \
  --alarm-name high-cpu \
  --alarm-description "Alert if CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:us-east-1:123456789:alerts

# Enable detailed monitoring
aws ec2 monitor-instances --instance-ids i-xxxxx

# Set up logs
sudo systemctl enable awslogsd
sudo systemctl start awslogsd
```

### 3. Pre-Launch Checklist

```
Before launching instance:

Security:
├── ✓ Key pair created and downloaded
├── ✓ Security group configured (SSH, HTTP/HTTPS)
├── ✓ IAM role created with needed permissions
└── ✓ NACL rules reviewed

Configuration:
├── ✓ Correct AMI selected
├── ✓ Correct instance type for workload
├── ✓ Correct subnet (public or private?)
├── ✓ Auto-assign public IP enabled
└── ✓ User Data script tested

Monitoring:
├── ✓ Termination protection disabled (for testing)
├── ✓ CloudWatch alarms planned
├── ✓ Tags added (Name, Environment, Owner)
└── ✓ Backup strategy planned

Post-Launch:
├── ✓ SSH tested within 5 minutes
├── ✓ User Data logs reviewed
├── ✓ Application tested
├── ✓ CloudWatch metrics appearing
└── ✓ Alarms responding to load
```

---

## Quick Reference: 5-Minute Fix Guide

```
Problem: Instance won't SSH
Time: 5 minutes
1. Security group allows port 22? → Add rule
2. Instance running? → Start if stopped
3. Has public IP? → Allocate Elastic IP
4. Try again → Should work!

Problem: Application not accessible
Time: 5 minutes
1. App running locally? → ssh, curl localhost:3000
2. App listening on 0.0.0.0:3000? → Check code/config
3. Security group allows port 3000? → Add rule
4. Try again → Should work!

Problem: Can't reach RDS
Time: 5 minutes
1. RDS running? → Check RDS console
2. Same VPC? → Check subnets
3. Security group allows 5432? → Add rule
4. Try again → Should work!

Problem: Application crashing
Time: 5 minutes
1. Check logs → pm2 logs app-name
2. Find error → "module not found"? "port in use"?
3. Fix error → Install, change port, etc.
4. Restart → pm2 restart app-name
```

Bookmark this guide and reference when troubleshooting! 🚀
