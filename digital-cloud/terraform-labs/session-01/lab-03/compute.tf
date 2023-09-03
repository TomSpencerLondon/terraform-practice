resource "aws_network_interface" "nic" {
  subnet_id   = aws_subnet.public.id

  tags = {
    Name = "${var.instance_name}-nic"
  }
}

data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "ec2" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = var.instance_size

  network_interface {
    network_interface_id = aws_network_interface.nic.id
    device_index         = 0
  }

  tags = {
    Name    = var.instance_name
    Session = "01"
    Lab     = "03"
  }
}