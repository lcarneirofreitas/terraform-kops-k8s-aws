
resource "aws_route53_record" "app1" {
  zone_id = "Z1BRWWRJTM3LQO"
  name    = "app1"
  type    = "CNAME"
  records = ["aabb93d7a5c6611e89a761236b84818c-1370859360.us-east-1.elb.amazonaws.com"]
  ttl     = "60"
}
