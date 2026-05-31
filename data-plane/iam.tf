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
# step 2: IAM Role  -- data-plane
# ------------------------------------------------------------------------------
resource "aws_iam_role" "data_plane_role" {

  name = "data-plane-role"

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
#  step 3: IAM POLICY - data-plane
# ---------------------------------------------------------
resource "aws_iam_policy" "ssm_join_policy" {

  name = "ssm-join-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ssm:GetParameter"
        ]

        Resource = [
          "*"
        ]
      }
    ]
  })
}

# ---------------------------------------------------------
# step 4: IAM ROLE POLICY ATTACHMENT
# ---------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ssm_attach_1" {

  role = aws_iam_role.data_plane_role.name

  policy_arn = aws_iam_policy.ssm_join_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_attach_2" {

  role = aws_iam_role.data_plane_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ---------------------------------------------------------
# step 5: IAM INSTANCE PROFILE -- data-plane
# ---------------------------------------------------------
resource "aws_iam_instance_profile" "data_plane_profile" {

  name = "data-plane-profile"

  role = aws_iam_role.data_plane_role.name
}

# -----------------------------------------------------------------------------
# Attach EBS CSI Policy
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "ebs_csi" {

  role = aws_iam_role.data_plane_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# -----------------------------------------------------------------------------
# Attach EFS CSI Policy
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "efs_csi" {

  role = aws_iam_role.data_plane_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

# -----------------------------------------------------------------------------
# Attach ccm policy to data plane role (data plane)
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "aws_ccm_policy_attach" {

  role = aws_iam_role.data_plane_role.name

  policy_arn = data.aws_iam_policy.aws_ccm_policy.arn
}
