# Terraform CI/CD Pipeline Using Jenkins and AWS S3

## 1. Project Overview

This project demonstrates Infrastructure as Code (IaC) and CI/CD automation using Terraform, Jenkins, Git, GitHub, and AWS.

Terraform is used to provision an Amazon S3 bucket, while Jenkins automates the Terraform workflow through a pipeline.

The pipeline includes:

1. Checkout source code from GitHub.
2. Initialize Terraform.
3. Check Terraform formatting.
4. Validate Terraform configuration.
5. Generate a Terraform execution plan.
6. Request manual approval.
7. Apply Terraform configuration.
8. Display success or failure messages.

## 2. Technologies Used

| Technology | Purpose |
|---|---|
| AWS | Cloud platform |
| Amazon S3 | Cloud storage resource |
| Terraform | Infrastructure as Code |
| Jenkins | CI/CD automation |
| Git | Version control |
| GitHub | Source code repository |
| macOS | Local development environment |
| iTerm2 | Terminal for connecting to EC2 |
| AWS CLI | Command-line access to AWS |
| SSH | Secure remote connection |

## 3. Project Architecture

```text
MacBook (macOS)
      |
      v
iTerm2 Terminal
      |
      | SSH
      v
AWS EC2 Instance
      |
      v
Jenkins
      |
      v
GitHub Repository
      |
      v
Jenkins Pipeline
      |
      +--> Checkout
      +--> Terraform Init
      +--> Terraform Fmt
      +--> Terraform Validate
      +--> Terraform Plan
      +--> Manual Approval
      +--> Terraform Apply
      |
      v
AWS S3 Bucket
```

## 4. Project Structure

```text
Terraform_CICD/
│
├── .gitignore
├── .terraform.lock.hcl
├── Jenkinsfile
├── main.tf
├── output.tf
├── provider.tf
├── variable.tf
└── README.md
```

### File Descriptions

- `main.tf`: Defines the AWS S3 bucket.
- `provider.tf`: Configures the AWS provider and required provider version.
- `variable.tf`: Defines input variables such as bucket name and AWS region.
- `output.tf`: Displays the name of the created S3 bucket.
- `Jenkinsfile`: Defines the Jenkins CI/CD pipeline.
- `.gitignore`: Excludes local files and sensitive artifacts from Git.
- `.terraform.lock.hcl`: Records selected provider versions and checksums.
- `README.md`: Documents the project.

The `.terraform/` directory and Terraform state files can exist locally during execution but should not normally be committed to GitHub.

## 5. Prerequisites

Before starting the project, ensure you have:

- An AWS account.
- An IAM identity with appropriate permissions for the required S3 operations.
- An EC2 instance with Jenkins installed.
- Git and Terraform installed on the machine executing the pipeline.
- AWS CLI installed if using CLI-based credential configuration.
- A GitHub repository containing the Terraform files and `Jenkinsfile`.
- A Jenkins Pipeline job configured to use the repository.

## 6. Development Environment: MacBook and iTerm2

I use a MacBook running macOS as my local development machine. I use iTerm2 to connect securely to my AWS EC2 instance, where Jenkins runs the CI/CD pipeline.

### Step 1: Open iTerm2

Open iTerm2 on the MacBook.

### Step 2: Set private key permissions

If the EC2 private key is in the Downloads folder, run:

```bash
chmod 400 ~/Downloads/your-key.pem
```

Replace `your-key.pem` with your actual private key filename.

### Step 3: Connect to EC2

```bash
ssh -i ~/Downloads/your-key.pem ubuntu@<EC2-PUBLIC-IP>
```

Replace `<EC2-PUBLIC-IP>` with the instance's public IP address. Use the correct SSH username for your EC2 operating system, such as `ubuntu` or `ec2-user`.

### Step 4: Switch to the Jenkins user

If required, switch to the Jenkins user:

```bash
sudo su jenkins
```

Check the user's home directory:

```bash
echo $HOME
```

On a typical Jenkins installation, this is `/var/lib/jenkins`.

### Step 5: Navigate to the Jenkins workspace

Example:

```bash
cd /var/lib/jenkins/workspace/terraform-cicd
```

Use the actual workspace path shown in your Jenkins job.

