# -----------------------------------------------------------------------------
# EC2 Assume Role Policy
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
# IAM Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "kubeadm_role" {

  name = "kubeadm-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# -----------------------------------------------------------------------------
# Attach EBS CSI Policy
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "ebs_csi" {

  role = aws_iam_role.kubeadm_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# -----------------------------------------------------------------------------
# Attach EFS CSI Policy
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "efs_csi" {

  role = aws_iam_role.kubeadm_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

# -----------------------------------------------------------------------------
# Optional Recommended Policies
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "ec2_readonly" {

  role = aws_iam_role.kubeadm_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ssm" {

  role = aws_iam_role.kubeadm_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------------------------------------------------------
# Instance Profile
# -----------------------------------------------------------------------------

resource "aws_iam_instance_profile" "kubeadm_profile_01" {

  name = "kubeadm-instance-profile-01"

  role = aws_iam_role.kubeadm_role.name
}
