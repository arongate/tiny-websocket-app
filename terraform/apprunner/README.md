# Terraform Deployment for WebSocket Server on AWS App Runner

This folder contains Terraform code for deploying the WebSocket server on AWS App Runner.

## Prerequisites

Before deploying with Terraform, make sure you have the following:

1. **AWS Account:**
    - Ensure you have an AWS account and necessary credentials.

2. **Terraform Installed:**
    - [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).

3. **AWS CLI Installed:**
    - [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

4. **AWS App Runner Access:**
    - Ensure your AWS IAM user has the necessary permissions for AWS App Runner.

## Usage

1. **Configure AWS Credentials:**

    ```bash
    aws configure
    ```

    Follow the prompts to enter your AWS access key, secret key, default region, and default output format.

2. **Initialize Terraform:**

    ```bash
    terraform init
    ```

3. **Review and Apply Terraform Plan:**

    ```bash
    terraform apply
    ```

    Review the plan and type `yes` to apply the changes.

4. **Access the Deployed WebSocket Server:**

    After successful deployment, the WebSocket server should be accessible. Find the URL in the Terraform output.

## Customization

Feel free to modify the `main.tf` file to adjust deployment settings or integrate it into your larger infrastructure project.

## Cleanup

To destroy the resources created by Terraform, run:

```bash
terraform destroy
