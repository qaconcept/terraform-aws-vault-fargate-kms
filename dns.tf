# The SSL Certificate
resource "aws_acm_certificate" "vault" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# The Validation Record
resource "aws_route53_record" "vault_validation" {
  for_each = {
    for dvo in aws_acm_certificate.vault.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# The Alias Record
resource "aws_route53_record" "vault_alias" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    # Replace 'module.ecs_vault' with the actual name used in your root main.tf
    name                   = module.ecs_vault.alb_dns_name
    zone_id                = module.ecs_vault.alb_zone_id
    evaluate_target_health = true
  }
}