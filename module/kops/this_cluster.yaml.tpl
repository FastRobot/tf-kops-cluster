apiVersion: kops/v1alpha2
kind: Cluster
metadata:
  creationTimestamp: 2018-04-17T21:21:12Z
  name: ${cluster_fqdn}
spec:
  api:
    loadBalancer:
      type: Public
  authorization:
    rbac: {}
  channel: stable
  cloudProvider: aws
  configBase: s3://${kops_bucket}/${cluster_fqdn}
  docker:
    logDriver: awslogs
    logOpt:
    - awslogs-region=${aws_region}
    - awslogs-group=${cluster_name}
  etcdClusters:
  - etcdMembers:
    - instanceGroup: master-${aws_region}a
      name: a
    - instanceGroup: master-${aws_region}b
      name: b
    - instanceGroup: master-${aws_region}c
      name: c
    name: main
  - etcdMembers:
    - instanceGroup: master-${aws_region}a
      name: a
    - instanceGroup: master-${aws_region}b
      name: b
    - instanceGroup: master-${aws_region}c
      name: c
    name: events
  iam:
    allowContainerRegistry: true
    legacy: false
  kubernetesApiAccess:
  - 0.0.0.0/0
  kubernetesVersion: ${k8s_version}
  masterPublicName: ${cluster_fqdn}
  networkCIDR: ${networkCIDR}
  networkID: ${networkID}
  networking:
    ${k8s_networking}: {}
  nonMasqueradeCIDR: 100.64.0.0/10
  sshAccess:
  - 0.0.0.0/0
  subnets:
  - cidr: ${network_a}
    name: ${aws_region}a
    type: Public
    zone: ${aws_region}a
  - cidr: ${network_b}
    name: ${aws_region}b
    type: Public
    zone: ${aws_region}b
  - cidr: ${network_c}
    name: ${aws_region}c
    type: Public
    zone: ${aws_region}c
  topology:
    dns:
      type: Private
    masters: public
    nodes: public
