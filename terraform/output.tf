output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet1" {
  value = aws_subnet.public1.id
}

output "public_subnet2" {
  value = aws_subnet.public2.id
}


# output "alb_security_group_id" {
#   value = aws_security_group.alb.id
# }

output "ec2_security_group_id" {
  value = aws_security_group.ec2.id
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.web.arn
}

output "launch_template_id" {
  value = aws_launch_template.web.id
}

output "asg_name" {
  value = aws_autoscaling_group.web.name
}

output "asg_min_size" {
  value = aws_autoscaling_group.web.min_size
}

output "asg_max_size" {
  value = aws_autoscaling_group.web.max_size

}

output "rds_endpoint" {
  value = aws_db_instance.wordpress.address
}

output "rds_port" {
  value = aws_db_instance.wordpress.port
}

output "rds_database" {
  value = aws_db_instance.wordpress.db_name
}

output "rds_username" {
  value = aws_db_instance.wordpress.username
}

output "rds_secret_arn" {
  value     = aws_db_instance.wordpress.master_user_secret[0].secret_arn
  sensitive = true
}