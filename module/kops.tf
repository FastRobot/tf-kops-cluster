resource "null_resource" "check_kops_version" {
  provisioner "local-exec" {
    command = "kops version | grep -q ${local.supported_kops_version} || echo 'Unsupported kops version. Version ${local.supported_kops_version} must be used'"
  }
}

resource "local_file" "this_cluster_yaml" {
  content = "${data.template_file.this_cluster_yaml.rendered}"
  filename = "this_cluster.yaml"
}

data "template_file" "this_cluster_yaml" {
  template = "${file("${path.module}/kops/this_cluster.yaml.tpl")}"
  vars {
    kops_bucket = "${var.kops_s3_bucket_id}"
    cluster_name = "${var.cluster_name}"
    cluster_fqdn = "${local.cluster_fqdn}"
    networkID = "${var.vpc_id}"
    networkCIDR = "${var.cidr}"
    aws_region = "${data.aws_region.current.name}"
    k8s_version = "${var.kubernetes_version}"
    k8s_networking = "${var.kubernetes_networking}"
    network_a = "${var.public_subnet_cidr_blocks[0]}"
    network_b = "${var.public_subnet_cidr_blocks[1]}"
    network_c = "${var.public_subnet_cidr_blocks[2]}"

  }
}

resource "null_resource" "create_cluster" {
  depends_on = [
    "null_resource.check_kops_version",
    "local_file.this_cluster_yaml",
    "aws_subnet.public"
  ]

  provisioner "local-exec" {
    command = "kops create cluster --cloud=aws --dns ${var.kops_dns_mode} --authorization RBAC --networking ${var.kubernetes_networking} --zones=${join(",", data.aws_availability_zones.available.names)} --node-count=${var.node_asg_desired} --master-zones=${local.master_azs} --target=terraform --api-loadbalancer-type=public --vpc=${var.vpc_id} --state=s3://${var.kops_s3_bucket_id} --kubernetes-version ${var.kubernetes_version} --ssh-public-key ${var.ssh_public_key_path} ${local.cluster_fqdn}"
  }

  provisioner "local-exec" {
    command = "kops replace -f this_cluster.yaml --state=s3://${var.kops_s3_bucket_id}"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kops delete cluster --yes --state=s3://${var.kops_s3_bucket_id} --unregister ${local.cluster_fqdn}"
  }
}

resource "null_resource" "delete_tf_files" {
  depends_on = ["null_resource.create_cluster"]

  provisioner "local-exec" {
    command = "rm -rf out"
  }
}
