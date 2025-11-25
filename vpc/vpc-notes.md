# DAY 1 - VPC MASTER 🌐

## 📅 Date: November 24, 2025

## 🎯 Learning Objectives
- Understand AWS VPC architecture
- Master subnet design and configuration
- Learn routing, NAT, and security concepts
- Prepare for VPC-related interview questions

---

## 📚 Resources Watched

### 1. AWS VPC Overview – freeCodeCamp
**Key Takeaways:**
- VPC (Virtual Private Cloud) is an isolated network in AWS cloud
- Provides complete control over network configuration
- Allows you to define IP address ranges, subnets, route tables, and network gateways
- VPCs are region-specific but span multiple Availability Zones

### 2. VPC Subnets, Route Tables, NAT – Be A Better Dev
**Key Takeaways:**
- **Subnets** divide VPC into smaller network segments
- **Public Subnets** have routes to Internet Gateway (IGW)
- **Private Subnets** don't have direct internet access
- **Route Tables** control traffic routing between subnets
- **NAT Gateway** allows private subnets to access internet while staying private

### 3. Security Group vs NACL – AWS Simplified
**Key Takeaways:**
- **Security Groups (SG)**: Stateful, instance-level firewall
- **Network ACLs (NACL)**: Stateless, subnet-level firewall
- SGs evaluate all rules before deciding, NACLs process rules in order
- SGs only have allow rules, NACLs have both allow and deny rules

---

## ✅ Tasks Completed

### 1. Create VPC
- **CIDR Block**: `10.0.0.0/16`
- **Name**: `my-vpc` or `production-vpc`
- **Region**: Selected based on your location
- **Provides**: 65,536 IP addresses (10.0.0.0 to 10.0.255.255)

### 2. Create 2 Public Subnets
- **Public Subnet 1**: `10.0.1.0/24` (256 IPs)
  - Availability Zone: us-east-1a (or your region equivalent)
  - Auto-assign public IPv4: Enabled
  
- **Public Subnet 2**: `10.0.2.0/24` (256 IPs)
  - Availability Zone: us-east-1b (or your region equivalent)
  - Auto-assign public IPv4: Enabled

### 3. Create 2 Private Subnets
- **Private Subnet 1**: `10.0.3.0/24` (256 IPs)
  - Availability Zone: us-east-1a
  - Auto-assign public IPv4: Disabled
  
- **Private Subnet 2**: `10.0.4.0/24` (256 IPs)
  - Availability Zone: us-east-1b
  - Auto-assign public IPv4: Disabled

### 4. Attach Internet Gateway
- **Name**: `my-igw`
- **Attached to**: VPC created above
- **Purpose**: Allows public subnets to communicate with the internet

### 5. Create Route Tables & Associate Subnets

**Public Route Table:**
- Routes traffic to Internet Gateway
- Associated with Public Subnets 1 & 2
- Routes:
  - `10.0.0.0/16` → local (VPC traffic)
  - `0.0.0.0/0` → Internet Gateway (internet traffic)

**Private Route Table:**
- Routes traffic to NAT Gateway
- Associated with Private Subnets 1 & 2
- Routes:
  - `10.0.0.0/16` → local (VPC traffic)
  - `0.0.0.0/0` → NAT Gateway (outbound internet only)

### 6. Add NAT Gateway
- **Name**: `my-nat-gateway`
- **Subnet**: Placed in Public Subnet 1
- **Elastic IP**: Allocated and associated
- **Purpose**: Allows private subnet instances to access internet for updates/patches

---

## 🔑 Key Concepts Learned

### CIDR (Classless Inter-Domain Routing)
- Notation for IP address ranges
- Format: `IP/prefix` (e.g., `10.0.0.0/16`)
- `/16` means first 16 bits are network bits, remaining 16 are host bits
- Smaller prefix = more IPs (e.g., `/16` > `/24`)

### VPC Components
1. **VPC**: Isolated network environment
2. **Subnets**: Network segments within VPC
3. **Internet Gateway**: Enables internet access for VPC
4. **NAT Gateway**: Outbound internet for private subnets
5. **Route Tables**: Traffic routing rules
6. **Security Groups**: Instance-level firewall
7. **NACLs**: Subnet-level firewall

### Public vs Private Subnets
| Feature | Public Subnet | Private Subnet |
|---------|--------------|----------------|
| Internet Access | Direct via IGW | Via NAT Gateway only |
| Public IP | Yes | No |
| Use Case | Web servers, load balancers | Databases, application servers |
| Route to IGW | Yes | No |

---

## 🎓 Best Practices Applied

1. ✅ **Multi-AZ Design**: Subnets across 2 Availability Zones for high availability
2. ✅ **Proper CIDR Planning**: Non-overlapping CIDR blocks
3. ✅ **Least Privilege**: Private subnets for sensitive resources
4. ✅ **Internet Gateway for Public Access**: Only public subnets route to IGW
5. ✅ **NAT Gateway for Updates**: Private instances can download patches
6. ✅ **Logical Naming**: Clear, descriptive names for all resources

---

## 🚀 Next Steps

- [ ] Add VPC Flow Logs for network monitoring
- [ ] Configure Security Groups for EC2 instances
- [ ] Set up Network ACLs for additional security layer
- [ ] Create VPC Peering connections (Day 2+)
- [ ] Implement VPN connection for hybrid cloud
- [ ] Test connectivity between subnets

---

## 💡 Common Pitfalls to Avoid

1. **Forgetting NAT Gateway**: Private subnets won't have internet access
2. **Wrong Route Table Association**: Check subnet associations carefully
3. **CIDR Overlap**: Ensure subnet CIDRs don't overlap
4. **Single AZ**: Always use multiple AZs for production
5. **NAT in Private Subnet**: NAT Gateway must be in public subnet
6. **Missing IGW**: Public subnets need IGW in route table

---

## 📊 Architecture Diagram

```
Internet
    |
    v
Internet Gateway (IGW)
    |
    +------------------+------------------+
    |                                     |
Public Subnet 1              Public Subnet 2
(10.0.1.0/24)                (10.0.2.0/24)
AZ-1                         AZ-2
    |                                     |
NAT Gateway                               |
    |                                     |
    +------------------+------------------+
                       |
                       v
    +------------------+------------------+
    |                                     |
Private Subnet 1             Private Subnet 2
(10.0.3.0/24)                (10.0.4.0/24)
AZ-1                         AZ-2
[Databases]                  [App Servers]
```

---

## 📝 Notes & Observations

- NAT Gateway is a managed AWS service (no maintenance required)
- NAT Gateway costs money per hour + data processed
- For cost savings in dev/test: Can use NAT Instance instead
- VPC CIDR cannot be changed after creation (plan carefully!)
- Maximum 5 VPCs per region (soft limit, can be increased)

---

**Status**: ✅ Completed  
**Time Spent**: ~2-3 hours  
**Confidence Level**: 🟢 High
