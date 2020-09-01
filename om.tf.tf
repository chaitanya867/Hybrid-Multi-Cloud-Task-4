provider "aws" {
  region  = "ap-south-1"
  profile = "mychaitanya"
}
resource "aws_vpc" "wpmysqlvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "main_vpc"
  }
}
resource "aws_subnet" "wp_subnet" {
  vpc_id     = "${aws_vpc.wpmysqlvpc.id}"
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "wp_subnet"
  }
}
resource "aws_subnet" "mysql_subnet" {
  vpc_id     = "${aws_vpc.wpmysqlvpc.id}"
  cidr_block = "192.168.2.0/24"
  map_public_ip_on_launch = "false"


  tags = {
    Name = "mysql_subnet"
  }
}
resource "aws_internet_gateway" "gateway1" {
  vpc_id = "${aws_vpc.wpmysqlvpc.id}"

  tags = {
    Name = "main_gateway"
  }
}
resource "aws_route_table" "routetable1" {
  vpc_id = "${aws_vpc.wpmysqlvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gateway1.id}"
  }

 

  tags = {
    Name = "main_routetable"
  }
}
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.wp_subnet.id
  route_table_id = aws_route_table.routetable1.id
}
resource "aws_security_group" "sg1" {
  name        = "sg_to_allow_http_ssh"
  vpc_id      = aws_vpc.wpmysqlvpc.id

  ingress {
    description = "allow http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow ssh"
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
    Name = "wp_sg"
  }
}
resource "aws_security_group" "sg2" {
  name        = "allow_mysql"
  vpc_id      = aws_vpc.wpmysqlvpc.id

  ingress {
    description = "allow_for_mysql"
    from_port   = 3306
    to_port     = 3306
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
    Name = "mysql_sg"
  }
}
resource "aws_security_group" "sg3" {
  name        = "sg_ssh"
  vpc_id      = aws_vpc.wpmysqlvpc.id

 
  ingress {
    description = "allow ssh"
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
    Name = "bationhost_sg"
  }
}
resource "aws_security_group" "sg4" {
  name        = "sg_ssh_forsql"
  vpc_id      = aws_vpc.wpmysqlvpc.id

 
  ingress {
    description = "allow ssh"
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
    Name = "bationhostmysql_sg"
  }
}
resource "aws_instance" "wp_instance" {
    ami             = "ami-7e257211"
    instance_type   = "t2.micro"
    key_name        = "mykey1122"
    vpc_security_group_ids = [aws_security_group.sg1.id]
    subnet_id = aws_subnet.wp_subnet.id
  tags = {
    Name = "wordpress_instance"
  }
}
resource "aws_instance" "mysql_instance" {
    ami             = "ami-08706cb5f68222d09"
    instance_type   = "t2.micro"
    key_name        = "mykey1122"
    vpc_security_group_ids = [aws_security_group.sg2.id,aws_security_group.sg4.id]
    subnet_id = aws_subnet.mysql_subnet.id
  tags = {
    Name = "mysql_instance"
  }
}

resource "aws_instance" "bastion_os" {
    ami             = "ami-07a8c73a650069cf3"
    instance_type   = "t2.micro"
    key_name        = "mykey1122"
    vpc_security_group_ids = [aws_security_group.sg3.id]
    subnet_id = aws_subnet.wp_subnet.id
  tags = {
    Name = "bastion_instance"
  }
}
resource "aws_eip" "ink" {
  vpc      = true
  depends_on = ["aws_internet_gateway.gateway1"]
}
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${aws_eip.ink.id}"
  subnet_id     = "${aws_subnet.wp_subnet.id}"
  depends_on = ["aws_internet_gateway.gateway1"]

  tags = {
    Name = "gw_NAT"
  }
}
resource "aws_route_table" "routetable2" {
  vpc_id = "${aws_vpc.wpmysqlvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }

 

  tags = {
    Name = "second_routetable"
  }
}
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.mysql_subnet.id
  route_table_id = aws_route_table.routetable2.id
}


