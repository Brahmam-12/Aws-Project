# AWS VPC Setup Guide - Step by Step 🚀

## Day 1 Complete Implementation Guide

This document provides detailed, step-by-step instructions for creating your VPC infrastructure in AWS Console.

---

## 📋 Prerequisites

- [ ] AWS Account created and verified
- [ ] IAM user with VPC full access permissions
- [ ] AWS Console access
- [ ] Region selected (e.g., us-east-1)

---

## 🎯 What We'll Build

```
VPC Architecture:
- 1 VPC (10.0.0.0/16)
- 2 Public Subnets across 2 AZs
- 2 Private Subnets across 2 AZs
- 1 Internet Gateway
- 1 NAT Gateway with Elastic IP
- 2 Route Tables (Public & Private)
```

**Estimated Time**: 30-45 minutes

---

## 📝 Step-by-Step Instructions

### Step 1: Create VPC

1. **Navigate to VPC Console**
   - Open AWS Console → Search "VPC" → Click "VPC"
   - Or visit: https://console.aws.amazon.com/vpc/

2. **Create VPC**
   - Click **"Create VPC"** button
   - Select **"VPC only"** (not VPC and more)

3. **Configure VPC Settings**
   ```
   Name tag:              my-vpc (or production-vpc)
   IPv4 CIDR block:       10.0.0.0/16
   IPv6 CIDR block:       No IPv6 CIDR block
   Tenancy:               Default
   Tags:                  Add tags if needed
   ```

4. **Click "Create VPC"**

✅ **Verification**: VPC should show "Available" state

---

### Step 2: Create Internet Gateway

1. **In VPC Console, go to "Internet Gateways"**
   - Left sidebar → Internet Gateways

2. **Create IGW**
   - Click **"Create internet gateway"**
   ```
   Name tag: my-igw
   ```
   - Click **"Create internet gateway"**

3. **Attach to VPC**
   - Select the newly created IGW
   - Click **"Actions"** → **"Attach to VPC"**
   - Select your VPC (`my-vpc`)
   - Click **"Attach internet gateway"**

✅ **Verification**: IGW state should show "Attached"

---

### Step 3: Create Subnets

#### Public Subnet 1

1. **Go to "Subnets"** in left sidebar
2. Click **"Create subnet"**
3. **Configure:**
   ```
   VPC ID:                    Select your VPC (my-vpc)
   Subnet name:               public-subnet-1
   Availability Zone:         us-east-1a (or first AZ in your region)
   IPv4 CIDR block:           10.0.1.0/24
   ```
4. Click **"Create subnet"**

#### Public Subnet 2

1. Click **"Create subnet"** again
2. **Configure:**
   ```
   VPC ID:                    Select your VPC (my-vpc)
   Subnet name:               public-subnet-2
   Availability Zone:         us-east-1b (or second AZ)
   IPv4 CIDR block:           10.0.2.0/24
   ```
3. Click **"Create subnet"**

#### Private Subnet 1

1. Click **"Create subnet"**
2. **Configure:**
   ```
   VPC ID:                    Select your VPC (my-vpc)
   Subnet name:               private-subnet-1
   Availability Zone:         us-east-1a (same as public-subnet-1)
   IPv4 CIDR block:           10.0.3.0/24
   ```
3. Click **"Create subnet"**

#### Private Subnet 2

1. Click **"Create subnet"**
2. **Configure:**
   ```
   VPC ID:                    Select your VPC (my-vpc)
   Subnet name:               private-subnet-2
   Availability Zone:         us-east-1b (same as public-subnet-2)
   IPv4 CIDR block:           10.0.4.0/24
   ```
3. Click **"Create subnet"**

✅ **Verification**: You should have 4 subnets total

---

### Step 4: Enable Auto-assign Public IP for Public Subnets

1. **Select public-subnet-1**
2. Click **"Actions"** → **"Edit subnet settings"**
3. Check **"Enable auto-assign public IPv4 address"**
4. Click **"Save"**

5. **Repeat for public-subnet-2**

✅ **Verification**: Public subnets should show auto-assign enabled

---

### Step 5: Create NAT Gateway

1. **Go to "NAT Gateways"** in left sidebar
2. Click **"Create NAT gateway"**
3. **Configure:**
   ```
   Name:                      my-nat-gateway
   Subnet:                    public-subnet-1 (MUST be public!)
   Connectivity type:         Public
   Elastic IP allocation ID:  Click "Allocate Elastic IP"
   ```
