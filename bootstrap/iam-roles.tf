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
# IAM Role  -- ansible server
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ansible_server_role" {

  name = "ansible-server-role"

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
# IAM POLICY
# ---------------------------------------------------------

resource "aws_iam_policy" "ansible_server_policy" {

  name = "ansible-server-policy"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      # ---------------------------------------------------------
      # SSM PARAMETER STORE
      # ---------------------------------------------------------

      {
        Sid    = "SSMParameterStoreAccess"
        Effect = "Allow"

        Action = [

          # Write parameter
          "ssm:PutParameter",

          # Read single parameter
          "ssm:GetParameter",

          # Read multiple parameters
          "ssm:GetParameters",

          # Delete parameter
          "ssm:DeleteParameter",

          # Describe parameters
          "ssm:DescribeParameters",

          # Required by Ansible AWS module
          "ssm:ListTagsForResource"
        ]

        Resource = "*"
      },

      # ---------------------------------------------------------
      # EC2 DESCRIBE
      # ---------------------------------------------------------

      {
        Sid    = "EC2Describe"
        Effect = "Allow"

        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]

        Resource = "*"
      },

      # ---------------------------------------------------------
      # AUTOSCALING DESCRIBE
      # ---------------------------------------------------------

      {
        Sid    = "AutoScalingDescribe"
        Effect = "Allow"

        Action = [
          "autoscaling:DescribeAutoScalingGroups"
        ]

        Resource = "*"
      }
    ]
  })
}

# ---------------------------------------------------------
# IAM POLICY for aws ccm
# ---------------------------------------------------------
resource "aws_iam_policy" "aws_ccm_policy" {

  name = "aws-cloud-controller-manager-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:DescribeVpcs",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeTags"
        ]

        Resource = "*"
      }
    ]
  })
}
# -----------------------------------------------------------------------------
# Attach ccm policy to kubeadm_role (control plane)
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "aws_ccm_policy_attach" {

  role = aws_iam_role.kubeadm_role.name

  policy_arn = aws_iam_policy.aws_ccm_policy.arn
}


resource "aws_iam_role_policy_attachment" "ansible_attach" {

  role       = aws_iam_role.ansible_server_role.name
  policy_arn = aws_iam_policy.ansible_server_policy.arn
}

resource "aws_iam_instance_profile" "ansible_profile" {

  name = "ansible-server-profile"

  role = aws_iam_role.ansible_server_role.name
}

# -----------------------------------------------------------------------------
# IAM Role -- control plane
# -----------------------------------------------------------------------------

resource "aws_iam_role" "kubeadm_role" {

  name = "kubeadm-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# -----------------------------------------------------------------------------
# IAM policy -- control plane for {kubeadm} 
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "cluster_autoscaler_policy" {

  name = "cluster-autoscaler-policy"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]

        Resource = "*"
      }
    ]
  })
}
# -----------------------------------------------------------------------------
# Attach cluster auto scaler policy
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {

  role = aws_iam_role.kubeadm_role.name

  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
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
