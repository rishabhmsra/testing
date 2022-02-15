#resource "aws_key_pair" "personal" {
#  key_name   = "amazon-key1"
#  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCZy6OdZXz3UmNvOfez32RS1NPnWv6IOlNmTbsoBv7kFf/sFOR2E4DabCh89uwdnAFMfnze6SL2S8MWX5FAN5VhAtdE3zPJ/lAm/G93fldBqnVA5hFMYJihA7BKf7M2IrfUUWr/sWEafia72qiaaZJx0O72IJe+KnOQwCHaUPIYTurOCGesbwS7FleP8aHsTOwCjvbYSMFv1Uz5EXocT1rDPebTaoc1P5BnP1MCOSo34CbHa/lK+p6HX8fmo3DeHWRRUt84lK3xY1PJcwuIICgyOR+j3YIUUfglYdCLjQfZwXrupAfk6u45m7Ry6FBBmgoFufXG+Er7ML5EH7HQUyhCg4yZffh9gQshstc1OFvszDuqjFGYqLtsBXnra4JiAyEwsAfZqo+YcFQ+dsB5nCwFq2dOnLvHXu4v6hVkD0Ru6Dtl27kNWQaZcueVkc0SuqNwKCSVPSxKfcyJi8CeAl3J5G8jKZ9WlrzAHkzbcEWDwmlZSPv2CCLN4d+o468n4uU= infracloud@infracloud-ThinkPad-E14"
#}

resource "aws_instance" "ec2-instance" {

  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = "subnet-6127e62d"
  security_groups             = [var.vpc_security_group_id_for_ec2]
  associate_public_ip_address = true
  key_name                    = "amazon-key1"
#  depends_on                  = [aws_key_pair.personal]
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 320
  }
  tags = {
    Name = "${var.name}"
  }
  
 user_data = <<-EOF
    #!/bin/bash
    set -x
    curl https://releases.rancher.com/install-docker/20.10.sh | sh
    sudo chmod 777 /var/run/docker.sock
    #Install Rancher
    docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher:${var.rancher_version}
    sleep 300
    #Saves bootstrap password log line to dockerpassword.txt
    docker logs $(docker ps --format '{{.Names}}') 2>&1 | grep "Bootstrap Password" > dockerpassword.txt
    #Saves bootstrap password log line to BootstrapPassword
    cat dockerpassword.txt | grep -oP '(?<=Bootstrap Password: )[^ ]*' > bootstrappassword
    export TF_VAR_pass=`cat bootstrappassword`
    export AWS_KEY_ID=${var.AWS_KEY_ID}
    export AWS_SECRET_KEY_ID= ${var.AWS_SECRET_KEY_ID}
    export AWS_DEFAULT_OUTPUT= ${var.AWS_DEFAULT_OUTPUT}
    export AWS_REGION= 'us-east-2'
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt install unzip
    unzip awscliv2.zip
    sudo ./aws/install
    aws --version
    aws ec2 describe-instances --region us-east-2 --filters "Name=tag:Name,Values=rishabh-rancher-Server" | grep -i publicipaddress | cut -d ":" -f 2 | cut -c 3-15 > server_url
    cat server_url
  EOF
}
