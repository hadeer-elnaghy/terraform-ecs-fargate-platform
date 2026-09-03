module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  environment          = var.environment
}

module "alb" {
  source            = "./modules/alb"
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  container_port    = 80
}

module "ecs" {
  source             = "./modules/ecs"
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ecs_tasks_sg_id    = module.alb.ecs_tasks_sg_id
  target_group_arn   = module.alb.target_group_arn
  container_port     = 80
}
