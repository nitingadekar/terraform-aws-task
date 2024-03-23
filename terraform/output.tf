output "s3_bucket_id" {
  value = aws_s3_bucket.bucket.id
}
output "efs_volume_id" {
  value = aws_efs_file_system.efs.id
}

output "ec2_instance_id" {
  value = aws_instance.server.id
}

output "ec2_security_group_id" {
  value = aws_security_group.instance_sg.id
}

output "ec2_subnet_id" {
  value = aws_instance.server.subnet_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
output "eip" {
  value = data.aws_eip.by_tag.public_ip
}
output "availability_zone_name" {
  value = data.aws_availability_zones.available.all_availability_zones
}