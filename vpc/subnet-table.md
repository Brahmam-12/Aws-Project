# VPC Subnet Configuration Table

## 📋 Overview
This document provides a detailed breakdown of all subnets in the VPC configuration for Day 1 project.

---

## 🌐 VPC Details

| Property | Value |
|----------|-------|
| **VPC Name** | my-vpc / production-vpc |
| **VPC CIDR** | 10.0.0.0/16 |
| **Total IPs** | 65,536 |
| **Usable IPs** | 65,531 (AWS reserves 5 IPs per VPC) |
| **Region** | us-east-1 (or your selected region) |
| **DNS Hostnames** | Enabled |
| **DNS Resolution** | Enabled |

### AWS Reserved IPs in VPC (10.0.0.0/16)
- `10.0.0.0` - Network address
- `10.0.0.1` - VPC router
- `10.0.0.2` - DNS server
- `10.0.0.3` - Reserved for future use
- `10.0.255.255` - Network broadcast

---

## 📊 Subnet Configuration Table

| Subnet Name | Type | CIDR Block | AZ | Available IPs | Internet Access | Route Table | Use Case |
|-------------|------|------------|----|--------------:|-----------------|-------------|----------|
| **Public Subnet 1** | Public | 10.0.1.0/24 | us-east-1a | 251 | Direct (IGW) | Public RT | Web servers, Load balancers |
| **Public Subnet 2** | Public | 10.0.2.0/24 | us-east-1b | 251 | Direct (IGW) | Public RT | Web servers, Load balancers |
| **Private Subnet 1** | Private | 10.0.3.0/24 | us-east-1a | 251 | Via NAT | Private RT | Databases, Backend apps |
| **Private Subnet 2** | Private | 10.0.4.0/24 | us-east-1b | 251 | Via NAT | Private RT | Databases, Backend apps |

> **Note**: Each subnet has 256 total IPs, but AWS reserves 5 IPs per subnet, leaving 251 usable IPs.

---

## 🔢 IP Address Calculations

### CIDR Notation Explained

| CIDR | Subnet Mask | Total IPs | Usable IPs | Binary Network Bits |
|------|-------------|-----------|------------|---------------------|
| /16 | 255.255.0.0 | 65,536 | 65,531 | 16 bits |
| /24 | 255.255.255.0 | 256 | 251 | 24 bits |
| /28 | 255.255.255.240 | 16 | 11 | 28 bits |
| /32 | 255.255.255.255 | 1 | 1 | 32 bits (single IP) |

### Our VPC Structure

```
VPC: 10.0.0.0/16 (65,536 IPs)
├── Public Subnet 1:  10.0.1.0/24 (256 IPs)
│   └── Range: 10.0.1.0 - 10.0.1.255
├── Public Subnet 2:  10.0.2.0/24 (256 IPs)
│   └── Range: 10.0.2.0 - 10.0.2.255
├── Private Subnet 1: 10.0.3.0/24 (256 IPs)
│   └── Range: 10.0.3.0 - 10.0.3.255
└── Private Subnet 2: 10.0.4.0/24 (256 IPs)
    └── Range: 10.0.4.0 - 10.0.4.255
```

---

## 🚦 Route Table Configuration

### Public Route Table
**Name**: `public-route-table`  
**Associated Subnets**: Public Subnet 1, Public Subnet 2

| Destination | Target | Purpose |
|-------------|--------|---------|
| 10.0.0.0/16 | local | Internal VPC traffic |
| 0.0.0.0/0 | igw-xxxxx | Internet traffic via Internet Gateway |

### Private Route Table
**Name**: `private-route-table`  
**Associated Subnets**: Private Subnet 1, Private Subnet 2

| Destination | Target | Purpose |
|-------------|--------|---------|
| 10.0.0.0/16 | local | Internal VPC traffic |
| 0.0.0.0/0 | nat-xxxxx | Outbound internet via NAT Gateway |

---

## 🛡️ Security Configuration

### Default Network ACL (NACL)
- **Inbound Rules**: Allow all traffic (default)
- **Outbound Rules**: Allow all traffic (default)
- **Stateless**: Return traffic must be explicitly allowed

### Custom Security Groups (To be created)

#### Web Server Security Group
| Type | Protocol | Port | Source | Description |
|------|----------|------|--------|-------------|
| HTTP | TCP | 80 | 0.0.0.0/0 | Public web access |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Secure web access |
| SSH | TCP | 22 | Your-IP/32 | Admin access |

#### Database Security Group
| Type | Protocol | Port | Source | Description |
|------|----------|------|--------|-------------|
| MySQL/Aurora | TCP | 3306 | 10.0.0.0/16 | VPC only access |
| PostgreSQL | TCP | 5432 | 10.0.0.0/16 | VPC only access |

---

## 🌍 Availability Zones

| AZ | Public Subnet | Private Subnet | NAT Gateway |
|----|---------------|----------------|-------------|
| **us-east-1a** | 10.0.1.0/24 | 10.0.3.0/24 | ✅ Yes |
| **us-east-1b** | 10.0.2.0/24 | 10.0.4.0/24 | ❌ No (uses AZ-a NAT) |

> **Multi-AZ Benefits**:
> - High availability
> - Fault tolerance
> - Disaster recovery
> - Better performance (latency)

---

## 💰 Cost Considerations

### NAT Gateway Costs (Approximate)
- **Hourly charge**: ~$0.045/hour = ~$32.40/month
- **Data processing**: ~$0.045/GB processed
- **Alternative**: NAT Instance (cheaper but requires maintenance)

### Elastic IP Costs
- **In-use**: Free (when attached to running instance/NAT)
- **Idle**: ~$0.005/hour = ~$3.60/month

---

## 📈 Subnet Utilization Planning

### Recommended Resource Distribution

#### Public Subnets (10.0.1.0/24 & 10.0.2.0/24)
- Application Load Balancers (ALB)
- NAT Gateways
- Bastion Hosts / Jump Servers
- Public-facing web servers

#### Private Subnets (10.0.3.0/24 & 10.0.4.0/24)
- RDS Database instances
- ElastiCache clusters
- Application servers
- Backend microservices
- Lambda functions (in VPC)

---

## 🔄 Future Expansion

### Available CIDR Ranges for Additional Subnets
- 10.0.5.0/24 - 10.0.255.0/24 (251 additional /24 subnets available)

### Common Additional Subnets
```
10.0.5.0/24 - Database subnet AZ-1
10.0.6.0/24 - Database subnet AZ-2
10.0.7.0/24 - Cache layer subnet AZ-1
10.0.8.0/24 - Cache layer subnet AZ-2
10.0.9.0/24 - Management/Tools subnet
```

---

## ✅ Validation Checklist

- [ ] All subnet CIDR blocks are within VPC CIDR range
- [ ] No overlapping subnet CIDR blocks
- [ ] Public subnets have auto-assign public IP enabled
- [ ] Private subnets have auto-assign public IP disabled
- [ ] Public route table has route to Internet Gateway
- [ ] Private route table has route to NAT Gateway
- [ ] NAT Gateway is in a public subnet
- [ ] NAT Gateway has Elastic IP attached
- [ ] Subnets are distributed across multiple AZs

---

## 📝 Quick Reference Commands (AWS CLI)

```bash
# List all subnets in VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"

# Check route table associations
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxx"

# View NAT Gateway status
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-xxxxx"

# List available IPs in subnet
aws ec2 describe-subnets --subnet-ids subnet-xxxxx --query 'Subnets[0].AvailableIpAddressCount'
```

---

**Last Updated**: November 24, 2025  
**Status**: ✅ Configuration Complete  
**Version**: 1.0