4. Click **"Create NAT gateway"**

⏳ **Wait**: NAT Gateway takes 3-5 minutes to become "Available"

✅ **Verification**: Status should show "Available" (refresh page)

---

### Step 6: Create Route Tables

#### Public Route Table

1. **Go to "Route Tables"** in left sidebar
2. Click **"Create route table"**
3. **Configure:**
   ```
   Name:          public-route-table
   VPC:           Select your VPC (my-vpc)
   ```
4. Click **"Create route table"**

5. **Add Internet Gateway Route**
   - Select the `public-route-table`
   - Go to **"Routes"** tab → Click **"Edit routes"**
   - Click **"Add route"**
   ```
   Destination:   0.0.0.0/0
   Target:        Internet Gateway → Select your IGW (my-igw)
   ```
   - Click **"Save changes"**

6. **Associate Public Subnets**
   - Stay on `public-route-table`
   - Go to **"Subnet associations"** tab
   - Click **"Edit subnet associations"**
   - Select **public-subnet-1** and **public-subnet-2**
   - Click **"Save associations"**

#### Private Route Table

1. Click **"Create route table"**
2. **Configure:**
   ```
   Name:          private-route-table
   VPC:           Select your VPC (my-vpc)
   ```
3. Click **"Create route table"**

4. **Add NAT Gateway Route**
   - Select the `private-route-table`
   - Go to **"Routes"** tab → Click **"Edit routes"**
   - Click **"Add route"**
   ```
   Destination:   0.0.0.0/0
   Target:        NAT Gateway → Select your NAT (my-nat-gateway)
   ```
   - Click **"Save changes"**

5. **Associate Private Subnets**
   - Stay on `private-route-table`
   - Go to **"Subnet associations"** tab
   - Click **"Edit subnet associations"**
   - Select **private-subnet-1** and **private-subnet-2**
   - Click **"Save associations"**

✅ **Verification**: Check route tables show correct associations

---

## 🧪 Testing Your VPC

### Test 1: Launch EC2 in Public Subnet

1. Launch EC2 instance in `public-subnet-1`
2. Assign Security Group allowing SSH (port 22) from your IP
3. Verify you can SSH into the instance using its public IP

### Test 2: Launch EC2 in Private Subnet

1. Launch EC2 instance in `private-subnet-1`
2. No public IP should be assigned
3. SSH from public instance (bastion host) to private instance
4. From private instance, run: `curl https://ifconfig.me`
   - Should show NAT Gateway's public IP (not blocked)

### Test 3: Verify Route Tables

**Public Route Table:**
```bash
aws ec2 describe-route-tables --route-table-ids rtb-xxxxx
```
Should show route: `0.0.0.0/0 → igw-xxxxx`

**Private Route Table:**
```bash
aws ec2 describe-route-tables --route-table-ids rtb-xxxxx
```
Should show route: `0.0.0.0/0 → nat-xxxxx`

---

## 🔍 Verification Checklist

Use this checklist to ensure everything is configured correctly:

### VPC Level
- [ ] VPC created with CIDR 10.0.0.0/16
- [ ] VPC state is "Available"
- [ ] DNS hostnames enabled
- [ ] DNS resolution enabled

### Internet Gateway
- [ ] IGW created and named
- [ ] IGW attached to VPC
- [ ] IGW state shows "Attached"

### Subnets
- [ ] 4 subnets created (2 public, 2 private)
- [ ] Subnets in 2 different Availability Zones
- [ ] Public subnets have auto-assign public IP enabled
- [ ] Private subnets have auto-assign public IP disabled
- [ ] No overlapping CIDR blocks

### NAT Gateway
- [ ] NAT Gateway created in public subnet
- [ ] Elastic IP allocated and attached
- [ ] NAT Gateway state is "Available"

### Route Tables
- [ ] Public route table created
- [ ] Public route table has route to IGW (0.0.0.0/0)
- [ ] Public subnets associated with public route table
- [ ] Private route table created
- [ ] Private route table has route to NAT (0.0.0.0/0)
- [ ] Private subnets associated with private route table

### Connectivity
- [ ] Can SSH into public subnet instance
- [ ] Private subnet instance can reach internet via NAT
- [ ] VPC internal communication works

---

## 🛠️ Alternative: Using AWS CLI

If you prefer command-line, here's the complete script:

