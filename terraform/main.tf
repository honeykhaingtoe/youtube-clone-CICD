# Create a new key pair
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-keypair"  # Name of the key pair in AWS
  public_key = file("~/.ssh/id_rsa.pub")  # Path to your public key
}

resource "aws_instance" "web" {
  ami                    = "ami-06c4be2792f419b7b"  # Change AMI ID for different region
  instance_type          = "t2.large"
  key_name               = aws_key_pair.jenkins_key.key_name  # Reference the created key pair
  vpc_security_group_ids = [aws_security_group.Jenkins-VM-SG.id]
  # subnet_id            = "subnet-0279333d80ef56ff8"  # Uncomment if needed
  user_data              = templatefile("./install.sh", {})

  tags = {
    Name = "Jenkins-SonarQube"
  }

  root_block_device {
    volume_size = 40
  }
}

resource "aws_security_group" "Jenkins-VM-SG" {
  name        = "Jenkins-VM-SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-0d5b095006ca56d4f"  # Change VPC ID

  ingress = [
    for port in [22, 80, 443, 8080, 9000, 3000] : {
      description      = "inbound rules"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins-VM-SG"
  }
}