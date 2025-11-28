# DAY 3 - EC2 DEEP DIVE 🚀

## Complete EC2 Mastery - Everything You Need

Welcome to Day 3 of your AWS learning journey! Today you'll become an EC2 expert and deploy your first scalable application.

---

## 📚 What You'll Learn

By the end of Day 3, you will:

✅ **Understand EC2 fundamentals** - What it is, why it's important, how it differs from other AWS services

✅ **Master AMIs** - Create, customize, and launch instances from templates

✅ **Choose the right instance type** - Match workload to t3, m5, c5, r5, and other families

✅ **Use User Data effectively** - Auto-install software, deploy code, configure services

✅ **Connect via SSH** - Access instances securely from your machine

✅ **Monitor and troubleshoot** - Debug common issues, monitor with CloudWatch

✅ **Scale applications** - Use Auto Scaling Groups for high availability

✅ **Implement security** - IAM roles, security groups, least privilege access

✅ **Answer interview questions** - 35+ common EC2 interview scenarios

✅ **Launch production-ready infrastructure** - Multi-tier application with ALB and auto-scaling

---

## 📁 Files & Documentation

### Core Learning Materials

#### 1. **notes.md** (Complete EC2 Theory)
   - **Time to read:** 2-3 hours
   - **Topics:**
     - EC2 Fundamentals
     - AMI (Amazon Machine Image)
     - Instance Types (t3, m5, c5, r5, etc.)
     - Instance Lifecycle (pending → running → stopped → terminated)
     - User Data vs Metadata
     - Key Pairs & SSH
     - Spot vs On-Demand instances
     - Elastic IP vs Public IP
     - CloudWatch Monitoring
     - Security Best Practices
   - **Best for:** Building foundational knowledge
   - **When to use:** Before launching your first instance

#### 2. **step-by-step-launch-guide.md** (Hands-On Tasks)
   - **Time to complete:** 1-2 hours
   - **Includes:**
     - Task 0: Prerequisites & security group setup
     - Task 1: Launch EC2 instance (console & CLI)
     - Task 2: Connect via SSH
     - Task 3: Test application
     - Task 4: Monitor with CloudWatch
     - Task 5: Create custom AMI
     - Task 6: Troubleshooting guide
   - **Best for:** Actually launching instances
   - **When to use:** After reading notes.md

#### 3. **interview-questions.md** (35+ Q&A)
   - **Time to read:** 3-4 hours
   - **Coverage:**
     - EC2 fundamentals
     - AMI & instance setup
     - Instance types & sizing
     - Spot vs On-Demand
     - User Data & Metadata
     - Networking & connectivity
     - Monitoring & troubleshooting
     - Security & best practices
     - Cost optimization
     - Architecture & scaling
   - **Best for:** Interview prep
   - **When to use:** Before taking AWS certification or job interview

#### 4. **ec2-architecture-diagrams.md** (Visual Reference)
   - **Time to read:** 30-45 minutes
   - **Contains:**
     - Instance lifecycle state diagram
     - User Data execution timeline
     - Metadata service architecture
     - Security group flow (stateful)
     - EC2 scaling architecture
     - EC2 + RDS communication
   - **Best for:** Understanding flows visually
   - **When to use:** When you need to visualize concepts

#### 5. **troubleshooting-guide.md** (Problem Solving)
   - **Time to read:** 1-2 hours (reference)
   - **Covers:**
     - SSH connection issues
     - Instance launch problems
     - User Data failures
     - Application issues
     - Performance problems
     - Network & routing issues
     - Debugging toolkit
   - **Best for:** When something breaks
   - **When to use:** When you encounter errors

### User Data Scripts

#### **user-data-ubuntu-nodejs.sh**
- **What it does:** Installs Node.js v18, NPM, PM2 on Ubuntu 20
- **Runtime:** 3-4 minutes
- **Best for:** Node.js applications
- **Copy-paste ready:** Yes, just change GitHub repo URL

#### **user-data-amazon-linux-nodejs.sh**
- **What it does:** Installs Node.js v18, NPM, PM2 on Amazon Linux 2
- **Runtime:** 3-4 minutes
- **Best for:** AWS-optimized environments
- **Copy-paste ready:** Yes, just change GitHub repo URL

#### **user-data-ubuntu-python.sh**
- **What it does:** Installs Python 3, Flask, Gunicorn on Ubuntu 20
- **Runtime:** 3-4 minutes
- **Best for:** Python applications
- **Copy-paste ready:** Yes, just change GitHub repo URL

#### **user-data-monitoring.sh**
- **What it does:** Installs CloudWatch agent, sets up monitoring
- **Runtime:** 2 minutes
- **Best for:** Adding monitoring to any instance
- **Copy-paste ready:** Yes, can combine with other scripts

---

## 🎯 Learning Path (Recommended Order)

### Day 3 Schedule

