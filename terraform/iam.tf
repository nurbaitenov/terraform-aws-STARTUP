resource "aws_iam_role" "wordpress_ec2" {
  name = "wordpress-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "wordpress_secret" {
  name = "wordpress-secret-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_db_instance.wordpress.master_user_secret[0].secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "wordpress_secret" {
  role       = aws_iam_role.wordpress_ec2.name
  policy_arn = aws_iam_policy.wordpress_secret.arn
}

resource "aws_iam_instance_profile" "wordpress" {
  name = "wordpress-ec2-profile"
  role = aws_iam_role.wordpress_ec2.name
}