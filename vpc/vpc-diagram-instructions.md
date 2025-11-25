# VPC Architecture Diagram

> **Note**: This is a placeholder file. To complete your Day 1 project, please create a VPC architecture diagram.

---

## 🎨 How to Create Your VPC Diagram

### Option 1: Use Draw.io (Free, Recommended)
1. Visit [draw.io](https://app.diagrams.net/)
2. Choose "AWS Architecture" template
3. Use AWS shape library (includes VPC, subnets, IGW, NAT icons)
4. Export as PNG and save as `vpc-diagram.png`

### Option 2: Use Lucidchart
1. Visit [Lucidchart](https://www.lucidchart.com/)
2. Select AWS Architecture shapes
3. Create your VPC diagram
4. Export and save here

### Option 3: Use AWS Architecture Icons (Official)
1. Download [AWS Architecture Icons](https://aws.amazon.com/architecture/icons/)
2. Use PowerPoint, Visio, or similar tool
3. Create diagram using official icons
4. Save as `vpc-diagram.png`

### Option 4: Use CloudCraft
1. Visit [CloudCraft](https://www.cloudcraft.co/)
2. Design your VPC architecture
3. Export as PNG

---

## 📋 What to Include in Your Diagram

Your VPC diagram should show:

### ✅ Required Components
- [ ] VPC box/boundary (10.0.0.0/16)
- [ ] Internet Gateway (outside/attached to VPC)
- [ ] 2 Public Subnets (10.0.1.0/24, 10.0.2.0/24)
- [ ] 2 Private Subnets (10.0.3.0/24, 10.0.4.0/24)
- [ ] NAT Gateway (in public subnet)
- [ ] Route Tables (show associations)
- [ ] Availability Zone labels (us-east-1a, us-east-1b)

### ✨ Nice-to-Have
- [ ] Traffic flow arrows
- [ ] Color coding (public = green, private = orange)
- [ ] Security Group icons
- [ ] Sample EC2 instances
- [ ] Legend/key

---

## 🖼️ Example Layout

```
┌─────────────────────────────────────────────────────────────┐
│  VPC: 10.0.0.0/16                                           │
│                                                             │
│  ┌────────────────────────┐  ┌────────────────────────┐   │
│  │ Availability Zone 1a   │  │ Availability Zone 1b   │   │
│  │                        │  │                        │   │
│  │  ┌──────────────────┐  │  │  ┌──────────────────┐  │   │
│  │  │ Public Subnet 1  │  │  │  │ Public Subnet 2  │  │   │
│  │  │  10.0.1.0/24     │  │  │  │  10.0.2.0/24     │  │   │
│  │  │                  │  │  │  │                  │  │   │
│  │  │  [NAT Gateway]   │  │  │  │                  │  │   │
│  │  └──────────────────┘  │  │  └──────────────────┘  │   │
│  │                        │  │                        │   │
│  │  ┌──────────────────┐  │  │  ┌──────────────────┐  │   │
│  │  │ Private Subnet 1 │  │  │  │ Private Subnet 2 │  │   │
│  │  │  10.0.3.0/24     │  │  │  │  10.0.4.0/24     │  │   │
│  │  │                  │  │  │  │                  │  │   │
│  │  │  [EC2 Instance]  │  │  │  │  [RDS Database]  │  │   │
│  │  └──────────────────┘  │  │  └──────────────────┘  │   │
│  └────────────────────────┘  └────────────────────────┘   │
│                                                             │
│  [Internet Gateway]                                         │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
     Internet
```

---

## 🎯 Diagram Checklist

Before considering your diagram complete:

- [ ] Shows hierarchical structure (VPC → Subnets)
- [ ] Clearly labels all CIDR blocks
- [ ] Indicates Availability Zones
- [ ] Shows Internet Gateway connection
- [ ] Shows NAT Gateway location
- [ ] Illustrates public vs private subnets
- [ ] Includes routing information (optional)
- [ ] Uses consistent colors/styling
- [ ] Has a title and date
- [ ] Saved as `vpc-diagram.png` in this directory

---

## 💡 Pro Tips

1. **Keep it simple**: Don't over-complicate your first diagram
2. **Use colors**: Green for public, orange for private, blue for data
3. **Show traffic flow**: Use arrows to indicate data movement
4. **Label everything**: CIDR blocks, names, and purpose
5. **Save high resolution**: Ensure diagram is readable when zoomed

---

## 📸 When You're Done

Replace this file with your actual `vpc-diagram.png` image!

Your final project structure should be:
```
aws-project/
├── README.md
├── vpc-notes.md
├── subnet-table.md
├── interview-questions.md
├── vpc-setup-guide.md
└── vpc-diagram.png  ← Your actual diagram here!
```

---

**Quick ASCII Diagram Alternative**

If you prefer a simple text-based diagram, here's a clean version:

```
                     ┌─────────────┐
                     │  Internet   │
                     └──────┬──────┘
                            │
                     ┌──────▼──────┐
                     │     IGW     │
                     └──────┬──────┘
                            │
    ┌───────────────────────┴───────────────────────┐
    │                                               │
┌───▼────────────────────┐      ┌──────────────────▼────┐
│  Public Subnet 1       │      │  Public Subnet 2      │
│  10.0.1.0/24           │      │  10.0.2.0/24          │
│  AZ: us-east-1a        │      │  AZ: us-east-1b       │
│  ┌──────────────┐      │      │                       │
│  │ NAT Gateway  │      │      │                       │
│  └──────┬───────┘      │      │                       │
└─────────┼──────────────┘      └───────────────────────┘
          │                              
    ┌─────┴──────────────────────────┐
    │                                │
┌───▼────────────────────┐   ┌───────▼───────────────┐
│  Private Subnet 1      │   │  Private Subnet 2     │
│  10.0.3.0/24           │   │  10.0.4.0/24          │
│  AZ: us-east-1a        │   │  AZ: us-east-1b       │
│  ┌──────────────┐      │   │  ┌──────────────┐     │
│  │  App Server  │      │   │  │   Database   │     │
│  └──────────────┘      │   │  └──────────────┘     │
└────────────────────────┘   └───────────────────────┘
```

---

**Status**: 📝 Diagram Pending  
**Action Required**: Create and add your VPC diagram!

Good luck! 🎨
