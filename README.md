# terraform-aws-task
Requirement:  
1. Create VPC with public and private subnets  
2. Create S3 bucket with private acl  
3. Create EFS file system to be accessible from EC2 instance  
4. EC2 instance to use Elastic IP which is manually created in the account. Should have iam permission to access s3 bucket. Should auto mount the efs storage on /data/test path on launch. 



## Execution 

* Initialize backend

1. Create S3 bucket and Dynamo table in your aws account to save state file and state lock respectively.   
2. Update the s3 backend config in `config/backend.hcl`
   ```
   bucket         = "s3_bucket_name"
   key            = "environment/state/key/terraform.tfstate"
   region         = "your_region"
   dynamodb_table = "dynamodb_table_for_state_lock"
   ```  
3. Initialze the backend with terraform command 
   `terraform init config/backend.hcl`

* Configure inputs for resources. 

1. Configure the minimal inputs in `config/values.tfvars` file 

```
environment = "dev"  # update environment name to add  prefix for all resources
region  = "ap-south-1"  # udpate the region to create resources in
vpc_cidr = "10.0.0.0/16" # Change the vpc cidr
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] # Add list of public subnets to create
public_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"] # Add list of private subnets to create
instance_type = "t3.micro"  # instance type to be used for EC2 instance creation. 
```

2. Run plan to validate changes. 

    `terraform validate`

    `terraform plan --var-file config/values.tfvars`

    If plan looks satisfying, then apply the changes

    `terraform apply --var-file config/values.tfvars` 

    Type `yes` when prompted to approve. 

3. Make note of outputs at the end of successfull execution. 


4. Get ssh pem file from terraform output. 

`terraform output -raw private_key`