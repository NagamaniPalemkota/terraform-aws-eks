module "db" {
    source = "git::https://github.com/NagamaniPalemkota/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    description = "SG for mysql db instance"
    common_tags = var.common_tags
    sg_name = "db"
    vpc_id = data.aws_ssm_parameter.ssm_vpc_info.value

}

module "bastion" {
    source = "git::https://github.com/NagamaniPalemkota/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    description = "SG for bastion instance"
    common_tags = var.common_tags
    sg_name = "bastion"
    vpc_id = data.aws_ssm_parameter.ssm_vpc_info.value

}

module "ingress" {
    source = "git::https://github.com/NagamaniPalemkota/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    description = "SG for Ingress controller"
    common_tags = var.common_tags
    sg_name = "ingress"
    vpc_id = data.aws_ssm_parameter.ssm_vpc_info.value

}
module "cluster" {
    source = "git::https://github.com/NagamaniPalemkota/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    description = "SG for cluster instance"
    common_tags = var.common_tags
    sg_name = "cluster"
    vpc_id = data.aws_ssm_parameter.ssm_vpc_info.value

}
module "node" {
    source = "git::https://github.com/NagamaniPalemkota/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    description = "SG for node group instance"
    common_tags = var.common_tags
    sg_name = "node"
    vpc_id = data.aws_ssm_parameter.ssm_vpc_info.value

}

module "vpn" {
    source = "git::https://github.com/NagamaniPalemkota/terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    description = "SG for VPN Instances"
    vpc_id = data.aws_ssm_parameter.ssm_vpc_info.value
    common_tags = var.common_tags
    sg_name = "vpn"
    inbound_rules = var.vpn_sg_rules
}
#inbound security group rules allowing traffic to cluster from bastion since, EKS cluster can be accessed by bastion host
resource "aws_security_group_rule" "cluster_bastion" {
    type = "ingress"
    protocol = "tcp"
    from_port = 443
    to_port = 443
    security_group_id = module.cluster.sg_id
    source_security_group_id = module.bastion.sg_id # source is from where we're getting traffic
}

#inbound security group rules allowing traffic to EKS cluster from nodes 
resource "aws_security_group_rule" "cluster_nodes" {
    type = "ingress"
    protocol = "-1" #All traffic
    from_port = 0
    to_port = 65535
    security_group_id = module.cluster.sg_id
    source_security_group_id = module.node.sg_id # source is from where we're getting traffic
}

#inbound security group rules allowing traffic to nodes from EKS cluster 
resource "aws_security_group_rule" "nodes_cluster" {
    type = "ingress"
    protocol = "-1" #All traffic
    from_port = 0
    to_port = 65535
    security_group_id = module.node.sg_id
    source_security_group_id = module.cluster.sg_id # source is from where we're getting traffic
}

#inbound security group rules allowing traffic to nodes from other nodes,within VPC CIDR range 
resource "aws_security_group_rule" "nodes_vpc" {
    type = "ingress"
    protocol = "-1" #All traffic
    from_port = 0
    to_port = 65535
    security_group_id = module.node.sg_id
    cidr_blocks = ["10.0.0.0/16"]# source is from where we're getting traffic
}

#inbound security group rules allowing traffic to db from nodes
resource "aws_security_group_rule" "db_nodes" {
    type = "ingress"
    protocol = "tcp"
    from_port = 3306
    to_port = 3306
    security_group_id = module.db.sg_id
    source_security_group_id = module.node.sg_id # source is from where we're getting traffic
}

#inbound security group rules allowing traffic to db from bastion
resource "aws_security_group_rule" "db_bastion" {
    type = "ingress"
    protocol = "tcp"
    from_port = 3306
    to_port = 3306
    security_group_id = module.db.sg_id
    source_security_group_id = module.bastion.sg_id # source is from where we're getting traffic
}

#inbound security group rules allowing traffic to bastion from public
resource "aws_security_group_rule" "bastion_public" {
    type = "ingress"
    protocol = "tcp"
    from_port = 22
    to_port = 22
    security_group_id = module.bastion.sg_id
    cidr_blocks = ["0.0.0.0/0"]  # it is from where we're getting traffic
}

# Ingress ALB accepting traffic on 443
resource "aws_security_group_rule" "ingress_public_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP" # All traffic
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.ingress.sg_id
}

# Ingress ALB accepting traffic on 80
resource "aws_security_group_rule" "ingress_public_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP" # All traffic
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.ingress.sg_id
}

#
resource "aws_security_group_rule" "node_ingress" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32768
  protocol          = "TCP" # All traffic
  source_security_group_id = module.ingress.sg_id
  security_group_id = module.node.sg_id
}