**Morning (2-3 hours):**
1. Read `notes.md` (60-90 minutes)
   - Focus on: Fundamentals, AMI, Instance Types, Lifecycle
2. Watch AWS EC2 videos (30-45 minutes optional)
3. Quick quiz: Can you explain instance lifecycle states?

**Afternoon (2-3 hours):**
4. Follow `step-by-step-launch-guide.md`
   - Task 0: Set up security group (10 minutes)
   - Task 1: Launch instance (15 minutes)
   - Task 2: SSH connection (10 minutes)
   - Task 3: Test application (10 minutes)
   - Task 4: Monitor CloudWatch (15 minutes)
   - Task 5: Create custom AMI (20 minutes)
   - Task 6: Troubleshoot any issues (30 minutes)

**Evening (1-2 hours):**
5. Review `interview-questions.md` (30 minutes)
   - Read 5-10 questions from each category
6. Experiment (30-60 minutes)
   - Launch second instance from custom AMI
   - Test different instance types
   - Create CloudWatch alarm

---

## 🚀 Quick Start (5-Minute Summary)

**If you're in a hurry:**

1. **What is EC2?**
   - Virtual server in AWS cloud
   - Pay per hour
   - Choose OS, software, configuration
   - Scale instantly

2. **How to launch?**
   - EC2 Console → Launch Instances
   - Choose Ubuntu 20 AMI, t3.micro instance
   - Paste User Data script from `user-data-ubuntu-nodejs.sh`
   - Click Launch

3. **How to access?**
   - Wait 3-4 minutes for User Data to finish
   - SSH: `ssh -i key.pem ubuntu@PUBLIC_IP`
   - Test app: `curl http://localhost:3000`
   - Browser: `http://PUBLIC_IP:3000`

4. **How to monitor?**
   - CloudWatch → EC2 Metrics
   - Check CPU, Memory, Network
   - Create alarms for high CPU

5. **Next steps?**
   - Put behind ALB (Day 2 review)
   - Set up auto-scaling (Advanced)
   - Deploy real application (Production)

---

## 📊 Topics by Difficulty Level

### Beginner Topics
- What is EC2?
- Launching an instance (console)
- SSH connection
- Viewing logs
- Basic CloudWatch monitoring

### Intermediate Topics
- AMI creation
- User Data scripting
- Metadata service
- Security groups + IAM roles
- Instance types selection
- Auto Scaling Group basics

### Advanced Topics
- Custom AMI creation & management
- Spot instances + interruption handling
- Reserved Instances + cost optimization
- IAM role policy creation
- VPC endpoint setup
- Multi-AZ deployments
- Auto Scaling policies tuning
- Infrastructure as Code (Terraform)

---

## 🎓 Interview Preparation

### Must-Know Topics
```
✅ What is an AMI? (5-minute explanation)
✅ Explain instance lifecycle states
✅ User Data vs Metadata (difference)
✅ Spot vs On-Demand (when to use each)
✅ How do security groups work? (stateful)
✅ t3.micro vs m5.large (choose for workload)
✅ Can you change instance type? (how?)
✅ What's an Elastic IP? (when needed?)
```

### Interview Questions in This Material
- 35+ questions with detailed answers
- Real-world scenarios included
- Follow-up questions you might face
- Code examples (Node.js, Python, Java)

### Practice Mode
1. Read question without answer
2. Try to answer yourself (3-5 minutes)
3. Compare with provided answer
4. Explain to someone else (best learning!)

---

## 💾 Hands-On Checklist

By the end of Day 3, you should have completed:

```
EC2 Launch & Configuration:
  ☐ Created security group with SSH + HTTP rules
  ☐ Launched Ubuntu 20 instance (t3.micro)
  ☐ Configured User Data with Node.js setup
  ☐ Connected via SSH successfully
  ☐ Verified application running (pm2 status)
  ☐ Tested in browser (curl + HTTP)

Monitoring & Management:
  ☐ Viewed CloudWatch metrics (CPU, Network)
  ☐ Created CloudWatch alarm (high CPU)
  ☐ Checked instance logs (/var/log/cloud-init-output.log)
  ☐ Stopped and restarted instance
  ☐ Verified data persisted after restart

Advanced Tasks:
  ☐ Created custom AMI from instance
  ☐ Launched second instance from custom AMI
  ☐ Allocated Elastic IP (optional)
  ☐ Modified security group (add rule)
  ☐ Troubleshot at least one issue

Cost Awareness:
  ☐ Understands hourly billing model
  ☐ Can estimate monthly cost for instance type
  ☐ Knows how to stop/terminate to save costs
  ☐ Considered Spot instances for non-critical workloads
```

---

## 🔗 Integration with Other Days

### From Previous Days (Day 1 & 2)
- **VPC:** EC2 launches in your VPC (subnets)
- **Security Groups:** Manage EC2 inbound/outbound traffic
- **NACLs:** Second layer of firewall for EC2
- **IGW:** How public EC2 instances reach internet

