# DAY 3 - REAL-WORLD EC2 SCENARIOS 🏗️

## Production-Grade Architecture Patterns

---

## Scenario 1: Scaling a Startup's Web Application

### Background
A startup has built a Node.js web app with growing traffic:
- 100 requests/second during peak
- Traffic varies throughout the day
- $500/month budget for infrastructure
- Need 99.9% uptime
- Small DevOps team (1 person)

### Current Problem
- Single t3.micro instance
- Crashes during traffic spikes
- No monitoring/alerting
- Manual restarts when it breaks

### Architecture Solution

```
                    User Traffic
                         │
                         ↓
    ┌─────────────────────────────────────┐
    │ Application Load Balancer           │
    │ (Always ON - On-Demand)             │
    │ Cost: $16/month                     │
    └─────────────────┬───────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ↓             ↓             ↓
    ┌────────┐   ┌────────┐   ┌────────┐
    │EC2 #1  │   │EC2 #2  │   │EC2 #3  │
    │Spot    │   │Spot    │   │Spot    │
    │t3.small│   │t3.small│   │t3.small│
    │$0.025/h│   │$0.025/h│   │$0.025/h│
    └────────┘   └────────┘   └────────┘
        │            │            │
        └────────────┼────────────┘
                     │
                     ↓
        ┌────────────────────────┐
        │ RDS PostgreSQL         │
        │ Multi-AZ (Reliable)    │
        │ Cost: $100/month       │
        └────────────────────────┘

Auto-Scaling Configuration:
├── Min: 2 (high availability)
├── Desired: 3 (baseline)
├── Max: 10 (during viral spike)
└── Metrics: CPU > 70% → Add 2 instances
            CPU < 30% → Remove 1 instance

Total Monthly Cost:
├── ALB: $16
├── 3 × t3.small Spot (avg 24h): $54
├── RDS: $100
├── Snapshots: $15
└── Total: ~$185/month ✅ (Under budget!)

Benefits:
✅ High availability (if 1 instance dies, 2 others handle)
✅ Auto-scales with traffic (no manual intervention)
✅ Cost-optimized (Spot + On-Demand hybrid)
✅ Monitoring built-in (CloudWatch)
✅ Self-healing (bad instances replaced)
```

### Implementation Steps

```bash
# Step 1: Create security groups
aws ec2 create-security-group \
  --group-name web-app-alb-sg \
  --description "ALB security group"

aws ec2 create-security-group \
  --group-name web-app-ec2-sg \
  --description "EC2 security group"

# Step 2: Create launch template (for auto-scaling)
aws ec2 create-launch-template \
  --launch-template-name web-app-v1 \
  --launch-template-data '{
    "ImageId": "ami-0c55b...",
    "InstanceType": "t3.small",
    "UserData": "base64-encoded-user-data",
    "SecurityGroupIds": ["sg-web-app-ec2"]
  }'

# Step 3: Create Auto Scaling Group
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name web-app-asg \
  --launch-template LaunchTemplateName=web-app-v1 \
  --min-size 2 \
  --desired-capacity 3 \
  --max-size 10 \
  --vpc-zone-identifier "subnet-1,subnet-2"

# Step 4: Create ALB
aws elbv2 create-load-balancer \
  --name web-app-alb \
  --subnets subnet-public-1 subnet-public-2 \
  --security-groups sg-web-app-alb

# Step 5: Add scaling policy
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name web-app-asg \
  --policy-name scale-up \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration "TargetValue=70.0,PredefinedMetricSpecification={PredefinedMetricType=ASGAverageCPUUtilization}"
```

### Monitoring & Alerting

```
CloudWatch Alarms:

1. High CPU (Scale Up)
   └── If AVG CPU > 70% for 5 min → Add instances

2. Low CPU (Scale Down)
   └── If AVG CPU < 30% for 10 min → Remove instances

3. Unhealthy Targets
   └── If any target fails health check → Replace

4. RDS Connection Issues
   └── Alert ops team → Manual investigation

5. Cost Alert
   └── Monthly bill > $250 → Alert budget owner
```

### Cost Breakdown (Per Month)

