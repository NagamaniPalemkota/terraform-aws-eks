locals {
    private_subnet_ids =  data.aws_ssm_parameter.private_subnet_ids.value
    vpc_id = data.aws_ssm_parameter.ssm_vpc_info.value
    cluster_sg_id = data.aws_ssm_parameter.cluster_sg_id.value
    node_sg_id = data.aws_ssm_parameter.node_sg_id.value
}