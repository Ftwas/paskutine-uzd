# AWS Provider konfigūracija
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"        # AWS provider šaltinis
      version = "~> 5.0"               # Naudoti AWS provider 5.x versiją
    }
  }
  # S3 backend state saugojimui (remote state management)
  backend "s3" {
    bucket = "vcsbucket112345"         # S3 bucket pavadinimas state failui
    key    = "terraform.tfstate"       # State failo pavadinimas bucket'e
    region = "eu-west-1"               # AWS regionas kur saugomas state
  }
}

# AWS provider konfigūracija
provider "aws" {
  region = "eu-west-1"                 # Pagrindinės AWS regionas (Airija)
}

# S3 bucket Terraform state saugojimui
resource "aws_s3_bucket" "terraform_state" {
  bucket = "vcsbucket112345-new"       # Unikalus S3 bucket pavadinimas
  
  tags = {
    Name        = "Terraform State Bucket"  # Bucket tag'as identifikacijai
    Environment = "production"              # Aplinkos tag'as
  }
}

# S3 bucket versioning įjungimas
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id  # Nuoroda į sukurtą bucket
  versioning_configuration {
    status = "Enabled"                        # Įjungti versioning (state failų istorija)
  }
}

# S3 bucket šifravimas
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id  # Nuoroda į sukurtą bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"                # Naudoti AES256 šifravimo algoritmą
    }
  }
}

# S3 bucket public access blokavimas (saugumui)
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id  # Nuoroda į sukurtą bucket

  block_public_acls       = true             # Blokuoti public ACL
  block_public_policy     = true             # Blokuoti public policy
  ignore_public_acls      = true             # Ignoruoti public ACL
  restrict_public_buckets = true             # Apriboti public bucket'us
}

# VPC (Virtual Private Cloud) sukūrimas
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"       # IP adresų diapazonas (65536 adresų)
  enable_dns_hostnames = true                # Įjungti DNS hostnames
  enable_dns_support   = true                # Įjungti DNS palaikymą
  
  tags = {
    Name = "main-vpc"                        # VPC pavadinimas
  }
}

# Internet Gateway (interneto prieiga)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id                   # Priskirti prie main VPC
  
  tags = {
    Name = "main-igw"                        # Internet Gateway pavadinimas
  }
}

# Public subnet (viešas tinklas)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id  # Priskirti prie main VPC
  cidr_block              = "10.0.1.0/24"   # IP diapazonas (256 adresai)
  availability_zone       = "eu-west-1a"    # Konkretus AZ (Availability Zone)
  map_public_ip_on_launch = true            # Automatiškai priskirti public IP
  
  tags = {
    Name = "public-subnet"                   # Subnet pavadinimas
  }
}

# Route table (maršrutizavimo lentelė)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id                   # Priskirti prie main VPC
  
  route {
    cidr_block = "0.0.0.0/0"                # Visas interneto srautas
    gateway_id = aws_internet_gateway.main.id # Nukreipti per Internet Gateway
  }
  
  tags = {
    Name = "public-rt"                       # Route table pavadinimas
  }
}

# Route table association (susieti subnet su route table)
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id     # Public subnet ID
  route_table_id = aws_route_table.public.id # Public route table ID
}

# Security Group (firewall taisyklės)
resource "aws_security_group" "web" {
  name        = "web-sg"                     # Security group pavadinimas
  description = "Security group for web application"  # Aprašymas
  vpc_id      = aws_vpc.main.id              # Priskirti prie main VPC

  # Ingress taisyklės (įeinantis srautas)
  ingress {
    from_port   = 80                         # HTTP portas
    to_port     = 80
    protocol    = "tcp"                      # TCP protokolas
    cidr_blocks = ["0.0.0.0/0"]            # Leidžiama iš bet kur
  }

  ingress {
    from_port   = 22                         # SSH portas
    to_port     = 22
    protocol    = "tcp"                      # TCP protokolas
    cidr_blocks = ["0.0.0.0/0"]            # Leidžiama iš bet kur
  }

  # Egress taisyklės (išeinantis srautas)
  egress {
    from_port   = 0                          # Visi portai
    to_port     = 0
    protocol    = "-1"                       # Visi protokolai
    cidr_blocks = ["0.0.0.0/0"]            # Leidžiama į bet kur
  }

  tags = {
    Name = "web-sg"                          # Security group pavadinimas
  }
}

# EC2 instance (virtualus serveris)
resource "aws_instance" "web" {
  ami           = "ami-0d64bb532e0502c46"    # Amazon Linux 2 AMI ID (eu-west-1)
  instance_type = "t2.micro"                 # Instance tipas (nemokamas tier)
  
  subnet_id                   = aws_subnet.public.id        # Priskirti prie public subnet
  vpc_security_group_ids      = [aws_security_group.web.id] # Priskirti security group
  associate_public_ip_address = true                        # Priskirti public IP
  
  tags = {
    Name = "web-server"                      # EC2 instance pavadinimas
  }
}

# Outputs (išvestys po terraform apply)
output "instance_public_ip" {
  value = aws_instance.web.public_ip         # Parodyti EC2 public IP
}

output "s3_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket  # Parodyti S3 bucket pavadinimą
}
