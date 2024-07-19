locals {
    private_subnet_id =  data.aws_ssm_parameter.private_subnet_ids.value
    vpc_id = data.aws_ssm_parameter.ssm_vpc_info.value
}