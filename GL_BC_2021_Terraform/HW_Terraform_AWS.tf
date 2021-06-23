provider "aws" {
  region = "eu-central-1"
}
resource "aws_launch_configuration" "uwebserver" {
    image_id = "ami-05f7491af5eef733a"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]
        user_data = <<-EOF
        #!/bin/bash
        myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
        echo "<h2>WebServer_IP: $myip</h2><br>Made in Ukraine<br>Terraform v1.0.0<br>
        Vladislav Semenenko<br>2021" > index.html
        nohup busybox httpd -f -p 8080 &
        EOF
    lifecycle {
        create_before_destroy = true
    }
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}
data "aws_vpc" "default" {
default = true
}

resource "aws_security_group" "alb" {
    name = "terraform-alb-security-group"
    ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "instance" {
  name = "terraform-instance-security-group"
  ingress {
    from_port	    = 8080
    to_port	        = 8080
    protocol	    = "tcp"
    cidr_blocks	    = ["0.0.0.0/0"]
    }
}

resource "aws_lb" "alb" {
    name = "terraform-alb"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.alb.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "fixed-response"
        fixed_response {
        content_type = "text/plain"
        message_body = "404: 空  Kōng"
        status_code = 404
        }
    }
}

resource "aws_lb_listener_rule" "asg-listener_rule" {
    listener_arn    = aws_lb_listener.http.arn
    priority        = 100
    condition {
      path_pattern {
        values = ["*"]
      }
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg-target-group.arn
    }
}

resource "aws_lb_target_group" "asg-target-group" {
    name = "terraform-aws-lb-target-group"
    port = 8080
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 3
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }
}

resource "aws_autoscaling_group" "uwebserver" {
    launch_configuration = aws_launch_configuration.uwebserver.name
    vpc_zone_identifier = data.aws_subnet_ids.default.ids
    target_group_arns = [aws_lb_target_group.asg-target-group.arn]
    health_check_type = "ELB"      
    min_size = 2
    max_size = 2    
    tag {
    key = "Name"
    value = "terraform-asg-uwebserver"
    propagate_at_launch = true
    }
}

output "alb_target_group_arn" {
  value = "${aws_lb_target_group.asg-target-group.arn}"
}
output "alb_dns_name" {
    value = aws_lb.alb.dns_name
}