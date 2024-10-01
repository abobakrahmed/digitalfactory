# main.tf
module "network" {
  source = "./network"
}

module "compute" {
  source = "./compute"
}

module "database" {
  source = "./database"
}

module "monitoring" {
  source = "./monitoring"
}

module "scaling" {
  source = "./scaling"
}

module "security" {
  source = "./security"
}