### Prerequisites for Day 3
- ✅ VPC created (Day 1)
- ✅ Public & private subnets (Day 1)
- ✅ Security group with SSH + HTTP (Day 2)
- ✅ Understanding of routing (Day 1)

### Will Use in Future Days
- **Day 4:** Load balancing EC2 instances
- **Day 5:** Database with EC2 (RDS)
- **Day 6:** Auto-scaling & infrastructure
- **Day 7+:** Production deployment

---

## 🛠️ Troubleshooting Quick Links

**Can't SSH?** → See `troubleshooting-guide.md` → SSH Connection Issues

**App won't start?** → See `troubleshooting-guide.md` → Application Issues

**Can't reach database?** → See `troubleshooting-guide.md` → Network & Routing

**Instance too slow?** → See `troubleshooting-guide.md` → Performance Problems

**User Data didn't run?** → See `troubleshooting-guide.md` → User Data Failures

---

## 📝 Key Takeaways

### EC2 Fundamentals
- EC2 = Virtual server in AWS with pay-as-you-go pricing
- Instances launch from AMI (template)
- Instance types determine size/power (t3, m5, c5, etc.)
- Lifecycle: pending → running → stopped → terminated

### User Data & Metadata
- User Data = Setup script (runs once at launch)
- Metadata = Query instance info (anytime)
- Can auto-install software, deploy code with User Data

### Networking
- Public IP = Temporary, free (lost on stop/start)
- Elastic IP = Permanent, costs if unused
- Security Groups = Stateful firewall
- NACL = Stateless firewall (second layer)

### Scaling & HA
- Auto Scaling Group scales instances based on metrics
- Minimum 2 instances for high availability
- ALB distributes traffic across instances
- Graceful failover when instance fails

### Monitoring & Cost
- CloudWatch monitors CPU, Memory, Network
- Set alarms for auto-scaling
- t3 instances best for variable workloads (cheap)
- Reserved Instances save 40-60% vs on-demand

---

## 📞 Getting Help

**Material not clear?**
- Re-read the section with fresh perspective
- Check `ec2-architecture-diagrams.md` for visual explanation
- Look for similar question in `interview-questions.md`

**Stuck on task?**
- Check `troubleshooting-guide.md` for your specific error
- SSH into instance and read logs carefully
- Use debugging toolkit commands

**Interview coming up?**
- Practice answering questions aloud
- Draw architecture diagrams on whiteboard
- Do mock interviews with colleagues

---

## ✅ Completion Criteria

You've completed Day 3 when you can:

1. **Explain EC2 concepts**
   - ✅ What is EC2 and why use it?
   - ✅ What's an AMI?
   - ✅ Instance lifecycle states
   - ✅ Difference between User Data and Metadata

2. **Launch & manage instances**
   - ✅ Launch instance with security group
   - ✅ Connect via SSH
   - ✅ Verify application running
   - ✅ Monitor with CloudWatch
   - ✅ Create custom AMI
   - ✅ Stop/start/terminate instances

3. **Troubleshoot common issues**
   - ✅ Debug SSH connection problems
   - ✅ Fix User Data script errors
   - ✅ Handle application crashes
   - ✅ Performance diagnosis

4. **Answer interview questions**
   - ✅ 80%+ of interview questions correctly
   - ✅ Explain reasoning clearly
   - ✅ Provide real-world examples
   - ✅ Discuss trade-offs and best practices

---

## 🎓 Next Steps After Day 3

1. **Day 4: Advanced EC2**
   - Auto Scaling Groups in depth
   - Spot Instances strategy
   - Reserved Instances & cost optimization
   - Infrastructure as Code (CloudFormation, Terraform)

2. **Day 5: EC2 + Database**
   - Connect EC2 to RDS
   - Database security groups
   - Connection pooling
   - Backup strategies

3. **Day 6: Load Balancing**
   - Review ALB (from Day 2)
   - Multi-tier architecture
   - Health checks
   - Rolling deployments

4. **Weeks 2+: Production**
   - Deploy real application
   - Set up CI/CD pipeline
   - Implement monitoring & alerting
   - Disaster recovery planning

---

## 📚 Resource Summary

| File | Duration | Use Case |
|------|----------|----------|
| notes.md | 2-3 hrs | Learning theory |
| step-by-step-launch-guide.md | 2-3 hrs | Hands-on practice |
| interview-questions.md | 3-4 hrs | Interview prep |
| ec2-architecture-diagrams.md | 30-45 min | Visual reference |
| troubleshooting-guide.md | 1-2 hrs | Debugging |
| user-data-*.sh | Copy-paste | Automation |

**Total time investment:** 8-12 hours for complete mastery

---

Good luck on Day 3! 🚀 You're about to become an EC2 expert!
