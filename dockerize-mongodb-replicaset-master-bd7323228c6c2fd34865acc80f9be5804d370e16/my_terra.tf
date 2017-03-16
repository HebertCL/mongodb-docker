resource "aws_vpc" "hebert_vpc" {
    cidr_block = "10.0.0.0/16"

	tags {

	Name = "Hebert VPC"
	}
}

resource "aws_internet_gateway" "hebert_gateway" {
    vpc_id = "${aws_vpc.hebert_vpc.id}"

    tags {
        Name = "Hebert Gateway"
    }
}

resource "aws_subnet" "public_sub1" {
    vpc_id = "${aws_vpc.hebert_vpc.id}"
    cidr_block = "10.0.2.0/24"

    tags {
        Name = "Public Subnet 1"
    }
}

 resource "aws_subnet" "public_sub2" {
    vpc_id = "${aws_vpc.hebert_vpc.id}"
    cidr_block = "10.0.3.0/24"

    tags {
        Name = "Public Subnet 2"
    }
}

resource "aws_subnet" "private_sub1" {
    vpc_id = "${aws_vpc.hebert_vpc.id}"
    cidr_block = "10.0.0.0/24"

    tags {
        Name = "Private Subnet 1"
    }
}

resource "aws_subnet" "private_sub2" {
    vpc_id = "${aws_vpc.hebert_vpc.id}"
    cidr_block = "10.0.1.0/24"

    tags {
        Name = "Private Subnet 2"
    }
}

resource "aws_route_table" "private_table" {
    vpc_id = "${aws_vpc.hebert_vpc.id}"
    route {
        cidr_block = "0.0.0.0/16"
        gateway_id = "${aws_internet_gateway.hebert_gateway.id}"
    }

    tags {
        Name = "Private Routing Table"
    }
}

resource "aws_route_table" "public_table" {
    vpc_id = "${aws_vpc.hebert_vpc.id}"
    route {
        cidr_block = "0.0.0.0/16"
        gateway_id = "${aws_internet_gateway.hebert_gateway.id}"
    }

    tags {
        Name = "Public Routing Table"
    }
}

resource "aws_route_table_association" "private_1" {
    subnet_id = "${aws_subnet.private_sub1.id}"
    route_table_id = "${aws_route_table.private_table.id}"
}

resource "aws_route_table_association" "private_2" {
    subnet_id = "${aws_subnet.private_sub2.id}"
    route_table_id = "${aws_route_table.private_table.id}"
}

resource "aws_route_table_association" "public_1" {
    subnet_id = "${aws_subnet.public_sub1.id}"
    route_table_id = "${aws_route_table.public_table.id}"
}

resource "aws_route_table_association" "public_2" {
    subnet_id = "${aws_subnet.public_sub2.id}"
    route_table_id = "${aws_route_table.public_table.id}"
}
/*
resource "aws_network_interface" "hebert_eip_pub1" {
  subnet_id   = "${aws_subnet.public_sub1.id}"
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = "${aws_network_interface.hebert_eip_pub1.id}"
}

resource "aws_network_interface" "hebert_eip_pub2" {
  subnet_id   = "${aws_subnet.public_sub2.id}"
}

resource "aws_eip" "two" {
  vpc                       = true
  network_interface         = "${aws_network_interface.hebert_eip_pub2.id}"
}

resource "aws_nat_gateway" "hebert_nat" {
    allocation_id = "${aws_eip.two.id}"
    subnet_id = "${aws_subnet.public_sub2.id}"
}
*/
resource "aws_security_group" "allow_all" {
  name = "allow_all"
  description = "Allow all inbound traffic"

  ingress {
      from_port = 0
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_all"
  }
}

resource "aws_s3_bucket" "hebucket" {
    bucket = "hebert_test_bucket"
    acl = "private"

    tags {
        Name = "Hebert bucket"
        Environment = "Test"
    }
}

resource "aws_elb" "hebert_elb" {
  name = "hebert-terraform-elb"
  availability_zones = ["us-east-1a", "us-east-1b"]


  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "hebert-terraform-elb"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_configuration" "hebert_conf" {
    name_prefix = "hebert_terraform_test"
    image_id = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
    security_groups = ["${aws_security_group.allow_all.id}"]
    user_data = "sudo apt install apache2; sudo echo $hostname > /var/www/html/index.html; sudo /etc/init.d/apache2 restart "
    root_block_device {
      volume_size = "10"
      volume_type = "standard"
      delete_on_termination = true
    }

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "hebert_autosc" {
    	availability_zones = ["us-east-1a", "us-east-1b"]
	name = "hebert_terraform"
    	max_size = 4
  	min_size = 2
  	health_check_grace_period = 300
  	health_check_type = "ELB"
  	desired_capacity = 4
  	force_delete = true
	launch_configuration = "${aws_launch_configuration.hebert_conf.name}"

    	lifecycle {
      		create_before_destroy = true
   	}	
}


