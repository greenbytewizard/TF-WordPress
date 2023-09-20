# A resource block declares a resource of a given type ("aws_instance") with a given local name ("Demo"). The name is used to refer to this resource from elsewhere in the same Terraform module.
# Dyanmic variables
locals {
  keyPath = "./'${var.generated_key_name}'.pem"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create key for AWS
resource "aws_key_pair" "kp" {
  key_name   = var.generated_key_name
  public_key = tls_private_key.ssh.public_key_openssh

  # Create "terraform-key-pair.pem" in current directory
  provisioner "local-exec" {
    command = <<EOF
      $privateKey = "${tls_private_key.ssh.private_key_pem}"
      $privateKey | Out-File -FilePath ".\\${var.generated_key_name}.pem" -Encoding utf8
      Set-Content ".\\${var.generated_key_name}.pem" -Value $privateKey -Encoding utf8
      attrib +R ".\\${var.generated_key_name}.pem"
  EOF
  interpreter = ["PowerShell", "-Command"]
  }
}

# > ./'${var.generated_key_name}'.pem: This part of the command uses the output redirection (>) to write the echoed content () into a file on the current directory
# create an instance
resource "aws_instance" "ec2" {
  ami             = var.ami
  subnet_id       = var.subnet
  security_groups = var.security_groups
  key_name        = var.generated_key_name
  instance_type   = var.instance_type
  tags = {
    name = "SkyNet"
  }
}

#  A null_resource is used for running local provisioners and doesn't create any actual infrastructure.
resource "null_resource" "configure-vm" {
  triggers = {
    web_id = aws_instance.ec2.public_ip
  }
  # triggers: The triggers block specifies values that, when changed, cause Terraform to consider the resource to be "tainted" and thus trigger a recreation
  # Login to the ec2-user with the aws key.    
  provisioner "file" {
    content = templatefile("lampstack.sh.tftpl", { 
      PASSWORD_1 = random_password.salt_passwords[0].result, 
      PASSWORD_2 = random_password.salt_passwords[1].result, 
      PASSWORD_3 = random_password.salt_passwords[2].result,
      PASSWORD_4 = random_password.salt_passwords[3].result, 
      PASSWORD_5 = random_password.salt_passwords[4].result, 
      PASSWORD_6 = random_password.salt_passwords[5].result,
      PASSWORD_7 = random_password.salt_passwords[6].result, 
      PASSWORD_8 = random_password.salt_passwords[7].result,
      wordpress_user_pwd = random_password.wordpress_user_pwd.result })
    destination ="/tmp/lampstack.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.ssh.private_key_pem
      host        = aws_instance.ec2.public_ip
    }
  }
  # chmod commands: u refers to the owner of the file. + is used to add permissions. r stands for read permission. 
  # w stands for write permission. x stands for execute permission.
  # Change permissions on bash script and execute from ec2-user.
  # [,] an array of... 
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y dos2unix",
      "sudo chmod +x /tmp/lampstack.sh",
      "sudo bash /tmp/lampstack.sh"
    ]
    # dos2unix - convert text files with DOS or MAC line breaks to Unix line breaks. Needed due to templatefile running on local windows machine.
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.ssh.private_key_pem
      host        = aws_instance.ec2.public_ip
    }
  }
  provisioner "file" {
    source      = templatefile("mysql_script.sql.tftpl", { 
      mysql_root_pwd = random_password.mysql_root_pwd.result, 
      wordpress_user_pwd = random_password.wordpress_user_pwd.result 
      })
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
resource "random_password" "salt_passwords" {
  count            = 8
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}|;:'\",.<>?/`~"
}
# In PowerShell, double-quoted strings (") allow you to embed variables within the string by using $variableName. 
# The backtick (`) character is used as an escape character to insert a newline (n) character, which creates 
# a line break between "Password 1" and "Password 2" in the final output.
# The | symbol is known as the pipe operator in PowerShell. 
# It is used to pass the output (in this case, the value of the $output variable) from one command to another as input.