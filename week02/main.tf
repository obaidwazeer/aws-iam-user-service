
# Create an EC2 role that can only read one S3 bucket.
resource "aws_iam_role" "ec2-role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    version = "2012-10-17"
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

resource "aws_iam_role_policy" "ec2-role-policy" {
    name = "ec2-role-policy"
    role = aws_iam_role.ec2-role.name
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = "s3:ReadObject"
                Resource = [
                "arn:aws:s3:::my-sample-bucket"
            ]
            }
        ]
    })
}

# Attach it through an instance profile.
resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2-role.name
}


# ======================== To Do ==============================
# Verify the role using aws sts get-caller-identity.
# Download one object from the allowed bucket.
# Try accessing another bucket and confirm that it is denied.
# Remove the instance profile and observe what happens to AWS CLI authentication.
# Restore the instance profile and verify that access works again.