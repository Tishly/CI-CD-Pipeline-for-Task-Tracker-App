# CI-CD-Pipeline-for-Task-Tracker-App

# Task Tracker CI/CD Pipeline

This repository contains the complete CI/CD pipeline setup for a Task Tracker application, including Docker configuration, GitHub Actions workflows, and AWS deployment setup.

## Project Structure

```
.
├── backend/              # Backend application code
│   ├── Dockerfile        # Backend Docker configuration
│   └── ...
├── frontend/             # Frontend application code
│   ├── Dockerfile        # Frontend Docker configuration
│   └── ...
├── monitoring/           # Prometheus and Grafana configuration
│   ├── prometheus/
│   │   └── prometheus.yml
│   └── grafana/
│       └── provisioning/
├── infra/                # Infrastructure as code
│   ├── terraform/        # Terraform files for AWS resources
│   └── cloudformation/   # CloudFormation template
├── .github/
│   └── workflows/        # GitHub Actions workflow files
└── docker-compose.yml    # Local development setup
```

## Getting Started

### Prerequisites

- Docker and Docker Compose
- AWS Account
- GitHub Account
- Terraform (optional, for IaC approach)

### Local Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Tishly/CI-CD-Pipeline-for-Task-Tracker-App
   cd CI-CD-Pipeline-for-Task-Tracker-App
   ```

2. Start the local development environment:
   ```bash
   docker-compose up -d
   ```

3. Access the application:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000

### Setting Up CI/CD Pipeline

#### 1. GitHub Secrets

Add the following secrets to your GitHub repository:

- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_PASSWORD`: Your Docker Hub password
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

#### 2. AWS Infrastructure Setup

You can deploy the AWS infrastructure using either CloudFormation or Terraform:

**Using CloudFormation:**
```bash
aws cloudformation create-stack \
  --stack-name tasktracker-production \
  --template-body file://infra/cloudformation/template.yaml \
  --parameters ParameterKey=EnvironmentName,ParameterValue=production \
  --capabilities CAPABILITY_IAM
```

**Using Terraform:**
```bash
cd infra/terraform
terraform init
terraform apply -var="environment=production"
```

#### 3. Setting Up Environment Variables

Configure the following environment variables in AWS for your application:

**Production:**
- `NODE_ENV=production`
- `MONGO_URI=<your_production_mongodb_uri>`

**Staging:**
- `NODE_ENV=staging`
- `MONGO_URI=<your_staging_mongodb_uri>`

### Monitoring Setup

To set up monitoring with Prometheus and Grafana:

1. Start the monitoring stack:
   ```bash
   docker-compose -f monitoring/docker-compose.yml up -d
   ```

2. Access monitoring dashboards:
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3001 (admin/admin)

## CI/CD Pipeline Flow

1. **Push to Repository**
   - Push to `staging` branch -> Deploys to Staging
   - Push to `main` branch -> Deploys to Production

2. **Automated Testing**
   - Runs unit and integration tests for frontend and backend

3. **Docker Image Building**
   - Builds Docker images for frontend and backend
   - Tags images with environment name (`staging` or `prod`)

4. **AWS Deployment**
   - Updates ECS services with new task definitions
   - Performs zero-downtime deployment

## Deployment Architecture

The application is deployed on AWS with the following architecture:

- **VPC** with public subnets across two availability zones
- **ECS Fargate** for container orchestration
- **Application Load Balancer** for traffic distribution
- **CloudWatch** for logging and monitoring
- **ECR** for Docker image storage

## Environments

The pipeline supports two environments:

1. **Staging**
   - Branch: `staging`
   - URL: [https://staging.tasktracker-app.com](https://staging.tasktracker-app.com)
   - Used for testing new features before production

2. **Production**
   - Branch: `main`
   - URL: [https://tasktracker-app.com](https://tasktracker-app.com)
   - The live production environment

## Troubleshooting

**Common Issues:**

1. **Docker Build Failures**
   - Check Docker credentials in GitHub secrets
   - Verify Dockerfile syntax

2. **AWS Deployment Issues**
   - Verify AWS credentials
   - Check ECS service logs in CloudWatch
   - Verify task definition compatibility

3. **Local Development Issues**
   - Run `docker-compose down -v` and then `docker-compose up -d` to reset
   - Check container logs with `docker-compose logs -f`

## License

MIT