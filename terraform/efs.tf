
resource "aws_security_group" "efs_sg" {
  name        = "${var.environment}-efs-sg"
  description = "${var.environment} EFS Security Group"

  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_efs_file_system" "efs" {
  #  creation_token = "my-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
  encrypted        = true

  availability_zone_name = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.environment}-efs-storage"
  }
}


resource "aws_efs_access_point" "efs_access_point" {
  file_system_id = aws_efs_file_system.efs.id
  posix_user {
    uid = "1000"
    gid = "1000"
  }

  root_directory {
    path = "/"
    creation_info {
      owner_uid   = "1000"
      owner_gid   = "1000"
      permissions = "0755"
    }
  }
}



resource "aws_efs_mount_target" "efs_mount_target" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.efs_sg.id]
}