### Step 6: Verify installed tools

```bash
git --version
terraform -version
aws --version
```

These commands display the installed versions of Git, Terraform, and AWS CLI.

## 7. AWS IAM Credentials Configuration

AWS IAM manages access to AWS resources. Terraform and the AWS CLI require an authorized credential source to perform operations in AWS.

### Steps to create AWS IAM access keys

1. Sign in to the [AWS Management Console](https://console.aws.amazon.com/).
2. Open **IAM**.
3. Select **Users**.
4. Select an existing IAM user or create a dedicated user for the project.
5. Under **Permissions**, assign only the permissions required for the project.
6. Open the user's **Security credentials** tab.
7. Under **Access keys**, select **Create access key**.
8. Follow the prompts and securely save the Access Key ID and Secret Access Key.

The secret access key is displayed at creation time, so store it securely.

### Configure AWS CLI

If using IAM user access keys, run:

```bash
aws configure
```

Enter the requested values:

- AWS Access Key ID
- AWS Secret Access Key
- Default region: `ap-south-1`
- Default output format: `json`

The default AWS CLI files are:

**On macOS:**

```text
~/.aws/credentials
~/.aws/config
```

**On an EC2 instance running Jenkins:**

```text
/var/lib/jenkins/.aws/credentials
/var/lib/jenkins/.aws/config
```

The EC2 paths assume `/var/lib/jenkins` is the Jenkins user's home directory. These are default locations; the active credential source may be different.

### Verify AWS configuration

Check which credential source is being used:

```bash
aws configure list
```

Verify the AWS identity:

```bash
aws sts get-caller-identity
```

### IAM role for Jenkins on EC2

For an EC2-hosted Jenkins server, an appropriately scoped **IAM role attached to the EC2 instance** is generally preferable to long-lived access keys. AWS CLI and Terraform can use the role's temporary credentials without manually storing permanent access keys.

An IAM role does not have permanent access keys to download. The EC2 instance obtains temporary credentials through the role when configured correctly.

### Security Best Practices

- Never commit AWS access keys or secret keys to GitHub.
- Never hardcode credentials in Terraform files or the Jenkinsfile.
- Apply least-privilege IAM permissions.
- Prefer an EC2 IAM role for Jenkins when possible.
- Keep Terraform state and plan files secure.

## 8. Terraform Configuration

### `main.tf`

This file defines the S3 bucket resource:

```hcl
resource "aws_s3_bucket" "cicd-bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "cicd-project"
    Environment = "lab"
    ManagedBY   = "Terraform"
  }
}
```

**Explanation:**

- `aws_s3_bucket`: Terraform resource type for an AWS S3 bucket.
- `cicd-bucket`: Local Terraform resource name.
- `var.bucket_name`: References the bucket name variable.
- `tags`: Adds metadata to the bucket.

S3 bucket names must be globally unique.

### `provider.tf`

The AWS provider configuration specifies the region:

```hcl
provider "aws" {
  region = var.aws-region
}
```

The AWS provider must also be declared as a required provider. Keep the `required_providers` declaration in one place rather than duplicating it across files.

Example:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

This constraint selects compatible AWS provider versions in the 6.x series.

Credentials should come from a supported credential source, such as an EC2 IAM role or AWS CLI configuration.

### `variable.tf`

```hcl
variable "bucket_name" {
  type        = string
  description = "Enter your globally unique bucket name"
}

variable "aws-region" {
  type    = string
  default = "ap-south-1"
}
```

**Explanation:**

- `bucket_name`: The S3 bucket name supplied when running Terraform.
- `aws-region`: The AWS region variable.
- `ap-south-1`: AWS Asia Pacific (Mumbai) region.

The bucket name variable has no default value, so it must be supplied through a variable file, command-line argument, or another supported input mechanism.

Example:

```bash
terraform plan -var="bucket_name=my-unique-cicd-bucket-12345"
```

Replace the example with a globally unique bucket name.

### `output.tf`

```hcl
output "bucket_name" {
  value       = aws_s3_bucket.cicd-bucket.bucket
  description = "Created bucket name"
}
```

This output displays the name of the S3 bucket managed by Terraform.

## 9. Terraform Commands

Run Terraform commands from the directory containing the `.tf` files.

### Initialize Terraform

```bash
terraform init
```

Initializes the working directory and downloads required providers.

### Format Terraform files

```bash
terraform fmt
```

Formats Terraform configuration files.

To check formatting without modifying files:

```bash
terraform fmt -check
```

### Validate configuration

```bash
terraform validate
```

Checks configuration syntax and internal consistency.

### Generate a plan

```bash
terraform plan -var="bucket_name=my-unique-cicd-bucket-12345"
```

Shows the proposed infrastructure changes.

### Apply configuration

```bash
terraform apply -var="bucket_name=my-unique-cicd-bucket-12345"
```

Applies the proposed changes after confirmation.

### Display outputs

```bash
terraform output
```

Displays configured Terraform outputs.

### Destroy resources

```bash
terraform destroy -var="bucket_name=my-unique-cicd-bucket-12345"
```

Destroys the resources managed by the configuration after confirmation. Use this only when you intentionally want to remove the infrastructure.

The examples use placeholder bucket names. Ensure the Jenkins pipeline also receives the required variable.

## 10. Jenkins CI/CD Pipeline

The `Jenkinsfile` automates the Terraform workflow.

### Jenkinsfile

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Fmt') {
            steps {
                sh 'terraform fmt -check'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }

        stage('Approval') {
            steps {
                input message: 'Do you want to apply Terraform changes?',
                      ok: 'Approve'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }
    }

    post {
        success {
            echo 'Terraform CI/CD pipeline completed successfully!'
        }

        failure {
            echo 'Terraform CI/CD pipeline failed. Check the console output.'
        }
    }
}
```

**Important:** This is the basic pipeline structure. The Jenkins build must have access to AWS credentials and receive the required `bucket_name` variable. The current pipeline runs `terraform plan` and then runs `terraform apply -auto-approve` separately, so Terraform may calculate a new plan during apply.

For a more controlled deployment, consider saving the plan using `terraform plan -out=tfplan` and applying that same plan after approval. Saved plans can contain sensitive information and should be protected.

### Pipeline stages

| Stage | Purpose |
|---|---|
| Checkout | Retrieves code from the configured GitHub repository |
| Terraform Init | Initializes Terraform |
| Terraform Fmt | Checks Terraform formatting |
| Terraform Validate | Validates configuration |
| Terraform Plan | Previews infrastructure changes |
| Approval | Pauses for manual approval |
| Terraform Apply | Applies infrastructure changes |
| Post Success | Prints a success message |
| Post Failure | Prints a failure message |

## 11. Jenkins Setup

1. Install Jenkins on the EC2 instance.
2. Ensure Jenkins can access the GitHub repository.
3. Install the required Jenkins plugins, including Pipeline and Git as appropriate.
4. Ensure Terraform, Git, and AWS authentication are available to the Jenkins build user.
5. Create a Pipeline job in Jenkins.
6. Configure the GitHub repository URL.
7. Select the appropriate branch, such as `main`.
8. Configure Jenkins to use the `Jenkinsfile` from the repository.
9. Run the pipeline and review the Console Output.
10. Approve the deployment when the pipeline reaches the manual approval stage.

## Part 12 — Git and GitHub Commands

Git is used for version control, while GitHub hosts the project repository and stores the source code remotely.

### 1. Check Repository Status

```bash
git status
```

Displays modified, staged, and untracked files in the working directory.

### 2. Add Files to the Staging Area

```bash
git add .
```

Stages all changes that are not excluded by `.gitignore`. Check that sensitive files and Terraform state files are excluded before staging.

To stage a specific file:

```bash
git add README.md
```

### 3. Commit Changes

```bash
git commit -m "<commit comment"
```

Creates a commit containing the staged changes with a descriptive message.

**Syntax:**

```bash
git commit -m "your commit message"
```

### 4. View Commit History

```bash
git log
```

Displays the commit history, including commit IDs, authors, dates, and messages.

For a compact view:

```bash
git log --oneline
```

### 5. Show Commit Details

```bash
git show
```

Displays details of the latest commit, including its commit message and changes.

To inspect a specific commit:

```bash
git show <commit-id>
```

Replace `<commit-id>` with the actual commit hash.

### 6. Check Configured Remote Repository

```bash
git remote -v
```

Displays the URLs of the configured remote repositories.

### 7. Push Changes to GitHub

```bash
git push origin main
```

Uploads local commits from the `main` branch to the remote GitHub repository.

### 8. Pull Changes from GitHub

```bash
git pull origin main
```

Fetches and integrates changes from the remote `main` branch into the current local branch.

### 9. Clone a Repository

```bash
git clone <repository-url>
```

Creates a local copy of a remote GitHub repository.

Replace `<repository-url>` with the actual repository URL.

### 10. Complete Git Workflow

The following commands demonstrate a typical workflow for updating the project:

```bash
git status
git add .
git status
git commit -m "Update Terraform CI/CD project"
git show
git push origin main
```

**Workflow explanation:**

1. `git status` — Check the current changes.
2. `git add .` — Stage the changes.
3. `git status` — Confirm which files are staged.
4. `git commit -m "..."` — Save the staged changes as a commit.
5. `git show` — Review the latest commit.
6. `git push origin main` — Upload the commit to GitHub.

**Note:** Git commits save changes locally. The `git push` command uploads those commits to GitHub.


## 13. `.gitignore` and Terraform State Security

Terraform creates local files and directories during execution. These should be excluded from Git where appropriate.

Recommended `.gitignore` entries:

```gitignore
# Terraform working directory
.terraform/

