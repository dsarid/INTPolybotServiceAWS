resource "aws_iam_role" "yolo5-role" {
  depends_on = [
    aws_iam_policy.policy_poly_dynamodb,
    aws_iam_policy.policy_poly_ecr,
    aws_iam_policy.policy_poly_s3,
    aws_iam_policy.policy_poly_sqs
  ]
  name                = "dsarid-yolo5-tf-role-${var.y5-region}"
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
    aws_iam_policy.policy_poly_sqs.arn,
    aws_iam_policy.policy_poly_ecr.arn,
    aws_iam_policy.policy_poly_s3.arn,
    aws_iam_policy.policy_poly_dynamodb.arn
  ]
}

resource "aws_iam_policy" "policy_poly_ecr" {
  name = "danielms-ecr-tf-yolo-policy-${var.y5-region}"
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
                "arn:aws:ecr:eu-central-1:019273956931:repository/aws-project-yolo5"
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
  name = "danielms-s3-tf-yolo-policy-${var.y5-region}"
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
                var.s3_arn,
                "${var.s3_arn}/*"
            ]
        }
    ]
  })
}

resource "aws_iam_policy" "policy_poly_sqs" {
  name = "danielms-sqs-tf-yolo-policy-${var.y5-region}"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "sqs:DeleteMessage",
                "sqs:ReceiveMessage"
            ],
            "Resource": var.sqs_arn
        }
    ]
  })
}

resource "aws_iam_policy" "policy_poly_dynamodb" {
  name = "danielms-dynamodb-tf-yolo-policy-${var.y5-region}"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem"
            ],
            "Resource": var.dynamodb_table_arn
        }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile_yolo" {
  name = "${var.y5-owner}-yolo-iam-${var.y5-region}"

  role = aws_iam_role.yolo5-role.name
}
