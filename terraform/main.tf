# --------------------
# EC2
# --------------------

resource "aws_instance" "web" {
  ami           = "ami-0332d564d76dbd8d6" # AMI hardcoded
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  tags = {
    Name = "terraform-ec2"
  }
}