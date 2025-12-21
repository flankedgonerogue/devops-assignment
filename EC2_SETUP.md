# EC2 Instance Setup Guide for Docker/ECR Deployment

This guide will help you set up your EC2 instances (Testing and Staging) to work with the GitHub Actions Docker/ECR deployment pipeline.

## Prerequisites

- EC2 instance running Ubuntu (or Amazon Linux)
- SSH access to the instance
- AWS account with ECR repositories created

---

## Step 1: Install Docker

### For Ubuntu:

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group (replace 'ubuntu' with your username)
sudo usermod -aG docker ubuntu

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
docker --version
sudo docker run hello-world
```

### For Amazon Linux 2:

```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker ec2-user

# Verify installation
docker --version
sudo docker run hello-world
```

**Note:** Log out and log back in for group changes to take effect.

---

## Step 2: Install AWS CLI

### For Ubuntu:

```bash
# Download AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Install unzip if not present
sudo apt-get install -y unzip

# Unzip and install
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

### For Amazon Linux 2:

```bash
# AWS CLI v2 is usually pre-installed, but if not:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

---

## Step 3: Configure AWS Credentials for ECR Access

You have two options:

### Option A: IAM Role (Recommended - More Secure)

1. **Create IAM Role:**
   - Go to AWS Console → IAM → Roles → Create Role
   - Select "EC2" as the service
   - Attach policy: `AmazonEC2ContainerRegistryReadOnly`
   - Name it: `EC2-ECR-Access-Role`

2. **Attach Role to EC2 Instance:**
   - Go to EC2 Console → Select your instance → Actions → Security → Modify IAM role
   - Select the role you created
   - Click "Update IAM role"

3. **No additional configuration needed** - the instance will automatically use the role!

### Option B: AWS Credentials File (Alternative)

```bash
# Configure AWS credentials
aws configure

# Enter:
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region name: [e.g., us-east-1]
# Default output format: json

# Or create credentials file manually
mkdir -p ~/.aws
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
EOF

cat > ~/.aws/config << EOF
[default]
region = us-east-1
output = json
EOF
```

---

## Step 4: Test ECR Login

```bash
# Replace with your AWS region and account ID
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"  # Your AWS account ID

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# If successful, you should see: "Login Succeeded"
```

---

## Step 5: Create ECR Repositories

If you haven't created ECR repositories yet:

```bash
# Create testing repository
aws ecr create-repository \
  --repository-name react-node-app-testing \
  --region us-east-1

# Create staging repository
aws ecr create-repository \
  --repository-name react-node-app-staging \
  --region us-east-1
```

**Note:** Save the repository names - you'll need them for GitHub secrets:
- `ECR_REPOSITORY_TESTING`: `react-node-app-testing`
- `ECR_REPOSITORY_STAGING`: `react-node-app-staging`

---

## Step 6: Configure Security Group

Ensure your EC2 security group allows:

1. **Inbound Rules:**
   - Port 80 (HTTP) from `0.0.0.0/0` (or your IP)
   - Port 22 (SSH) from your IP only (for security)

2. **Outbound Rules:**
   - All traffic (for Docker pulls, ECR access, etc.)

**To update via AWS Console:**
- EC2 → Security Groups → Select your instance's security group
- Inbound rules → Edit inbound rules → Add rule
- Type: HTTP, Port: 80, Source: 0.0.0.0/0

---

## Step 7: Test Manual Deployment

Test that everything works by manually pulling and running a container:

```bash
# Set variables (replace with your values)
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"
export ECR_REPO="react-node-app-testing"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Pull image (if it exists)
docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest

# Stop any existing container
docker stop react-node-app || true
docker rm react-node-app || true

# Run container
docker run -d -p 80:80 --name react-node-app --restart unless-stopped \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest

# Check if container is running
docker ps

# View logs
docker logs react-node-app

# Test access
curl http://localhost:80
```

---

## Step 8: Verify Setup

Run this checklist:

```bash
# 1. Docker is installed and running
docker --version
sudo systemctl status docker

# 2. AWS CLI is installed
aws --version

# 3. Can authenticate to ECR (if using IAM role, this should work automatically)
aws ecr describe-repositories --region us-east-1

# 4. Docker can pull from ECR (test with a public image first)
docker pull hello-world

# 5. Port 80 is accessible (from another machine)
# curl http://YOUR_EC2_IP
```

---

## Troubleshooting

### Docker permission denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and log back in
```

### Cannot pull from ECR
```bash
# Check IAM role is attached
aws sts get-caller-identity

# Verify ECR permissions
aws ecr describe-repositories --region us-east-1

# Try manual login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

### Container won't start on port 80
```bash
# Check if port 80 is already in use
sudo netstat -tulpn | grep :80

# Run container with sudo if needed (not recommended, fix permissions instead)
sudo docker run -d -p 80:80 --name react-node-app IMAGE_NAME
```

### Security group issues
- Ensure port 80 is open in inbound rules
- Check that your instance's security group is correctly attached
- Verify network ACLs allow traffic

---

## Quick Setup Script (Ubuntu)

Save this as `setup-ec2.sh` and run: `chmod +x setup-ec2.sh && ./setup-ec2.sh`

```bash
#!/bin/bash
set -e

echo "Installing Docker..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
sudo systemctl start docker
sudo systemctl enable docker

echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install -y unzip
unzip awscliv2.zip
sudo ./aws/install

echo "Setup complete! Please log out and log back in for Docker group changes to take effect."
echo "Then verify with: docker --version && aws --version"
```

---

## Next Steps

1. ✅ Complete EC2 setup (this guide)
2. ✅ Create ECR repositories
3. ✅ Configure GitHub Secrets (see workflow files for required secrets)
4. ✅ Test deployment by creating a PR or pushing to main

Your EC2 instances are now ready for automated Docker deployments! 🚀