```
Hour-by-hour simulation:

Midnight-8 AM (Low Traffic):
├── ALB: Running ($16/month flat)
├── 2 EC2 instances (min): 8 hrs × 2 × $0.025 = $0.40
├── RDS: Running ($100/month flat)
└── Daily cost: ~$4

8 AM-12 PM (Morning Peak):
├── 5 instances (scaled up): 4 hrs × 5 × $0.025 = $0.50
└── Daily addition: ~$0.50

12 PM-5 PM (Lunch → Afternoon):
├── 4 instances (scaling down): 5 hrs × 4 × $0.025 = $0.50
└── Daily addition: ~$0.50

5 PM-Midnight (Evening):
├── 3 instances (back to desired): 7 hrs × 3 × $0.025 = $0.53
└── Daily addition: ~$0.50

Daily cost: ~$5.50
Monthly: 30 × $5.50 = $165 + $100 RDS = $265/month

Yearly savings vs manual scaling: ~$3,000! 💰
```

---

## Scenario 2: Running Batch Processing Jobs

### Background
A data science company runs daily ML model training:
- 100 GB training dataset
- Takes 2-3 hours per job
- Runs daily at 2 AM
- Cost is highest concern

### Architecture Solution

```
Scheduled Batch Job (Using EventBridge + Auto-Scaling)

2:00 AM Daily:
     │
     ↓
┌─────────────────┐
│ EventBridge     │ (Free service)
│ Cron trigger    │
└────────┬────────┘
         │
         ↓
    Lambda Function
    (Start/Stop logic)
         │
         ├─→ GET Spot Price
         │   (Check current rate)
         │
         ├─→ Launch 10 Spot Instances
         │   (c5.2xlarge - high CPU)
         │   (Cost: $0.17/hr each = $1.70/hr total)
         │
         └─→ Start EC2 instances
            
Parallel Job Execution:
─────────────────────
Instance 1 ──→ Training subset 1 (30 min)
Instance 2 ──→ Training subset 2 (30 min)
Instance 3 ──→ Training subset 3 (30 min)
... (10 instances total)
Instance 10 → Training subset 10 (30 min)

       All done in 30 minutes! ⚡

5:00 AM:
     │
     ↓
Lambda Aggregates Results
     │
     ↓
Uploads to S3
     │
     ↓
Terminates all Spot instances
     │
     ↓
Cost: 3 hours × 10 instances × $0.17/hr = $5.10 ✅

vs Daily On-Demand:
├── 1 c5.2xlarge 24/7
├── Cost: 365 days × 24 hrs × $0.34/hr = $2,982/year
└── Batch approach: 365 × $5.10 = $1,861/year
└── Savings: $1,121/year! 💰
```

### Implementation

```bash
# Step 1: Create security group for batch jobs
aws ec2 create-security-group \
  --group-name batch-processing-sg \
  --description "Batch processing job instances"

# Step 2: Create launch template
aws ec2 create-launch-template \
  --launch-template-name batch-training-v1 \
  --launch-template-data '{
    "ImageId": "ami-batch-ml-stack",
    "InstanceType": "c5.2xlarge",
    "UserData": "#!/bin/bash\naws s3 cp s3://data-bucket/training.csv ./\npython train_model.py\naws s3 cp ./model.pkl s3://models-bucket/\n"
  }'

# Step 3: Create Spot Fleet Request (for parallel execution)
aws ec2 request-spot-fleet \
  --spot-fleet-request-config '{
    "IamFleetRole": "arn:aws:iam::123456789:role/fleet-role",
    "AllocationStrategy": "lowestPrice",
    "TargetCapacity": 10,
    "SpotPrice": "0.25",
    "LaunchSpecifications": [
      {
        "ImageId": "ami-batch-ml-stack",
        "InstanceType": "c5.2xlarge",
        "SecurityGroups": [{"GroupId": "sg-batch"}]
      }
    ]
  }'

# Step 4: Create Lambda function for orchestration
# (Pseudocode)
def batch_training_handler(event, context):
    # 1. Launch 10 Spot instances
    # 2. Wait for all to start
    # 3. Monitor training progress
    # 4. Once complete, aggregate results
    # 5. Terminate all instances
    # 6. Email results to team
    pass

# Step 5: Create EventBridge rule
aws events put-rule \
  --name daily-batch-training \
  --schedule-expression "cron(0 2 * * ? *)" \  # 2 AM UTC daily
  --state ENABLED

aws events put-targets \
  --rule daily-batch-training \
  --targets "Id"="1","Arn"="arn:aws:lambda:us-east-1:123456789:function:batch-orchestrator"
```

