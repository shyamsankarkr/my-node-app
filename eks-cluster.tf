module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.0"


  cluster_name = "myapp-eks-cluster"  
  cluster_version = "1.30"

  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id = module.myapp-vpc.vpc_id

  tags = {
    environment = "development"
    application = "myapp"
  }

  eks_managed_node_groups = {
    dev = {
      min_size     = 1
      max_size     = 1
      desired_size = 1

      instance_types = ["t2.small"]
    }
  }
}