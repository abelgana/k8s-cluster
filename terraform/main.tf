provider "aws" {
  region                  = var.region
  shared_credentials_file = "/Users/alex.fernandes/.aws/credentials"
  profile                 = "default"
}

resource "aws_key_pair" "main" {
  key_name   = "alexf"
  public_key = file(var.ssh_public_key_file)
}

resource "aws_instance" "master" {
  ami             = data.aws_ami.ubuntu_1910.id
  instance_type   = var.master_instance_type
  subnet_id       = aws_subnet.main.id
  security_groups = [aws_security_group.main.id]
  key_name        = aws_key_pair.main.key_name

  root_block_device {
    volume_size = 13
  }

  tags = {
    Name    = "${var.name} Master"
    Creator = "alex.fernandes"
  }

  volume_tags = {
    Name    = "${var.name} Master"
    Creator = "alex.fernandes"
  }
}

resource "aws_instance" "worker" {
  count           = var.workers_count
  ami             = data.aws_ami.ubuntu_1910.id
  instance_type   = var.worker_instance_type
  subnet_id       = aws_subnet.main.id
  security_groups = [aws_security_group.main.id]
  key_name        = aws_key_pair.main.key_name

  root_block_device {
    volume_size = 13
  }

  tags = {
    Name    = "${var.name} Worker ${format("%02v", count.index)}"
    Creator = "alex.fernandes"
  }

  volume_tags = {
    Name    = "${var.name} Worker ${format("%02v", count.index)}"
    Creator = "alex.fernandes"
  }
}

resource "aws_instance" "proxy" {
  ami             = data.aws_ami.ubuntu_1910_arm.id
  instance_type   = "a1.medium"
  subnet_id       = aws_subnet.main.id
  security_groups = [aws_security_group.proxy.id]
  key_name        = aws_key_pair.main.key_name

  root_block_device {
    volume_size = 13
  }

  tags = {
    Name    = "${var.name} proxy"
    Creator = "alex.fernandes"
  }

  volume_tags = {
    Name    = "${var.name} proxy"
    Creator = "alex.fernandes"
  }
}

resource "aws_efs_file_system" "main" {
  tags = {
    Name = "K8s Persistent Volume"
  }
}

resource "aws_efs_mount_target" "main" {
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.main.id
  security_groups = [aws_security_group.main.id]
}

output "nfs" {
  value = aws_efs_file_system.main.dns_name
}