### Cost Comparison

| Approach | Monthly Cost | Annual | Benefit |
|----------|---|---|---|
| **Spot Batch (10 instances × 3 hrs)** | $153 | $1,836 | ✅ Cheapest |
| **Reserved c5.2xlarge (always on)** | $249 | $2,988 | 62% more than batch |
| **On-Demand c5.2xlarge (always on)** | $249 | $2,988 | 62% more than batch |

**Annual Savings: $1,152!** 🎉

---

## Scenario 3: Dev/Test Environment (Minimal Cost)

### Background
Small team needs dev and staging environments:
- Dev: Low traffic, always off outside work hours
- Staging: Mirror production (but smaller)
- Budget: $100/month total
- Goal: Simulate production without the cost

### Solution

```
Development Environment

Weekday 9 AM - 5 PM (Business Hours):
    Running
    ├── 1 × t3.small (code development)
    ├── RDS t3.micro (test database)
    └── Cost: 8 hrs × 5 days × ($0.025 + $0.017) = $8.40/week

After Hours / Weekends:
    STOPPED (no charges for compute)
    └── Cost: Only EBS storage (~$5/month)

Monthly: ~$40 (compute) + $20 (storage) = $60

Staging Environment

Always running (mirrors production):
    ├── 1 × t3.medium (similar to prod)
    ├── RDS t3.small
    └── Cost: 24/7 = $60/month compute + $15 storage = $75/month

Total Monthly: $60 + $75 = $135/month

But budget is $100! Solution:
├── Dev: Stop after hours (save $25/month)
├── Staging: Use smaller instance (save $15/month)
└── Total: ~$95/month ✅
```

### Automation (Stop/Start Schedule)

```bash
# Use AWS Systems Manager to auto stop/start

# Create document
aws ssm create-document \
  --content '{
    "schemaVersion": "2.2",
    "description": "Stop dev instances after hours",
    "mainSteps": [
      {
        "action": "aws:executeScript",
        "name": "StopInstances",
        "inputs": {
          "Runtime": "python3.8",
          "Handler": "stop_handler",
          "Script": "..."
        }
      }
    ]
  }' \
  --name stop-dev-instances

# Create EventBridge rule
aws events put-rule \
  --name stop-dev-after-hours \
  --schedule-expression "cron(0 18 ? * MON-FRI *)"  # 6 PM weekdays

# Restart next morning
aws events put-rule \
  --name start-dev-morning \
  --schedule-expression "cron(0 8 ? * MON-FRI *)"   # 8 AM weekdays

Result:
├── Weekday 9 AM: Auto-start dev instances
├── Weekday 6 PM: Auto-stop dev instances
├── Weekend: Always off
└── Savings: 66% on dev compute! 💰
```

---

## Scenario 4: High-Availability Production Setup

### Background
E-commerce platform with:
- $5M revenue/year
- 99.99% uptime SLA
- Can't lose data
- Peak: 1000 requests/second
- Multi-region requirement

### Architecture Solution

```
Multi-Region, Multi-AZ Architecture

         Primary Region (us-east-1)
    ┌────────────────────────────────────┐
    │                                    │
    │  AZ-1a          AZ-1b             │
    │  ├── ALB        ├── ALB           │
    │  │              │                 │
    │  ├── Web EC2    ├── Web EC2       │
    │  │              │                 │
    │  └── App EC2    └── App EC2       │
    │       │              │             │
    │       └──────┬───────┘             │
    │              │                     │
    │         RDS Primary               │
    │         (Multi-AZ)                │
    │         - Sync replication        │
    │         - Auto-failover           │
    │         - Backup: Every 1 hour    │
    │                                    │
    └────────┬─────────────────────────┘
             │
             │ (Cross-region replication)
             │ (Read-only replicas)
             ↓
      Secondary Region (us-west-1)
      ├── Read-only RDS replica
      ├── Warm standby ASG
      └── Can take over in 5 minutes

Route53 Health Checks:
├── Primary region healthy?
├── Yes → Route 100% traffic to primary
├── No → Route to secondary (failure recovery)
└── RTO: 5 minutes | RPO: 1 hour
```

