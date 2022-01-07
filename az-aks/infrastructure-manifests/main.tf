provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "data" {
  name     = "${var.prefix}-data-rg"
  location = var.location
  tags = {
    environment = var.env
    source      = "AzureDevCollege"
  }
}
resource "azurerm_resource_group" "aks" {
  name     = "${var.prefix}-aks-rg"
  location = var.location
  tags = {
    environment = var.env
    source      = "AzureDevCollege"
  }
}

resource "azurerm_resource_group" "common" {
  name     = "${var.prefix}-common-rg"
  location = var.location
  tags = {
    environment = var.env
    source      = "AzureDevCollege"
  }
}

module "common" {
  source              = "./common"
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name
  env                 = var.env
  prefix              = var.prefix
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

#SQL DB
module "data" {
  source              = "./data"
  location            = azurerm_resource_group.data.location
  resource_group_name = azurerm_resource_group.data.name
  env                 = var.env
  prefix              = var.prefix
  sqldbusername       = var.sqldbusername
  sqldbpassword       = "changeme@123!" #random_password.password.result
  sqldbname           = var.sqldbname
}

# AKS
module "network" {
  source              = "./network"
  prefix              = var.prefix
  env                 = var.env
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = "10.0.0.0/8"      #"10.0.0.0/16"
  subnet_prefixes     = ["10.240.0.0/16"] #["10.0.1.0/24"]
  subnet_names        = ["aks-subnet"]
  location            = azurerm_resource_group.aks.location
  depends_on          = [azurerm_resource_group.aks]
}

module "acr" {
  source              = "./acr"
  prefix              = var.prefix
  env                 = var.env
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  depends_on          = [azurerm_resource_group.aks]
}

data "azuread_group" "aks_cluster_admins" {
  display_name = "AKS-cluster-admins" 
}

module "aks" {
  source                           = "./aks"
  resource_group_name              = azurerm_resource_group.aks.name
  client_id                        = ""#data.azurerm_client_config.current.client_id
  client_secret                    = ""#var.client_secret
  kubernetes_version               = "1.20.9"
  orchestrator_version             = "1.20.9"
  prefix                           = var.prefix
  env                              = var.env
  location                         = azurerm_resource_group.aks.location
  network_plugin                   = "azure" # "kubenet"
  vnet_subnet_id                   = module.network.vnet_subnets[0]
  os_disk_size_gb                  = 128
  sku_tier                         = "Paid" # defaults to Free
  enable_role_based_access_control = true
  rbac_aad_admin_group_object_ids  = [data.azuread_group.aks_cluster_admins.id]
  rbac_aad_managed                 = true
  private_cluster_enabled          = false #true # default value
  enable_http_application_routing  = false #true
  enable_azure_policy              = true
  enable_auto_scaling              = true
  enable_host_encryption           = false #true
  agents_min_count                 = 1
  agents_max_count                 = 2
  agents_count                     = null # Please set `agents_count` `null` while `enable_auto_scaling` is `true` to avoid possible `agents_count` changes.
  agents_max_pods                  = 100
  agents_pool_name                 = "exnodepool"
  agents_availability_zones        = ["1", "2"]
  agents_type                      = "VirtualMachineScaleSets"

  agents_labels = {
    "nodepool" : "defaultnodepool"
  }

  agents_tags = {
    "Agent" : "defaultnodepoolagent"
  }

  network_policy                 = "azure"
  net_profile_dns_service_ip     = "10.0.0.10"
  net_profile_docker_bridge_cidr = "170.10.0.1/16"
  net_profile_service_cidr       = "10.0.0.0/16"

  depends_on = [module.network]
}

data "azuread_service_principal" "aks_principal" {
  application_id = data.azurerm_client_config.current.client_id
}
resource "azurerm_role_assignment" "role_acrpull" {
  #depends_on                       = [module.aks]
  scope                            = module.acr.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity.0.object_id #data.azuread_service_principal.aks_principal.object_id #module.aks.system_assigned_identity #
  skip_service_principal_aad_check = true
}

# Save Secrets to Key Vault

resource "azurerm_key_vault_secret" "sqldb_connectionstring" {
  name         = "SQLDBCONNECTIONSTRING"
  value        = module.data.sqldb_connectionstring
  key_vault_id = module.common.keyvaultid
}
resource "azurerm_key_vault_secret" "sqldb_username" {
  name         = "SQLUSER"
  value        = module.data.sqldb_username
  key_vault_id = module.common.keyvaultid
}
resource "azurerm_key_vault_secret" "sqldb_pwd" {
  name         = "SQLPASSWORD"
  value        = module.data.sqldb_pwd
  key_vault_id = module.common.keyvaultid
}
resource "azurerm_key_vault_secret" "sqldb_server" {
  name         = "SQLSERVER"
  value        = module.data.sqldb_server
  key_vault_id = module.common.keyvaultid
}
resource "azurerm_key_vault_secret" "sqldb_name" {
  name         = "${var.prefix}SQLDBNAME"
  value        = module.data.sqldb_name
  key_vault_id = module.common.keyvaultid
}

# Data

output "sqldb_connectionstring_base64" {
  value     = base64encode(module.data.sqldb_connectionstring)
  sensitive = true
}
output "sqldb_connectionstring" {
  value     = random_password.password.result
  sensitive = true
}