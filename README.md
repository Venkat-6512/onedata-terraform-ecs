# OneData DevOps Assessment — Task 2: ECS Fargate with ALB (Terraform)

## 📋 Requirements Checklist

- [x] VPC with 2 public + 2 private subnets across 2 AZs
- [x] ECS Cluster with Container Insights enabled
- [x] Fargate Task Definition — image URI read from SSM Parameter Store
- [x] Application Load Balancer (internet-facing) in public subnets
- [x] ECS Service in private subnets — `assign_public_ip = false`
- [x] Security groups enforce ALB-only access to containers
- [x] Auto-scaling 1→4 tasks at CPU > 60%
- [x] CloudWatch alarm: task count drops to 0
- [x] CloudWatch alarm: ALB 5xx errors > 10/minute
- [x] SNS topic for alarm notifications

---

## 🏗️ Architecture

```
Internet (0.0.0.0/0)
        │ :80
        ▼
[ALB — public subnets — SG: allow 80/443]
        │ :3000 (ALB SG only)
        ▼
[ECS Fargate — private subnets — no public IP]
        │
        ▼
[CloudWatch Logs → /ecs/onedata-api]
```

---

## 📁 File Structure

| File | Purpose |
|------|---------|
| `main.tf` | Provider + backend config |
| `variables.tf` | All input variable definitions |
| `terraform.tfvars` | Actual variable values |
| `vpc.tf` | VPC, subnets, IGW, NAT Gateway, route tables |
| `security.tf` | ALB and ECS security groups |
| `ssm.tf` | SSM parameter for container image URI |
| `alb.tf` | Load balancer, target group, listener |
| `ecs.tf` | Cluster, IAM roles, task definition, Fargate service |
| `autoscaling.tf` | Auto-scaling target and CPU/memory policies |
| `cloudwatch.tf` | CloudWatch alarms + SNS notifications |
| `outputs.tf` | ALB DNS, cluster name, subnet IDs |

---

## 🚀 Usage

### Prerequisites
```bash
terraform --version   # >= 1.6.0
aws configure         # valid AWS credentials
```

### Update container image in SSM (before deploying)
```bash
aws ssm put-parameter \
  --name "/onedata/container-image-uri" \
  --value "ghcr.io/venkat-6512/onedata-devops-api:YOUR_SHA" \
  --type String \
  --overwrite
```

### Deploy
```bash
terraform init      # download providers
terraform plan      # preview all changes
terraform apply     # create resources (confirm with 'yes')
```

### Test the service
```bash
# Get ALB DNS from output
terraform output alb_dns_name

# Test the running service
curl http://<ALB_DNS_NAME>/health
curl http://<ALB_DNS_NAME>/items
```

### Destroy
```bash
terraform destroy
```

---

## 🔐 Security Design

| Rule | Implementation |
|------|---------------|
| No direct container access | `assign_public_ip = false` in ECS service |
| ALB-only ingress to ECS | ECS SG ingress only from ALB SG ID |
| No hardcoded image URI | Read from SSM Parameter Store at deploy time |
| Encrypted logs | CloudWatch Log Group with 7-day retention |

---

## 📊 Auto Scaling

Scales between **1 minimum** and **4 maximum** tasks:
- **Scale out** when average CPU > 60% for 60 seconds
- **Scale in** when CPU drops below target for 60 seconds
- Memory scaling also configured at 80% threshold

---

## 🔔 CloudWatch Alarms

| Alarm | Trigger | Action |
|-------|---------|--------|
| `onedata-task-count-zero` | Running tasks < 1 | SNS email alert |
| `onedata-alb-5xx-errors` | 5xx errors > 10/min | SNS email alert |
