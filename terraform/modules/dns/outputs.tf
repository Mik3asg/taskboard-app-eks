output "zone_id" {
  description = "Route53 hosted zone ID — used in IRSA policies for ExternalDNS and cert-manager"
  value       = aws_route53_zone.main.zone_id
}

output "zone_name" {
  description = "The DNS zone name"
  value       = aws_route53_zone.main.name
}

output "name_servers" {
  description = "NS records to add to the parent zone for delegation"
  value       = aws_route53_zone.main.name_servers
}
