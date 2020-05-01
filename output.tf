output "server_public_ip" {
  description = "The public ip of the server"
  value       = module.ec2.public_ip
}

output "smtp_host" {
  description = "The SMTP endpoint"
  value       = module.ses.smtp_host
}

output "smtp_user_name" {
  description = "The SMTP user name"
  value       = module.ses.smtp_user_name
}

output "smtp_password" {
  description = "The SMTP password"
  value       = module.ses.smtp_password
}
