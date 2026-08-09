# Three-Tier AWS Architecture with Terraform

This is a three-tier web architecture I built on AWS, fully defined as Infrastructure as Code with Terraform. I built it to get hands-on with core cloud/DevOps concepts — network isolation, load balancing, auto scaling, and secure database access — since this is the same basic pattern behind most real-world web apps.

## Architecture

```
                              Internet
                                 │
                        ┌────────▼────────┐
                        │  Internet Gateway │
                        └────────┬────────┘
                                 │
        ┌────────────────────────┴────────────────────────┐
        │                        VPC (10.0.0.0/16)          │
        │                                                     │
        │   ┌─────────────────┐        ┌─────────────────┐  │
        │   │  Public Subnet A │        │  Public Subnet B │  │
        │   │   (us-east-1a)   │        │   (us-east-1b)   │  │
        │   │                  │        │                  │  │
        │   │   Application Load Balancer                  │  │
        │   └────────┬─────────┘        └────────┬─────────┘  │
        │            │                            │            │
        │   ┌────────▼─────────┐        ┌────────▼─────────┐  │
        │   │ Private App Subnet A│      │ Private App Subnet B││
        │   │  EC2 (Auto Scaling)  │      │  EC2 (Auto Scaling)  ││
        │   └────────┬─────────┘        └────────┬─────────┘  │
        │            │                            │            │
        │   ┌────────▼─────────┐        ┌────────▼─────────┐  │
        │   │ Private DB Subnet A │      │ Private DB Subnet B │ │
        │   │   RDS (MySQL)        │      │   (standby AZ)       ││
        │   └──────────────────┘        └──────────────────┘  │
        │                                                     │
        └─────────────────────────────────────────────────────┘
```

## Why I built it this way

The whole idea is three isolated tiers, where each one has a smaller blast radius than the last:

- **Public subnets** only hold the Application Load Balancer. It's the one and only thing in this whole setup that's directly reachable from the internet.
- **Private app subnets** hold the EC2 instances, sitting behind an Auto Scaling Group. They only accept traffic from the ALB — never straight from the internet — and reach out to the internet (for updates, etc.) through a NAT Gateway instead of having a public IP of their own.
- **Private DB subnets** hold the RDS MySQL instance. It only accepts traffic from the app tier's security group — not the ALB, not the internet, not even a specific IP range. I set the security groups up so they reference each other directly instead of using IP-based rules, so that trust chain is actually enforced at the network layer instead of just being something the app is supposed to respect.

**High availability:** everything is spread across two Availability Zones (us-east-1a and us-east-1b), so if one physical data center has an issue, the app doesn't go down with it.

**Self-healing:** the Auto Scaling Group is tied into the ALB's health checks. If an app server stops responding, the ALB stops sending it traffic and the ASG swaps it out automatically — I don't have to do anything manually.

## Tech stack

- **Terraform** — Infrastructure as Code, AWS provider
- **AWS VPC** — custom networking, public/private subnets, route tables, IGW, NAT Gateway
- **AWS ALB** — Application Load Balancer with health checks
- **AWS EC2 + Auto Scaling** — Launch Template + Auto Scaling Group across 2 AZs
- **AWS RDS (MySQL)** — private, multi-AZ-capable database tier
- **AWS Security Groups** — tiered, reference-based (not IP-based) access control

## Repository structure

```
three-tier-aws-terraform/
├── main.tf              # provider and Terraform configuration
├── variables.tf          # input variables
├── outputs.tf            # ALB DNS name and RDS endpoint outputs
├── vpc.tf                # VPC, subnets, IGW, NAT Gateway, route tables
├── security_groups.tf    # tiered security group chain
├── alb.tf                # Application Load Balancer + target group
├── ec2.tf                # Launch Template + Auto Scaling Group
├── rds.tf                # RDS MySQL instance + subnet group
└── terraform.tfvars      # variable values (gitignored — not included in repo)
```

## How to deploy it

**You'll need:** an AWS account, the AWS CLI configured (`aws configure`), and Terraform installed.

1. Clone the repo:
   ```
   git clone https://github.com/zbryantjones/three-tier-aws-terraform.git
   cd three-tier-aws-terraform
   ```
2. Create your own `terraform.tfvars` file (it's gitignored so it's not in this repo) with your database password:
   ```
   db_password = "YourStrongPassword123"
   ```
3. Deploy:
   ```
   terraform init
   terraform plan
   terraform apply
   ```
4. Once it's done, Terraform prints out the ALB's DNS name — pop that into a browser and you'll see the app running behind the load balancer.
5. When you're finished, tear it down so you're not paying for anything sitting idle:
   ```
   terraform destroy
   ```

## What I'd add next

- HTTPS via AWS Certificate Manager (ACM) on the ALB listener
- Multi-AZ RDS for full database failover (I kept it single-AZ for now to keep costs down while learning)
- CloudWatch alarms + SNS notifications for CPU/health monitoring
- A CI/CD pipeline (GitHub Actions) to run `terraform plan` automatically on pull requests
- Breaking the VPC/EC2/RDS resources out into reusable Terraform modules

## Notes

I built this as a hands-on project to actually learn AWS networking and Terraform instead of just watching tutorials. Everything above was deployed live in AWS, tested end-to-end, and torn down afterward.
