output "instance_ip_addr" {
  value       = aws_instance.ec2
  description = "The public IP address of the main server instance."
}
