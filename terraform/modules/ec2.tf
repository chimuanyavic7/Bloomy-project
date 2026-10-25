data "aws_key_pair" "key_pair" {
  key_name = var.key_name
}

resource "aws_instance" "public_ec2" {
  ami  = var.ami_id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public_subnet[0].id
  associate_public_ip_address = true
  key_name = data.aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.sg_public_ec2.id]

  user_data = <<-EOF
   #!/bin/bash

    set -e  # Exit immediately if a command fails

    echo "=== Updating system ==="
    sudo apt update -y

    echo "=== Installing software-properties-common ==="
    sudo apt install -y software-properties-common

    echo "=== Adding official Ansible PPA ==="
    sudo add-apt-repository --yes --update ppa:ansible/ansible

    echo "=== Installing Ansible ==="
    sudo apt install -y ansible

    echo "=== Verifying Ansible installation ==="
    ansible --version

    echo "=== Cloning GitHub Repository ==="
    # Replace these with your actual GitHub repository URL and destination path
    REPO_URL="https://github.com/chimuanyavic7/Bloomy-project.git"
    REPO_DEST="/home/ubuntu/Bloomy-project"

    # Clone the repository as the 'ubuntu' user (prevents permission issues)
    sudo -u ubuntu git clone "$REPO_URL" "$REPO_DEST"

    echo "=== Setup completed successfully ==="
    EOF


  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    delete_on_termination = var.delete_on_termination
    encrypted             = var.encrypted
  }


  tags = {
    Name = "Bastion-Host"
  }
}





resource "aws_security_group" "sg_public_ec2" {
    name        = "ec2-sg"
    description = "Allow SSH, HTTP, HTTPS inbound traffic"
    vpc_id      = aws_vpc.vpc.id
    
    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTPS"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "prometheus"
        from_port   = 9090
        to_port     = 9090
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Grafana"
        from_port   = 3000
        to_port     = 3000
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
        "Name" = "team-c-sg"
        "Env"  = var.env  
    }
}




