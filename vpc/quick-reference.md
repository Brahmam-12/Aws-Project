# Quick Reference Card - VPC Testing 🚀

## 🎯 Your Mission Today

Test your VPC by launching 2 EC2 instances and verifying all connectivity paths.

---

## 📋 Quick Setup Steps

### 1. Create Security Groups (5 minutes)

**Web Server SG:**
- SSH (22) from My IP
- HTTP (80) from Anywhere
- HTTPS (443) from Anywhere

**Private Server SG:**
- SSH (22) from VPC CIDR (10.0.0.0/20)
- All ICMP from VPC CIDR

### 2. Launch 2 EC2 Instances (10 minutes)

**Bastion Host:**
- Amazon Linux 2023, t2.micro
- Public Subnet 1 (10.0.1.0/24)
- Auto-assign public IP: Enabled
- Security Group: web-server-sg

**Private Server:**
- Amazon Linux 2023, t2.micro
- Private Subnet 1 (10.0.3.0/24)
- Auto-assign public IP: Disabled
- Security Group: private-server-sg

### 3. Run Tests (15 minutes)

See detailed testing guide in `vpc-testing-guide.md`

---

## 🔑 Essential Commands

### Connect to Bastion (From Your PC):
```powershell
ssh -i my-vpc-key.pem ec2-user@<BASTION-PUBLIC-IP>
```

### Test Internet from Bastion:
```bash
ping -c 4 google.com
curl ifconfig.me
```

### Connect to Private Server (From Bastion):
```bash
ssh -i ~/.ssh/my-vpc-key.pem ec2-user@10.0.3.x
```

### Test NAT Gateway (From Private Server):
```bash
ping -c 4 google.com
curl ifconfig.me     # Should show NAT Gateway IP
```

---

## ✅ Success Checklist

- [ ] Created 2 security groups
- [ ] Launched bastion host in public subnet
- [ ] Launched private server in private subnet
- [ ] Can SSH to bastion from internet ✅
- [ ] Bastion can reach internet ✅
- [ ] Can SSH from bastion to private server ✅
- [ ] Private server can reach internet via NAT ✅
- [ ] Cannot SSH directly to private server from internet ✅

---

## 🎓 What You're Learning

**Traffic Flow:**
```
Internet → IGW → Public Subnet → Bastion ✅
Internet → Private Subnet ❌ (Blocked)
Private Server → NAT → IGW → Internet ✅ (Outbound only)
Bastion → Private Server ✅ (Internal VPC)
```

**Key Concept:**
- Public subnet = Internet can reach it
- Private subnet = Hidden from internet, but can reach internet via NAT
- NAT = One-way door (out only, not in)

---

## 🆘 Quick Troubleshooting

**Can't SSH to bastion?**
→ Check Security Group has SSH from your IP
→ Verify public subnet route table has IGW route

**Bastion can't reach internet?**
→ Check route table: 0.0.0.0/0 → igw-xxx
→ Verify IGW is attached to VPC

**Can't connect to private server?**
→ Check private-server-sg allows SSH from VPC
→ Verify you copied the key file to bastion

**Private server can't reach internet?**
→ Check NAT Gateway is "Available"
→ Check private route table: 0.0.0.0/0 → nat-xxx
→ Verify NAT is in public subnet

---

## 💰 Cost Reminder

**Current monthly cost:** ~$35-40
- NAT Gateway: ~$32/month
- EC2 t2.micro: Free tier (first 750 hours/month)

**After testing, STOP or TERMINATE:**
- EC2 instances (Stop if you want to practice again)
- NAT Gateway (Delete if done, can recreate later)

---

## 📚 Files Created

1. `README.md` - Project overview
2. `vpc-notes.md` - Complete VPC concepts
3. `subnet-table.md` - Subnet configuration details
4. `interview-questions.md` - Interview prep
5. `vpc-setup-guide.md` - Step-by-step AWS setup
6. `vpc-testing-guide.md` - **← START HERE FOR TESTING**
7. `quick-reference.md` - This file

---

## 🎯 Next Steps After Testing

1. Take a screenshot of your successful connections
2. Document what you learned
3. Answer the 4 interview questions without looking
4. Try breaking and fixing things to learn deeper
5. Move to Day 2 (EC2 deep dive)

---

**Good luck! 🚀 You've got this!**
