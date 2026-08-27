# to get AMI 

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template 

resource "aws_launch_template" "web" {
  name_prefix   = "wordpress-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.wordpress.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash

    set -e

    # -------------------------
    # Install packages
    # -------------------------

    dnf update -y

    dnf install -y \
      nginx \
      php \
      php-fpm \
      php-mysqlnd \
      php-gd \
      php-mbstring \
      php-xml \
      php-json \
      php-curl \
      php-zip \
      wget \
      tar \
      unzip

    # -------------------------
    # Start PHP-FPM
    # -------------------------

    systemctl enable php-fpm
    systemctl start php-fpm

    # -------------------------
    # Download WordPress
    # -------------------------

    cd /tmp

    wget https://wordpress.org/latest.tar.gz

    tar -xzf latest.tar.gz

    rm -rf /var/www/html

    mv wordpress /var/www/html

    # -------------------------
    # Get RDS credentials
    # -------------------------

    SECRET_ARN="${aws_db_instance.wordpress.master_user_secret[0].secret_arn}"

    SECRET_JSON=$(aws secretsmanager get-secret-value \
      --secret-id "$SECRET_ARN" \
      --query SecretString \
      --output text)

    DB_USERNAME=$(echo "$SECRET_JSON" | python3 -c \
      'import sys,json; print(json.load(sys.stdin)["username"])')

    DB_PASSWORD=$(echo "$SECRET_JSON" | python3 -c \
      'import sys,json; print(json.load(sys.stdin)["password"])')

    DB_HOST="${aws_db_instance.wordpress.address}"
    DB_NAME="${aws_db_instance.wordpress.db_name}"

    # -------------------------
    # Create wp-config.php
    # -------------------------

    cp /var/www/html/wp-config-sample.php \
       /var/www/html/wp-config.php

    sed -i "s/database_name_here/$DB_NAME/" \
      /var/www/html/wp-config.php

    sed -i "s/username_here/$DB_USERNAME/" \
      /var/www/html/wp-config.php

    sed -i "s/password_here/$DB_PASSWORD/" \
      /var/www/html/wp-config.php

    sed -i "s/localhost/$DB_HOST/" \
      /var/www/html/wp-config.php

    # -------------------------
    # Configure NGINX
    # -------------------------

    rm -f /etc/nginx/conf.d/default.conf

    cat > /etc/nginx/conf.d/wordpress.conf <<'NGINX'
    server {
        listen 80;
        server_name _;

        root /var/www/html;
        index index.php index.html;

        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_pass unix:/run/php-fpm/www.sock;
        }

        location ~ /\.ht {
            deny all;
        }
    }
    NGINX

    # -------------------------
    # Permissions
    # -------------------------

    chown -R nginx:nginx /var/www/html
    chmod -R 755 /var/www/html

    # -------------------------
    # Start services
    # -------------------------

    systemctl enable nginx
    systemctl restart nginx

  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "wordpress-server"
    }
  }
}

# ASG #

resource "aws_autoscaling_group" "web" {
  name = "web-asg"

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  vpc_zone_identifier = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]

  target_group_arns = [
    aws_lb_target_group.web.arn
  ]

  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Startup in AWS"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }
}