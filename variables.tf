variable "generated_key_name" {
  type        = string
  default     = "terraform-key-pair"
  description = "Key-pair generated by Terraform"
}
variable "region" {
  type = string
  default = "us-east-1"
}
variable "availabilityZone" {
  type = string
  default = "us-east-1a"
}
variable "instance_type" {
  type = string
  default = "t2.micro"
}
variable "subnet" {
  type = string
  default = "subnet-0c6ec6381e6efac8d"
}
variable "security_groups" {
  type    = list(any)
  default = ["sg-05f12184bac5827d2"]
}
variable "instance_name" {
  type = string
  default = "SkyNet"
}
variable "ami" {
  type = string
  default = "ami-08a52ddb321b32a8c"
}