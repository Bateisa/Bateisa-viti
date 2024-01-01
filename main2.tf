provider "aws" {
  region = "us-east-1"  # Replace with your desired AWS region
}

# Use the existing VPC
data "aws_vpcs" "existing_vpcs" {
  ids = ["vpc-0290179c45627d575"]  # Replace with your VPC ID
}

# Use an existing subnet in the VPC
data "aws_subnet" "existing_subnet" {
  id = "subnet-0e4125aa99c261423"  # Replace with your subnet ID
}

# EC2 Security Group
resource "aws_security_group" "ec2_sg" {
  vpc_id = data.aws_vpcs.existing_vpcs.ids[0]
  # Ingress rule allowing SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  vpc_id       = data.aws_vpcs.existing_vpcs.ids[0]
  name_prefix  = "wordpress-db-"
  # Ingress rule allowing connections only from EC2 Security Group
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
}

# Define an RDS instance
resource "aws_db_instance" "wordpressdb" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  username             = var.database_user
  password             = var.database_password
  identifier           = var.database_name
  publicly_accessible = false
  storage_type         = "gp2"
  multi_az             = false
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# Define an EC2 instance
resource "aws_instance" "example_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Latest Amazon 2 Linux AMI
  instance_type = "t2.micro"  # Modify instance type as needed

  subnet_id              = data.aws_subnet.existing_subnet.id
  associate_public_ip_address = true
  key_name               = "InternshipKeys"  # Replace with your key pair name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "example-instance"
  }
}

# Output the public IP of the instance
output "instance_public_ip" {
  value = aws_instance.example_instance.public_ip
}
// -----------------------------------------------
// Change USERDATA varible value after grabbing RDS endpoint info
// -----------------------------------------------
data "template_file" "user_data" {
  template = file("userdata.sh")
  vars = {
    db_username      = var.database_user
    db_user_password = var.database_password
    db_name          = var.database_name
    db_RDS           = aws_db_instance.wordpressdb.endpoint
  }
}