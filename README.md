# SonarQube on AWS

Terraform project for setting up SonarQube on AWS.

## Prerequisites

- Registered DNS domain on AWS Route53 is available
- An RSA key pair for SSH connection is available

## Prepare

```sh
cat <<EOT > terraform.tfvars
service_domain = "sq.your-domain.de"
cert_domain = "*.your-domain.de"
zone = "your-domain.de."
public_key_path = "~/.ssh/id_rsa.pub"
EOT
```

```
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa
```

## Apply

```sh
terraform init
terraform apply
```

## Resources

- [Bitnami SonarQube Stack for AWS Cloud](https://docs.bitnami.com/aws/apps/sonarqube/)
- [aws marketplace - SonarQube Certified by Bitnami](https://aws.amazon.com/marketplace/pp/Bitnami-SonarQube-Certified-by-Bitnami/B072N1Q6ZN)
- [Documentation](https://docs.bitnami.com/aws/apps/sonarqube/)