### Disaster Recovery Scenarios

```
Scenario A: Single Instance Failure
─────────────────────────────────
1. ALB health check fails (30 sec)
2. Instance marked unhealthy
3. ASG launches replacement (2 min)
4. New instance added to ALB
5. Impact: 2 seconds downtime, auto-recovered
6. Data loss: NONE (database survives)

Scenario B: Full AZ Outage
──────────────────────────
1. All instances in AZ-1a offline
2. Traffic routed to AZ-1b instances
3. ASG scales up (if CPU high)
4. No traffic loss (ALB + ASG)
5. RDS Multi-AZ: Sync replica takes over (1 min)
6. Impact: 1-2 seconds
7. Data loss: NONE (Multi-AZ replicated)

Scenario C: Entire Region Outage
─────────────────────────────────
1. us-east-1 completely down
2. Route53 detects failure
3. Routes traffic to us-west-1 (secondary)
4. Secondary region processes requests
5. Read replicas can handle reads (no writes)
6. For writes: Manual failover (or automation)
7. Impact: 5 minutes (manual) / Immediate (automated)
8. Data loss: Up to 1 hour (RDS replica lag)

Strategy for 99.99% uptime:
├── Instance failure: < 1 min recovery (AUTO)
├── AZ failure: < 1 min recovery (AUTO)
├── Region failure: 5-10 min recovery (MANUAL/AUTO)
└── Result: Only 52 minutes downtime per year ✅
```

### Cost for High Availability

```
Primary Region (us-east-1):
├── ALB (2): $32/month
├── EC2 instances (6 × t3.large): $200/month
├── RDS Multi-AZ: $400/month
└── Subtotal: $632/month

Secondary Region (us-west-1):
├── ALB (2): $32/month
├── Warm standby ASG (2 × t3.large): $70/month
├── RDS Read Replica: $200/month
└── Subtotal: $302/month

Data Transfer:
├── Cross-region replication: ~$50/month
└── Subtotal: $50/month

Total Monthly: $984/month

Revenue Impact:
├── 5M/year revenue = ~$410k/month
├── Downtime cost: $410k / 43200 min = $9.50/min
├── 99.99% SLA prevents: 52 min downtime/year = $494 potential loss
├── Infrastructure cost: $984/month = $11,808/year
├── ROI: Prevents $494/year loss (not great)...

But intangible benefits:
├── Reputation: Never goes down
├── Customer trust: 99.99% SLA
├── Ability to scale: Can handle spikes
└── Business opportunity: Enterprise contracts
```

---

## Scenario 5: Machine Learning Inference at Scale

### Background
ML model serves 1M inference requests/day:
- Each request: 100-500 MB data
- Processing: 1-2 seconds per request
- Throughput: 100 requests/second during peak
- Latency budget: < 500ms (p99)

### Solution: GPU Instance Scaling

```
Request Flow:

User Request
     │
     ├─→ API Gateway (auto-scale)
     │
     ├─→ Load Balancer
     │
     ├─→ Queue (SQS) - decouple load
     │
     ├─→ GPU Instances (scale on queue depth)
     │   ├── g4dn.xlarge (1 × T4 GPU)
     │   ├── g4dn.xlarge
     │   ├── g4dn.xlarge
     │   └── g4dn.xlarge (scales to 100+)
     │
     ├─→ Inference Server (TensorFlow, PyTorch)
     │   ├── Processes 50-100 inference/sec per GPU
     │   ├── Caches model in GPU memory
     │   └── Returns result to SQS
     │
     └─→ Result delivered to user

Peak Load Handling:

During peak (100 req/sec):
├── 1 GPU inference: 50 req/sec
├── Scale to: 2-3 GPU instances
├── Cost: 2 × $0.50/hour = $1/hour

Daily Cost (peak 4 hours, off 20 hours):
├── On-demand (peak 4 hrs): 4 × $1 = $4
├── On-demand (off-peak): 0 (scaled to 0)
├── Monthly: 30 × $4 = $120

Alternative: CPU (without GPU):
├── 1M requests × 1.5 sec = 1.5M seconds = 416 hours/day
├── Need: 416 CPU hours
├── Cost: 416 × $0.10 (c5.xlarge) = $41.60/day
├── Monthly: 30 × $41.60 = $1,248

GPU Savings: $1,248 - $120 = $1,128/month! 💰
```

