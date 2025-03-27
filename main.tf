provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "dart_vpc" {
  cidr_block = "172.200.0.0/16"
  tags = {
    Name = "dart-vpc"
  }
}

resource "aws_subnet" "sn_priv01" {
  vpc_id = aws_vpc.dart_vpc.id
  cidr_block = "172.200.1.0/24"
  availability_zone = "us-west-1c"
  tags = {
    Name = "dart-sn_priv01"
  }
}
resource "aws_subnet" "sn_priv02" {
  vpc_id = aws_vpc.dart_vpc.id
  cidr_block = "172.200.2.0/24"
  availability_zone = "us-west-1b"
  tags = {
    Name = "dart-sn_priv02"
  }
}
resource "aws_subnet" "sn_pub01" {
  vpc_id = aws_vpc.dart_vpc.id
  cidr_block = "172.200.3.0/24"
  availability_zone = "us-west-1c"
  tags = {
    Name = "dart-sn_pub01"
  }
}
resource "aws_subnet" "sn_pub02" {
  vpc_id = aws_vpc.dart_vpc.id
  cidr_block = "172.200.4.0/24"
  availability_zone = "us-west-1b"
  tags = {
    Name = "dart-sn_pub02"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dart_vpc.id
  tags = {
    Name = "dart-igw" 
  }
}

resource "aws_route_table" "route_pub" {
  vpc_id = aws_vpc.dart_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "dart-routetable"
  }
}

resource "aws_route_table_association" "pub01assoc" {
  subnet_id = aws_subnet.sn_pub01.id
  route_table_id = aws_route_table.route_pub.id
}
resource "aws_route_table_association" "pub02assoc" {
  subnet_id = aws_subnet.sn_pub02.id
  route_table_id = aws_route_table.route_pub.id
}




resource "aws_security_group" "sg_nginx" {
  name        = "dart-sg-nginx"
  description = "Grupo de segurança para o servidor NGINX"
  vpc_id      = aws_vpc.dart_vpc.id

 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dart-sg-nginx"
  }
}


resource "aws_instance" "nginx" {
  ami           = "ami-03f65b8614a860c29" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.sn_pub01.id
  vpc_security_group_ids = [aws_security_group.sg_nginx.id]
  
  
  associate_public_ip_address = true
  

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install nginx -y
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF

  tags = {
    Name = "dart-nginx"
  }
}


output "nginx_instance_ip" {
  description = "IP público da instância NGINX"
  value = aws_instance.nginx.public_ip
}

output "security_group_id" {
  description = "ID do grupo de segurança criado"
  value = aws_security_group.sg_nginx.id
}