```bash
# Set variables
VPC_CIDR="10.0.0.0/16"
REGION="us-east-1"

# 1. Create VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --region $REGION \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=my-vpc}]' \
  --query 'Vpc.VpcId' --output text)

echo "VPC Created: $VPC_ID"

# 2. Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-igw}]' \
  --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

echo "IGW Created and Attached: $IGW_ID"

# 3. Create Subnets
PUBLIC_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ${REGION}a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-1}]' \
  --query 'Subnet.SubnetId' --output text)

PUBLIC_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone ${REGION}b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-2}]' \
  --query 'Subnet.SubnetId' --output text)

PRIVATE_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.3.0/24 \
  --availability-zone ${REGION}a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-1}]' \
  --query 'Subnet.SubnetId' --output text)

PRIVATE_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.4.0/24 \
  --availability-zone ${REGION}b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-2}]' \
  --query 'Subnet.SubnetId' --output text)

echo "Subnets Created"

# 4. Enable auto-assign public IP for public subnets
aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_1 --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_2 --map-public-ip-on-launch

# 5. Allocate Elastic IP
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

# 6. Create NAT Gateway
NAT_GW=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_1 \
  --allocation-id $EIP_ALLOC \
  --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=my-nat-gateway}]' \
  --query 'NatGateway.NatGatewayId' --output text)

echo "NAT Gateway Creating: $NAT_GW (wait 3-5 minutes)"

# Wait for NAT Gateway to be available
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW

# 7. Create Route Tables
PUBLIC_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]' \
  --query 'RouteTable.RouteTableId' --output text)

PRIVATE_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=private-route-table}]' \
  --query 'RouteTable.RouteTableId' --output text)

# 8. Create Routes
aws ec2 create-route --route-table-id $PUBLIC_RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 create-route --route-table-id $PRIVATE_RT --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW

# 9. Associate Route Tables
aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_1 --route-table-id $PUBLIC_RT
aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_2 --route-table-id $PUBLIC_RT
aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_1 --route-table-id $PRIVATE_RT
aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_2 --route-table-id $PRIVATE_RT

echo "✅ VPC Setup Complete!"
echo "VPC ID: $VPC_ID"
```

---

## 📊 Cost Estimation

### Monthly Costs (Approximate)

| Resource | Cost |
|----------|------|
| VPC | Free |
| Subnets | Free |
| Internet Gateway | Free |
| Route Tables | Free |
| **NAT Gateway** | ~$32.40/month (0.045/hour) |
| **Data Processing (NAT)** | ~$0.045/GB |
| **Elastic IP (in-use)** | Free |
| **Total (minimal usage)** | ~$35-50/month |

💡 **Cost Saving Tips:**
- Delete NAT Gateway when not in use (dev/test)
- Use VPC Endpoints instead of NAT where possible
- Consider NAT Instance for low-traffic scenarios

---

## 🐛 Troubleshooting

### Issue: Can't SSH into public instance
**Solution:**
- Check Security Group allows port 22 from your IP
- Verify instance has public IP assigned
- Check public route table has IGW route

### Issue: Private instance can't reach internet
**Solution:**
- Verify NAT Gateway is in "Available" state
- Check private route table has NAT Gateway route
- Ensure NAT Gateway is in PUBLIC subnet

### Issue: Subnets not appearing in dropdown
**Solution:**
- Verify subnets are in the same VPC
- Check subnet state is "Available"
- Refresh AWS Console

### Issue: NAT Gateway stuck in "Pending"
**Solution:**
- Wait 3-5 minutes (normal)
- If >10 minutes, check Elastic IP was allocated
- Verify NAT is in public subnet

---

## 🎓 Next Steps (Day 2+)

1. **Security Hardening**
   - Create custom Security Groups
   - Configure Network ACLs
   - Enable VPC Flow Logs

2. **High Availability**
   - Add second NAT Gateway in AZ-2
   - Set up Auto Scaling Groups
   - Configure Application Load Balancer

3. **Monitoring**
   - Enable CloudWatch metrics
   - Set up CloudWatch alarms
   - Configure VPC Traffic Mirroring

4. **Advanced Networking**
   - VPC Peering
   - Transit Gateway
   - AWS PrivateLink/VPC Endpoints

---

## 📚 Additional Resources

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)
- [VPC Pricing](https://aws.amazon.com/vpc/pricing/)

---

**Created**: November 24, 2025  
**Status**: ✅ Complete  
**Estimated Completion Time**: 30-45 minutes  
**Difficulty**: Beginner

🎉 **Congratulations!** You've built a production-ready VPC architecture!
