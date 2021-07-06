provider "aws" {
	region = "eu-central-1"
}

variable "aws_zone1" {
    description = "high security amazone 1a"
    default = "eu-central-1a"
}

variable "aws_zone2" {
    description = "high security amazone 1b"
    default = "eu-central-1b"
}

variable "aws_ami" {
    default = "ami-089b5384aac360007"
}
