resource "aws_db_subnet_group" "wordpress" {
  name = "wordpress-db-subnet-group"

  subnet_ids = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]

  tags = {
    Name = "wordpress-db-subnet-group"
  }
}

resource "aws_db_instance" "wordpress" {
  identifier = "wordpress-db"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "wordpress"
  username = "wordpress"

  manage_master_user_password = true

  db_subnet_group_name = aws_db_subnet_group.wordpress.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  skip_final_snapshot = true

  tags = {
    Name = "wordpress-db"
  }
}