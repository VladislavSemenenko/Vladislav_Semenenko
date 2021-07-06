resource "aws_subnet" "webhubsub1" {
    vpc_id                  = "${aws_vpc.webhubvpc.id}"
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "${var.aws_zone1}"
    map_public_ip_on_launch = true
    tags = {
        Name = "Webhub-SubNet1"
    }
}

resource "aws_subnet" "webhubsub2" {
    vpc_id                  = "${aws_vpc.webhubvpc.id}"
    cidr_block              = "10.0.2.0/24"
    availability_zone       = "${var.aws_zone2}"
    map_public_ip_on_launch = true
    tags = {
        Name = "Webhub-SubNet2"
    }
}

resource "aws_instance" "vm1" {
	ami                    = var.aws_ami
	instance_type          = "t2.micro"
    availability_zone      = "${var.aws_zone1}"
    subnet_id              = "${aws_subnet.webhubsub1.id}"
    vpc_security_group_ids = ["${aws_security_group.vm_sg.id}"]
    user_data              = "${file("userdata.sh")}"
	tags = {
		Name = "VM1"
	}
}

resource "aws_instance" "vm2" {
	ami                    = var.aws_ami
	instance_type          = "t2.micro"
    availability_zone      = "${var.aws_zone2}"
    subnet_id              = "${aws_subnet.webhubsub2.id}"
    vpc_security_group_ids = ["${aws_security_group.vm_sg.id}"]
    user_data              = "${file("userdata.sh")}"
	tags = {
		Name = "VM2"
	}
}

resource "aws_route_table_association" "route-tbl1" {
    subnet_id      = "${aws_subnet.webhubsub1.id}"
    route_table_id = "${aws_route_table.main-public-rt.id}"
}

resource "aws_route_table_association" "route-tbl2" {
    subnet_id      = "${aws_subnet.webhubsub2.id}"
    route_table_id = "${aws_route_table.main-public-rt.id}"
}

resource "aws_vpc" "webhubvpc" {
    cidr_block            = "10.0.0.0/16"
    instance_tenancy      = "default"
    enable_dns_support    = true
    enable_dns_hostnames  = true
    tags = {
        Name = "WebhubVPC"
    }
}

resource "aws_security_group" "lb-sg" {
    name          = "webhub-lb-sg"
    description   = "Application load balancer security group"
    vpc_id        = "${aws_vpc.webhubvpc.id}"

    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb" "webhublb" {
    name               = "webhub-lb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = ["${aws_security_group.lb-sg.id}"]
    subnets            = ["${aws_subnet.webhubsub1.id}","${aws_subnet.webhubsub2.id}"]
}

resource "aws_alb_target_group" "lb-tg" {
    name      = "webhub-lb-tg"
    port      = 80
    protocol  = "HTTP"
    vpc_id    = "${aws_vpc.webhubvpc.id}"
    tags = {
        Name  = "Webhub-tg"
    }
}

resource "aws_alb_listener" "lb-listener" {
    load_balancer_arn    = "${aws_lb.webhublb.arn}"
    port                 = "80"
    protocol             = "HTTP"
    default_action {
      target_group_arn = "${aws_alb_target_group.lb-tg.arn}"
      type             = "forward"
  }
}

resource "aws_security_group" "vm_sg" {
    name        = "allow_http"
    vpc_id      = "${aws_vpc.webhubvpc.id}"
    ingress {
      from_port = 80
      to_port   = 80
      protocol  = "TCP"
      security_groups = ["${aws_security_group.lb-sg.id}"]
    }
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_alb_target_group_attachment" "alb_vm1" {
    target_group_arn = "${aws_alb_target_group.lb-tg.arn}"
    target_id        = "${aws_instance.vm1.id}"
    port             = 80
}

resource "aws_alb_target_group_attachment" "alb_vm2" {
    target_group_arn = "${aws_alb_target_group.lb-tg.arn}"
    target_id        = "${aws_instance.vm2.id}"
    port             = 80
}

resource "aws_internet_gateway" "igw" {
    vpc_id   = "${aws_vpc.webhubvpc.id}"    
    tags = {
        Name = "Webhub-IGW"
    }
}

resource "aws_route_table" "main-public-rt" {
    vpc_id         = "${aws_vpc.webhubvpc.id}"
    route {
        cidr_block ="0.0.0.0/0"
        gateway_id ="${aws_internet_gateway.igw.id}"
    }
    tags = {
        Name = "Webhub-public-rt"
    }
}
