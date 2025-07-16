# AWS DevSecOps Pipeline

## Projekto aprašymas
Terraform infrastruktūra su Python Flask aplikacija ir pilnu DevSecOps pipeline.

## Struktūra
- `main.tf` - Terraform konfigūracija
- `app/` - Python aplikacija
- `.github/workflows/` - GitHub Actions

## Paleidimas
1. Sukurti S3 bucket state saugojimui
2. Nustatyti AWS credentials GitHub secrets
3. Nustatyti Snyk token
4. Push į main branch

## Saugumas
- Checkov IaC skanavimas
- Snyk dependency ir code skanavimas
- Fail on high/critical vulnerabilities
