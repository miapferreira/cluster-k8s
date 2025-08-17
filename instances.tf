# Control Plane Instance
resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.control_plane_instance_type
  key_name               = aws_key_pair.k8s_key.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.control_plane.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true

    tags = {
      Name        = "${var.cluster_name}-control-plane-root"
      Environment = var.environment
      Project     = "kubernetes-cluster"
    }
  }

  user_data = base64encode(templatefile("${path.module}/scripts/control_plane_setup.sh", {
    cluster_name = var.cluster_name
  }))

  tags = {
    Name        = "${var.cluster_name}-control-plane"
    Environment = var.environment
    Project     = "kubernetes-cluster"
    Role        = "control-plane"
  }

  depends_on = [aws_internet_gateway.main]
}

# Worker Nodes Instances
resource "aws_instance" "workers" {
  count                  = 3
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  key_name               = aws_key_pair.k8s_key.key_name
  subnet_id              = aws_subnet.private[count.index].id
  vpc_security_group_ids = [aws_security_group.workers.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true

    tags = {
      Name        = "${var.cluster_name}-worker-${count.index + 1}-root"
      Environment = var.environment
      Project     = "kubernetes-cluster"
    }
  }

  user_data = base64encode(templatefile("${path.module}/scripts/worker_setup.sh", {
    cluster_name = var.cluster_name
    worker_id    = count.index + 1
  }))

  tags = {
    Name        = "${var.cluster_name}-worker-${count.index + 1}"
    Environment = var.environment
    Project     = "kubernetes-cluster"
    Role        = "worker"
  }

  depends_on = [aws_nat_gateway.main]
}
