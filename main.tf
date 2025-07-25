provider "aws" {
  region = var.region
}

variable "region" {
  default = "us-west-2"
}

resource "aws_iam_role" "conditionally_public_role" {
  name = "conditionally-public-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = var.region == "us-west-2" ? {
          "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E1234567890"
        } : {
          "AWS": "*"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_group" "developers" {
  name = "dev-group"
}

resource "aws_iam_group_policy_attachment" "dev_attach_any_policy" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

data "aws_iam_policy_document" "public_acl" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.static_site.bucket}/*"]
  }
}

resource "aws_s3_bucket" "static_site" {
  bucket = "dryrun-showcase-site"
  acl    = "private"

  
  policy = data.aws_iam_policy_document.public_acl.json
}
