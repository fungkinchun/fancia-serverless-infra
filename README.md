# Fancia

Fancia is a social platform connecting people with shared interests for offline, in-person group gatherings and community building.

## infra

This repository contains Terraform code to provision the infrastructure of Fancia. It consists of reusable modules that can be composed per environment (for example `dev`).

### IMPORTANT

It is recommended to use [fancia-infra-pipeline](https://github.com/fungkanchun/fancia-infra-pipeline) to deploy the infrastructure.

- Developer tools
- IAM
- Network
- S3
- RDS
- EKS

Additional resources include Secrets Manager secrets, Private CA, KMS keys, and ALB/ingress configurations.

### Local deployment

#### Prerequisites

- AWS CLI installed and configured for the target account and profile
- Terraform installed

#### Quick start

1. Define the profile and project name to be used for deployment:

   ```bash
   export AWS_PROFILE=<your-aws-profile>
   export PROJECT_NAME=<your-project-name>
   ```

2. Initialize Terraform state (adjust backend bucket name as needed):

   ```bash
   terraform init -backend-config="bucket=${PROJECT_NAME}-infra-pipeline-terraform-state"
   ```

3. Plan and apply the infrastructure (use a local terraform.tfvars for environment values):

   ```bash
   terraform plan -var-file="terraform.tfvars"
   terraform apply -var-file="terraform.tfvars"
   ```

4. Cleanup

   ```bash
   terraform destroy -var-file="terraform.tfvars"
   ```

### Notes

- Update variables in `terraform.tfvars` (`project_name`, `region`, `profile`, GitHub connection details, and `infra_credentials`) before applying. Create a local `terraform.tfvars` file if it does not exist and ensure it is not checked into version control.
- This project exists because AWS Lambda creation requires deployment artifacts to already exist (container images in ECR or zip packages in S3). Since core infrastructure is provisioned first and the CI/CD pipeline runs afterward, those artifacts do not exist yet during initial creation. This repository supports a two-step approach to bootstrap infrastructure first, then deploy Lambda artifacts through the pipeline.
- **SnapStart and Lambda aliases.** SnapStart only applies to published versions, so the API Lambda is created with `publish = true`. When wiring callers to a specific version, use an alias (for example `live`) rather than hard-coding a version number — the alias can be updated on each deploy without changing downstream references. API Gateway must integrate with and grant invoke permission on that alias (`aws_lambda_alias.live.invoke_arn` with `qualifier = "live"`), not the base function's `invoke_arn`. Pointing API Gateway at `aws_lambda_function.api.invoke_arn` invokes `$LATEST`, where SnapStart does not apply.
- **`aws_lb_target_group_attachment` appears stuck.** Terraform can sit on this resource while the ALB target group health check runs. If the Lambda has an initial function error (for example missing deployment artifact, bad handler, or runtime failure on cold start), the health check never passes and the attachment does not complete. Fix the Lambda so it runs successfully, then re-apply; the attachment should proceed once targets are healthy.
