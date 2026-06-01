# -----------------------------------------------------------------------------
# step 1: EC2 Assume Role Policy
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "ec2_assume_role" {

  statement {

    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com"
      ]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

# -----------------------------------------------------------------------------
# step 2: IAM Role  -- db-plane
# ------------------------------------------------------------------------------
resource "aws_iam_role" "db_plane_role" {

  name = "db-plane-role"

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

# ---------------------------------------------------------
# step 4: IAM ROLE POLICY ATTACHMENT db plane
# ---------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ssm_attach_1" {

  role = aws_iam_role.db_plane_role.name

  policy_arn = aws_iam_policy.ssm_join_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_attach_2" {

  role = aws_iam_role.db_plane_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ---------------------------------------------------------
# step 5: IAM INSTANCE PROFILE -- db-plane
# ---------------------------------------------------------
resource "aws_iam_instance_profile" "db_plane_profile" {

  name = "db-plane-profile"

  role = aws_iam_role.db_plane_role.name
}

# -----------------------------------------------------------------------------
# Attach EBS CSI Policy
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "ebs_csi" {

  role = aws_iam_role.db_plane_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# -----------------------------------------------------------------------------
# Attach ccm policy to db plane role
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "aws_ccm_policy_attach_db_plane" {

  role = aws_iam_role.db_plane_role.name

  policy_arn = data.aws_iam_policy.aws_ccm_policy.arn
}
