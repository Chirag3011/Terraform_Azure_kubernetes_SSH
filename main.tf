module "ssh" {
  source      = "./modules/ssh"
  for_each    = local.ssh
  rg_location = each.value.rg_location
}

module "aks" {
  source         = "./modules/aks"
  for_each       = local.ak8s
  akssubnet_name = each.value.akssubnet_name
  aksvnet_name   = each.value.aksvnet_name
  rg_location    = each.value.rg_location
  rg_name        = each.value.rg_name
  ssh_key_name   = local.ssh_key_name
  depends_on     = [module.ssh]
}
