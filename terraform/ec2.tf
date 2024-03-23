data "aws_ami" "amzn" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

data "aws_eip" "by_tag" {
  filter {
    name   = "tag:Project"
    values = ["NetSPI_EIP"]
  }
}


####### SSH KEY PAIR #####


resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.environment}-ssh-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}
# resource "aws_ssm_parameter" "server_key" {
#   name        = "/${var.environment}/ec2_server/private_key"
#   description = "Private key of ec2 linux server ${var.environment}-server"
#   type        = "String"
#   value       = tls_private_key.ssh_key.private_key_pem
# }

#### S3 bucket creation 


resource "aws_s3_bucket" "bucket" {
  bucket = "${var.environment}-netspi-test-bucket"
}

# resource "aws_s3_bucket_acl" "bucket_acl" {
#   bucket = aws_s3_bucket.bucket.id
#   acl    = "private"
# }

#### IAM ROLE AND POLICY ###
resource "aws_iam_policy" "iam_policy" {
  name        = "${var.environment}-iam-policy"
  path        = "/"
  description = "Policy to create EKS cluster Linux Nodes"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListObjectsInBucket",
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = ["${aws_s3_bucket.bucket.arn}"]
      },
      {
        Sid      = "AllObjectActions",
        Effect   = "Allow",
        Action   = "s3:*Object",
        Resource = ["${aws_s3_bucket.bucket.arn}/*"]
      }
    ]
  })
}
resource "aws_iam_role" "iam_role" {
  name                = "${var.environment}-server-iam-role"
  managed_policy_arns = [resource.aws_iam_policy.iam_policy.arn]
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_instance_profile" "iam_role_profile" {
  name = "${var.environment}-server-iam-profile"
  role = aws_iam_role.iam_role.name
}



###### SECURITY GROUP 

resource "aws_security_group" "instance_sg" {
  name        = "${var.environment}-server-sg"
  description = "Security group for EC2 instance allowing inbound internet access"

  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

#### EC2 Instance
resource "aws_instance" "server" {
  depends_on                  = [aws_security_group.instance_sg, aws_iam_instance_profile.iam_role_profile, aws_efs_access_point.efs_access_point, module.vpc]
  ami                         = data.aws_ami.amzn.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  security_groups             = [aws_security_group.instance_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.iam_role_profile.name
  associate_public_ip_address = false # To ensure no default public IP
  key_name                    = aws_key_pair.ssh_key.key_name

  user_data = <<EOF
#!/bin/bash
mkdir /data/test -p
echo "mounting" >> /file
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${aws_efs_file_system.efs.dns_name}:/ /data/test

EOF

  tags = {
    Name = "${var.environment}-server"
  }
}

resource "aws_eip_association" "eip_association" {
  instance_id = aws_instance.server.id
  public_ip   = data.aws_eip.by_tag.public_ip
}