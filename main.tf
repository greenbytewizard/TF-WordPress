# A resource block declares a resource of a given type ("aws_instance") with a given local name ("Demo"). The name is used to refer to this resource from elsewhere in the same Terraform module.
# Dyanmic variables
locals {
  keyPath = "./'${var.generated_key_name}'.pem"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
# Create key for AWS
resource "aws_key_pair" "kp" {
  key_name   = var.generated_key_name
  public_key = tls_private_key.ssh.public_key_openssh

  # Create "terraform-key-pair.pem" in current directory
provisioner "local-exec" {
  command = <<EOF
      echo '${tls_private_key.ssh.private_key_pem}' > ./'${var.generated_key_name}'.pem
      chmod 400 ./'${var.generated_key_name}'.pem
  EOF
  }
}

# > ./'${var.generated_key_name}'.pem: This part of the command uses the output redirection (>) to write the echoed content () into a file on the current directory
# create an instance
resource "aws_instance" "ec2" {
  ami             = var.ami
  subnet_id       =var.subnet
  security_groups = var.security_groups
  key_name        = var.generated_key_name
  instance_type   = var.instance_type
}

 #  A null_resource is used for running local provisioners and doesn't create any actual infrastructure.
resource "null_resource" "configure-vm" {
    triggers = {
    web_id     = aws_instance.ec2.public_ip
  }
  # triggers: The triggers block specifies values that, when changed, cause Terraform to consider the resource to be "tainted" and thus trigger a recreation
  # Login to the ec2-user with the aws key.    
  provisioner "file" {
    source      = templatefile("lampstack.sh.tftpl", {mysql_pwd = random_password.mysql_pwd.result})
    destination = "/tmp/lampstack.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.ssh.private_key_pem
      host        = aws_instance.ec2.public_ip
    }
  }

  # Change permissions on bash script and execute from ec2-user.
  # [,] an array of... 
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/lampstack.sh && sudo /tmp/lampstack.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.ssh.private_key_pem
      host        = aws_instance.ec2.public_ip
    }
  }
provisioner "file" {
    source      = templatefile("mysql_script.sql.tftpl", {mysql_root_pwd = random_password.mysql_root_pwd.result, wordpress_user_pwd = random_password.wordpress_user_pwd.result})
    destination = "/tmp/mysql_scipt.sql"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.ssh.private_key_pem
      host        = aws_instance.ec2.public_ip
    }
  }
}
resource "random_password" "mysql_root_pwd" {  
  length = 16
}

resource "random_password" "wordpress_user_pwd" {
  length = 16
}

resource "random_password" "mysql_pwd" {
  length = 16
}