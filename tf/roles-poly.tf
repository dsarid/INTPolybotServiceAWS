resource "aws_iam_role" "polybot-role" {
  depends_on = [
    aws_iam_policy.policy_poly_secret,
    aws_iam_policy.policy_poly_ecr,
    aws_iam_policy.policy_poly_dynamodb,
    aws_iam_policy.policy_poly_s3,
    aws_iam_policy.policy_poly_sqs,
    aws_iam_policy.policy_poly_acm
  ]
  name                = "dsarid-polybot-tf-role-${var.region}"
  assume_role_policy  = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
  managed_policy_arns = [
    aws_iam_policy.policy_poly_secret.arn,
    aws_iam_policy.policy_poly_ecr.arn,
    aws_iam_policy.policy_poly_dynamodb.arn,
    aws_iam_policy.policy_poly_s3.arn,
    aws_iam_policy.policy_poly_sqs.arn,
    aws_iam_policy.policy_poly_acm.arn
  ]
}

resource "aws_iam_policy" "policy_poly_secret" {
  depends_on = [aws_secretsmanager_secret.telegram_token]
  name = "danielms-secret-tf-policy-${var.region}"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": [
                "arn:aws:secretsmanager:eu-central-1:019273956931:secret:cert_public_key-K5bN0T",
                "arn:aws:secretsmanager:eu-central-1:019273956931:secret:telegram_bot_token-ILCci7",
                aws_secretsmanager_secret.telegram_token.arn
            ]
        }
    ]
  })
}

resource "aws_iam_policy" "policy_poly_dynamodb" {
  depends_on = [module.dynamodb_table]
  name = "danielms-dynamodb-tf-policy-${var.region}"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:Scan",
                "dynamodb:Query"
            ],
            "Resource": module.dynamodb_table.dynamodb_table_arn
        }
    ]
  })
}

resource "aws_iam_policy" "policy_poly_ecr" {
  name = "danielms-ecr-tf-policy-${var.region}"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:DescribeImages"
            ],
            "Resource": [
                "arn:aws:ecr:eu-central-1:019273956931:repository/aws-project-polybot"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ecr:GetAuthorizationToken",
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_policy" "policy_poly_s3" {
  depends_on = [aws_s3_bucket.main-bucket]
  name = "danielms-s3-tf-policy-${var.region}"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectAttributes"
            ],
            "Resource": [
                aws_s3_bucket.main-bucket.arn,
                "${aws_s3_bucket.main-bucket.arn}/*"
            ]
        }
    ]
  })
}

resource "aws_iam_policy" "policy_poly_sqs" {
  depends_on = [aws_sqs_queue.polybot-sqs]
  name = "danielms-sqs-tf-policy-${var.region}"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "sqs:SendMessage"
            ],
            "Resource": aws_sqs_queue.polybot-sqs.arn
        }
    ]
  })
}

resource "aws_iam_policy" "policy_poly_acm" {
  depends_on = [aws_acm_certificate.cert]
  name = "danielms-acm-tf-policy-${var.region}"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "acm:GetCertificate",
            "Resource": aws_acm_certificate.cert.arn
        }
    ]
  })
}


resource "aws_iam_instance_profile" "ec2_instance_profile_poly" {
  name = "${var.owner}-polybot-iam-${var.region}"

  role = aws_iam_role.polybot-role.name  // Reference to the IAM role name
}