### Implementation

```python
# Inference server (runs on GPU instance)

from flask import Flask, request
import torch
import numpy as np

app = Flask(__name__)

# Load model once (into GPU memory)
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = torch.hub.load('pytorch/vision:v0.10.0', 'resnet50', pretrained=True)
model.to(device)
model.eval()

@app.route('/predict', methods=['POST'])
def predict():
    # Get input image
    data = request.json['image']  # Base64 encoded
    
    # Prepare input
    tensor = torch.from_numpy(np.array(data)).to(device)
    
    # Inference (GPU acceleration!)
    with torch.no_grad():
        output = model(tensor.unsqueeze(0))
    
    # Return prediction
    return {'prediction': output.argmax(1).item()}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### Auto-Scaling Configuration

```bash
# Target: Process queue in 10 seconds
# If queue > 100 messages: Scale up

aws autoscaling put-scaling-policy \
  --auto-scaling-group-name ml-inference-asg \
  --policy-name queue-based-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "CustomizedMetricSpecification": {
      "MetricName": "ApproximateNumberOfMessagesVisible",
      "Namespace": "AWS/SQS",
      "Dimensions": [
        {
          "Name": "QueueName",
          "Value": "inference-queue"
        }
      ],
      "Statistic": "Average",
      "Unit": "Count"
    },
    "TargetValue": 100.0
  }'

# Min: 1 GPU (always on for warmth)
# Max: 100 GPUs (max throughput)
# Desired: Auto-scaled based on queue
```

---

## Cost Optimization Tips for All Scenarios

```
1. Right-Size Instances
   ├── Monitor actual usage: CPU, Memory, Network
   ├── Downsize if under 30% utilization
   └── Save: 40-60% per change

2. Use Spot Instances
   ├── For non-critical workloads: 70% savings
   ├── Batch jobs: 70% savings
   └── Dev/test: 70% savings

3. Reserved Instances
   ├── Baseline capacity: 40% savings (1-year)
   ├── Predictable workloads: Commit upfront
   └── Break-even: ~4 months

4. Stop During Off-Hours
   ├── Dev/test: Always off after hours
   ├── Non-production: Off weekends
   ├── Save: 66%+ on compute (storage remains)
   └── Automate: EventBridge + Lambda

5. Multi-Region Considerations
   ├── Primary region: Full capacity
   ├── Secondary region: Warm standby (50% cost)
   └── Trade-off: Cost vs. RTO

6. Data Transfer Optimization
   ├── Same AZ: Free
   ├── Cross-AZ: $0.01/GB
   ├── Cross-region: $0.02/GB
   └── Design: Keep workloads in same AZ

7. Storage Optimization
   ├── General Purpose (gp3): Most use cases
   ├── Provisioned IOPS (io1): High I/O
   ├── Throughput Optimized (st1): Batch/big data
   └── Delete old snapshots: Save storage

8. Reserved Capacity Planning
   ├── Buy for 70% baseline
   ├── Spot for 20% variable
   ├── On-Demand for 10% emergency
   └── Result: 40-50% vs all on-demand
```

---

## Summary: Real-World Patterns

| Scenario | Instance Type | Scaling | Cost/Month | Best For |
|----------|---|---|---|---|
| **Startup** | t3.small Spot | ASG (2-10) | $185 | Growing web apps |
| **Batch ML** | c5.2xlarge Spot | Fleet of 10 | $153 | ML training, batch jobs |
| **Dev/Test** | t3.small | Scheduled stop/start | $95 | Development teams |
| **HA Prod** | m5.large Reserved | ASG (6-20) | $984 | E-commerce, SaaS |
| **ML Inference** | g4dn.xlarge Spot | Queue-based (1-100) | $120 | ML inference, real-time |

All scenarios optimize cost while maintaining required availability and performance! 🚀
