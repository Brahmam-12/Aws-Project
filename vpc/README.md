# AWS 30-Day Learning Journey 🚀

## Day 1: VPC Master ✅

Welcome to Day 1 of your AWS learning journey! This project contains comprehensive documentation and resources for mastering AWS VPC concepts.

---

## 📁 Project Structure

```
aws-project/
├── README.md                    # This file - project overview
├── vpc-notes.md                 # Complete learning notes and concepts
├── subnet-table.md              # Detailed subnet configuration tables
├── interview-questions.md       # Interview Q&A with detailed explanations
├── vpc-setup-guide.md          # Step-by-step setup instructions
└── vpc-diagram.png             # Architecture diagram (to be added)
```

---

## 📚 Quick Navigation

### 📖 [VPC Notes](./vpc-notes.md)
Complete learning documentation including:
- VPC architecture concepts
- Tasks completed checklist
- Key concepts learned
- Best practices
- Architecture diagrams
- Common pitfalls to avoid

### 📊 [Subnet Configuration Table](./subnet-table.md)
Detailed subnet information including:
- VPC and subnet CIDR blocks
- IP address calculations
- Route table configurations
- Security group templates
- AWS CLI commands

### 🎯 [Interview Questions](./interview-questions.md)
Master these critical questions:
1. Difference between Security Groups & NACLs
2. What happens if private subnet has no NAT?
3. Why do companies use multiple subnets?
4. What is CIDR?

Plus bonus questions and study tips!

### 🛠️ [VPC Setup Guide](./vpc-setup-guide.md)
Step-by-step implementation guide:
- AWS Console instructions
- AWS CLI scripts
- Testing procedures
- Troubleshooting tips
- Cost estimation

---

## ✅ Day 1 Tasks Completed

- [x] Create VPC (CIDR: 10.0.0.0/16)
- [x] Create 2 Public Subnets (10.0.1.0/24, 10.0.2.0/24)
- [x] Create 2 Private Subnets (10.0.3.0/24, 10.0.4.0/24)
- [x] Attach Internet Gateway
- [x] Create Route Tables & associate subnets
- [x] Add NAT Gateway
- [x] Document everything comprehensively

---

## 🎥 Video Resources Watched

1. **AWS VPC Overview** – freeCodeCamp
   - Understanding VPC fundamentals
   - Core components and concepts

2. **VPC Subnets, Route Tables, NAT** – Be A Better Dev
   - Subnet design patterns
   - Routing configurations
   - NAT Gateway implementation

3. **Security Group vs NACL** – AWS Simplified
   - Stateful vs stateless firewalls
   - Security layer best practices

---

## 🏗️ Architecture Overview

```
Internet
    |
    v
[Internet Gateway]
    |
    +------------------+------------------+
    |                                     |
[Public Subnet 1]              [Public Subnet 2]
  10.0.1.0/24                    10.0.2.0/24
  AZ: us-east-1a                 AZ: us-east-1b
    |                                     |
[NAT Gateway]                             |
    |                                     |
    +------------------+------------------+
                       |
    +------------------+------------------+
    |                                     |
[Private Subnet 1]             [Private Subnet 2]
  10.0.3.0/24                    10.0.4.0/24
  AZ: us-east-1a                 AZ: us-east-1b
```

---

## 🎓 Key Learning Outcomes

After completing Day 1, you should be able to:

✅ Explain VPC architecture and components  
✅ Design multi-tier subnet architectures  
✅ Configure routing for public and private subnets  
✅ Understand the difference between Security Groups and NACLs  
✅ Calculate CIDR blocks and IP ranges  
✅ Implement NAT Gateway for private subnet internet access  
✅ Deploy highly available, multi-AZ architectures  
✅ Answer VPC-related interview questions confidently  

---

## 💡 Quick Reference

### VPC Details
- **VPC CIDR**: 10.0.0.0/16 (65,536 IPs)
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24
- **Private Subnets**: 10.0.3.0/24, 10.0.4.0/24
- **Availability Zones**: 2 (us-east-1a, us-east-1b)

### Key Components
- ✅ 1 VPC
- ✅ 4 Subnets (2 public, 2 private)
- ✅ 1 Internet Gateway
- ✅ 1 NAT Gateway
- ✅ 2 Route Tables
- ✅ Elastic IP for NAT

---

## 🚀 Next Steps

### Day 2 Preview
- EC2 instance deployment in VPC
- Security Group configuration
- Bastion host setup
- Network ACL implementation

### Additional Practice
- [ ] Create VPC in different region
- [ ] Add VPC Flow Logs
- [ ] Implement VPC Endpoints
- [ ] Set up VPC Peering

---

## 🔗 Useful Links

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [VPC Pricing Calculator](https://calculator.aws/)
- [CIDR Calculator](https://cidr.xyz)
- [AWS Network Workshops](https://networking.workshop.aws/)

---

## 📝 Study Notes

### Interview Preparation
- Review `interview-questions.md` daily
- Practice drawing VPC diagrams on whiteboard
- Explain concepts out loud
- Time yourself answering questions

### Hands-On Practice
- Rebuild VPC from scratch without guide
- Try CLI commands instead of console
- Break things intentionally and fix them
- Document your troubleshooting process

---

## 💰 Cost Management

**Monthly Estimate**: ~$35-50 (mainly NAT Gateway)

**Cost Breakdown**:
- VPC, Subnets, IGW, Route Tables: **Free**
- NAT Gateway: **~$32/month**
- Data transfer through NAT: **~$0.045/GB**
- Elastic IP (in-use): **Free**

**Savings Tips**:
- Delete NAT Gateway when not actively learning
- Use VPC Endpoints where possible
- Consider NAT Instance for practice

---

## 🐛 Common Issues & Solutions

See `vpc-setup-guide.md` troubleshooting section for:
- SSH connectivity problems
- NAT Gateway issues
- Route table configuration errors
- Subnet association problems

---

## 📊 Progress Tracker

| Day | Topic | Status | Confidence |
|-----|-------|--------|-----------|
| 1 | VPC Master | ✅ Complete | 🟢 High |
| 2 | EC2 & Security | 🔄 Next | - |
| 3 | Load Balancing | ⏳ Pending | - |
| ... | ... | ... | ... |

---

## 🙏 Acknowledgments

- freeCodeCamp for comprehensive VPC tutorial
- Be A Better Dev for practical implementation guidance
- AWS Simplified for security concepts clarification
- AWS Documentation team for detailed reference materials

---

## 📧 Connect

Feel free to reach out for questions or collaboration:
- GitHub: [Your GitHub Profile]
- LinkedIn: [Your LinkedIn Profile]
- Email: [Your Email]

---

**Last Updated**: November 24, 2025  
**Status**: Day 1 Complete ✅  
**Next Update**: Day 2 (Tomorrow)

---

## 🎯 Daily Commitment

> "Master one AWS service deeply each day. Consistency beats intensity."

**Time Investment**: 2-3 hours per day  
**Progress**: 1/30 days complete  
**Momentum**: 🔥 Strong start!

---

Keep learning, keep building! 🚀

