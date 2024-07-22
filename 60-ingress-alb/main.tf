resource "aws_lb" "ingress_alb" {
  name = "${var.project_name}-${var.environment}-ingress-alb"
  internal  = false
  load_balancer_type = "application"
  security_groups    = [data.aws_ssm_parameter.ingress_sg_id.value]
  subnets    = split(",",data.aws_ssm_parameter.public_subnet_ids.value)

  enable_deletion_protection = false

  tags =merge(
    var.common_tags ,{
         Name = "${var.project_name}-${var.environment}-ingress-alb"
    }
   
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ingress_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "<h1>This is Fixed response from WEB-ALB</h1>"
      status_code  = "201"
    
  }
}
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ingress_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn = data.aws_ssm_parameter.acm_certificate_arn.value
   ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "<h1>This is Fixed response from WEB-ALB HTTPS</h1>"
      status_code  = "201"
    
  }
}
}

#creating route53 records usind load balancer DNS
module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "web-${var.environment}"
      type    = "A"
      allow_overwrite = true
      alias = {
          name = aws_lb.ingress_alb.dns_name
          zone_id = aws_lb.ingress_alb.zone_id
      }
    },
  ]
}
