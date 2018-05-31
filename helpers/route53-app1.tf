
resource "aws_route53_record" "app1" {
  zone_id = "Z1BRWWRJTM3LQO"
  name    = "app1"
  type    = "CNAME"
  records = ["my-load-balance"]
  ttl     = "60"
}
