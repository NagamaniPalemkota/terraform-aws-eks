#creating acm https certificate
resource "aws_acm_certificate" "expense" {
  domain_name       = "*.${var.zone_name}"
  validation_method = "DNS"

  tags= merge(
    var.common_tags,
 {
    Name = "${var.project_name}-${var.environment}"
    }
  )
}

#creating a dns record for the above certificate
resource "aws_route53_record" "expense" {
  for_each = {
    for dvo in aws_acm_certificate.expense.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 1
  type            = each.value.type
  zone_id         = var.zone_id
}

#validating the doamin through certificate
resource "aws_acm_certificate_validation" "backend" {
  certificate_arn         = aws_acm_certificate.expense.arn
  validation_record_fqdns = [for record in aws_route53_record.expense : record.fqdn]
}
