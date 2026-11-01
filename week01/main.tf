# create an IAM group
resource "aws_iam_group" "developers" {
  name = "Developers"
  path = "/developers-group/"
}

# create user
resource "aws_iam_user" "obaid" {
  name = "obaid"
  path = "/dev/"
}

resource "aws_iam_user" "ijaz" {
  name = "ijaz"
  path = "/dev/"
}

# add the above two users to the developers group
resource "aws_iam_group_membership" "dev-team" {
  name = "developers group"
  users = [
    aws_iam_user.obaid.name,
    aws_iam_user.ijaz.name
  ]
  group = aws_iam_group.developers.name
}

# attach the aws managed read-only policy to the developers group
resource "aws_iam_group_policy_attachment" "policy" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# create a role for ec2 (trust policy)
resource "aws_iam_role" "ec2-role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

# policy for the aws ec2-role (permission policy)
resource "aws_iam_role_policy" "ec2-role-policy" {
  name = "ec2-role-policy"
  role = aws_iam_role.ec2-role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "secretsmanager:GetSecretValue"
      ]

      Resource = "arn:aws:secretsmanager:eu-north-1:482146446360:secret:prod/laravel/database-bootstrap-*"
    }]
  })
}

resource "aws_iam_role" "lambda-role" {
  name = "lembda-function-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "lambda.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda-role-policy" {
  name = "lambda-function-role-policy"
  role = aws_iam_role.lambda-role.id
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]

      Resource = "arn:aws:logs:eu-north-1:482146446360:*"
    }]
  })
}

# attach an AWS managed policy to ec2
resource "aws_iam_role_policy_attachment" "ec2-read-access" {
  role       = aws_iam_role.ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# customer managed policy to manage s3
resource "aws_iam_policy" "cm-policy" {
  name        = "customer-managed-policy"
  description = "customer managed policy for an s3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]

      Resource = [
        "arn:aws:s3:::your-bucket-name",
        "arn:aws:s3:::your-bucket-name/*"
      ]
    }]
  })
}

# inline policy
resource "aws_iam_role_policy" "describe-ec2" {
  name = "describe-ec2"
  role = aws_iam_role.ec2-role.name
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeTags"
      ]

      Resource = "*"
    }]
  })
}

# Create an IAM policy that permits:
# - Reading objects from laravel-assets-example/images/.
# - Not reading objects from laravel-assets-example/private/.
# - Listing the bucket only when needed.
resource "aws_iam_policy" "s3-policy" {
    name = "s3-bucket-policy"
    description = "Se bucket policy"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [ {
            Effect = "Allow"
            Action = [
                "s3:GetObject",
                "s3:ListBucket"
            ]
            Resource = [
                "arn:aws:s3:::laravel-assets-example",
                "arn:aws:s3:::laravel-assets-example/*"
            ]

        } ]
    })
}

# Create:
# 1. An EC2 role with an identity-based S3 permission.
# 2. An S3 bucket policy allowing a specified role.

# first we create an ec2 role for our ec2 instance below
resource "aws_iam_role" "ec2-s3-role" {
    name = "ec2-identity-based-policy"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = "sts:AssumeRole"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
        
    })
}

# secondely we create a custome policy for accessing s3 bucket
resource "aws_iam_policy" "s3-bucket-policy" {
    name = "s3-bucket-policy"
    policy = jsonencode({
        Version = "2012-07-10"
        Statement = {
            Effect = "Allow"
            Action = [
                "s3:ListBucket"
            ]
            Resource = [
                "arn:aws:s3:::my-sample-bucket"
            ]
        }

        Statement = {
            Effect = "Allow"
            Action = [
                "s3:GetObject"
            ]
            Resource = [
                "arn:aws:s3:::my-sample-bucket/*"
            ]
        }
    })
}

# now attach the s3-bucket-policy to ec2-s3-role
resource "aws_iam_role_policy_attachment" "attach-s3-policy" {
    role = aws_iam_role.ec2-s3-role.id
    policy_arn = aws_iam_policy.s3-bucket-policy.arn
}

# now create an instance profile for the above role, to be consumed by the EC2
resource "aws_iam_instance_profile" "ec2-instance-profile" {
    name = "ec2-instance-profile"
    role = aws_iam_role.ec2-s3-role.name
}

# now create an ec2 instance
resource "aws_instance" "ec2-instance" {
    iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.name
    ami                  = "ami-0c55b159cbfafe1f0"
    instance_type        = "t3.micro"
}

# Write a custom policy for an EC2 role with the following requirements:
# 1. It can read one Secrets Manager secret.
# 2. It can download objects only from reports/ in a particular S3 bucket.
# 3. It can upload logs only to logs/ in that bucket.
# 4. It cannot delete objects.
# 5. It cannot access other Secrets Manager secrets.

# using jsonencode
resource "aws_iam_policy" "ec2-s3-role" {
    name = "custome-policy-for-ec2"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = {
            Sid = "AllowAWSSecrets"
            Effect = "Allow"
            Action = [
                "secretsmanager:GetSecretValue"
            ]
            Resource = [
                "arn:aws:secretsmanager:eu-north-1:482146446360:secret:prod/laravel/database-bootstrap-*"
            ]
        }
        Statement = {
            Sid = "DownloadObjectFromS3"
            Action = [
                "s3:GetObject"
            ]
            Resource = [
                "arn:aws:s3:::my-sample-bucket/reports/*"
            ]
        }
        Statement = {
            Sid = "UploadToS3"
            Action = [
                "s3:SetUpload"
            ]
            Resource = [
                "arn:aws:s3:::my-sample-bucket/logs/*"
            ]
        }
    })
}