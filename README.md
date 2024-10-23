# Secure-Consent-Form-Upload-and-Mapping-System
The Secure Consent Form Upload and Mapping System is a solution to enhance the handling of paper-based consent forms within a digital consent framework for clinical genomics research. It allows participants to use paper forms while maintaining digital consent protocols and ensures the security and integrity of genomic data.

## Main Objectives:
1. Secure Management of Consent Forms: Ensure that participant’s paper and digital consent forms are securely handled and stored.
2. Seamless Integration: Facilitate the smooth transition between paper and digital consent processes, maintaining data integrity throughout.
3. Non-repudiation: Ensure non-repudiation of participant consent or the creation/modification of participant data.
4. Enhanced Data Confidentiality/Integrity: Protect data and verify the authenticity of consent forms, preventing tampering and ensuring accurate record-keeping.
5. Scalable Architecture: Develop a flexible system architecture that supports future enhancements and evolving consent management need

## Project Structure
- `lambda/`: Contains the Lambda functions.
- `lambda-layer/`: Contains additional layers for the Lambda functions.
  - `nodejs/`: Node.js libraries for Lambda layers.

## Prerequisites
Before setting up the project, make sure you have the following installed:

1. Terraform (latest version)
2. AWS CLI (configured with appropriate credentials)
3. Node.js (for Lambda development)
4. Zip utility (to compress files)

## AWS CLI Configuration
The AWS CLI is essential for interacting with AWS services from your local machine, including deploying Lambda functions and managing infrastructure.

1. Install the AWS CLI: Follow [the official installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configure AWS CLI: Run the following command to configure your AWS credentials:

```bash
aws configure
```

You'll be prompted to enter:
- AWS Access Key ID
- AWS Secret Access Key
- Default region name (e.g., us-east-1)
- Default output format (e.g., json)

These credentials will be used by Terraform and the AWS CLI to deploy the Lambda functions and manage resources.

## Setup
### Install Node Modules
Navigate to the lambda directory and install the required Node.js modules for your Lambda functions' dependencies:

```bash
cd lambda
npm install
```

### Run build script
```bash
node build.js
```

### Zip Lambda Functions
To prepare the Lambda function for deployment, cd into build folder and compress the necessary files

```bash
cd build
zip -r putitem.zip putitem.js
zip -r puts3object.zip puts3object.js
zip -r validateform.zip validateform.js
```

Ensure that the zipped files are located in the correct directory for deployment.

## Terraform Workflow Guide
### Verify Terraform Installation and Version
To ensure that Terraform is installed on your machine, check the version with:

```bash
terraform -version
```

You can also list all available commands and arguments by running:

```bash
terraform -help
```

### Initialize Terraform
Run the following command to initialize the Terraform working directory. This will install the required provider plugins and prepare your environment.

```bash
terraform init
```

### Validate the Configuration
Validating ensures there are no syntax errors in your Terraform configuration. Run:

```bash
terraform validate
```

If the configuration is correct, you’ll see:

```bash
Success! The configuration is valid.
```

### Generate a Terraform Plan
A Terraform plan is a dry run of what will happen when you apply the changes. It allows you to review the resources Terraform will manage.

Run the command to see the changes:

```bash
terraform plan
```

You can also output the plan to a file for later use:

```bash
terraform plan -out myplan
```

This stores the plan in `myplan` for later application.

### Apply a Terraform Plan
You can apply the changes directly from a plan file:

```bash
terraform apply myplan
```

Alternatively, apply changes directly without a plan file:

```bash
terraform apply
```

You’ll be prompted to confirm the changes. Type `yes` to proceed.

> Example: If you change the `random_string` length from 16 to 10 in `main.tf`, the resource will be destroyed and recreated to reflect the new configuration.

### Destroy Resources
To clean up all resources created by your Terraform configuration, use the `destroy` command. You can first preview what will be destroyed:

```bash
terraform plan -destroy
```

Finally, run the actual destroy command:

```bash
terraform destroy
```

You’ll be prompted to confirm. Enter `yes` to proceed.

---

By following these steps, you can manage infrastructure resources using Terraform efficiently. This workflow ensures you initialize your workspace, validate configurations, and apply or destroy resources as needed.