# Terraform state files
*.tfstate
*.tfstate.*

# Terraform plan files
*.tfplan
tfplan

# Variable files that may contain sensitive values
*.tfvars
*.tfvars.json
!example.tfvars

# Crash logs
crash.log
crash.*.log

# Override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# CLI configuration
.terraformrc
terraform.rc
```


## 14. Troubleshooting

### Error: No configuration files

**Cause:** Terraform is running in a directory without `.tf` files.

**Solution:**

```bash
ls
cd /path/to/your/terraform/project
```

### Error: S3 bucket name already exists

**Cause:** S3 bucket names must be globally unique.

**Solution:** Choose a different bucket name and supply it through the required variable.

### Error: AWS credentials not found

**Cause:** Terraform cannot find valid AWS credentials.

**Solution:**

```bash
aws configure list
aws sts get-caller-identity
```

Check the credential source available to the Jenkins build user. For EC2-hosted Jenkins, an appropriately configured IAM role is recommended.

### Error: Jenkins is waiting for an executor

**Cause:** No Jenkins executor is available, or the selected node is offline.

**Solution:** Check Jenkins node status, executor availability, disk space, and system logs.

### Error: Terraform formatting check failed

**Cause:** Terraform files are not formatted.

**Solution:**

```bash
terraform fmt
```

Commit the formatting changes and rerun the pipeline.

### Error: Required Terraform variable has no value

**Cause:** A required variable such as `bucket_name` was not supplied.

**Solution:** Provide the variable using a suitable Jenkins parameter, a variable file, or an explicit command-line argument.

## 15. Security Best Practices

- Never commit AWS credentials to GitHub.
- Never commit Terraform state files or saved plan files.
- Keep `.terraform.lock.hcl` under version control.
- Use least-privilege IAM permissions.
- Prefer an EC2 IAM role for AWS access from Jenkins.
- Restrict who can approve deployments.
- Protect Jenkins credentials and build logs.
- Use a secure remote Terraform backend for collaborative projects.
- Review proposed Terraform changes before approval.
- Rotate any credentials that may have been exposed.

## 16. Future Improvements

- Configure a secure remote Terraform backend.
- Use an EC2 IAM role for Jenkins authentication.
- Store sensitive values in Jenkins Credentials or a secrets manager.
- Apply the exact saved Terraform plan that was approved.
- Configure a GitHub webhook to trigger Jenkins automatically.
- Introduce separate development, staging, and production environments.
- Add automated security scanning.
- Improve artifact cleanup and pipeline error handling.


## 18. Conclusion

This project demonstrates how Terraform can provision AWS infrastructure and how Jenkins can automate the workflow through a CI/CD pipeline.

By combining GitHub, Terraform, Jenkins, AWS CLI, and Amazon S3, this project provides practical experience with Infrastructure as Code, cloud resource provisioning, version control, and deployment automation.
