provider "azurerm" {
  features {}

   subscription_id = var.subscription_id

}

provider azuread  {
   
    }
    

data "azuread_user" "users" {
    for_each = toset(var.user_principal_names)
  user_principal_name = each.value
}

# Resource Group
resource "azurerm_resource_group" "avd_rg" {
  name = "rg-${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}"
  location = var.location
}

resource "azurerm_role_assignment" "avd_vm_user_login" {
  for_each =  data.azuread_user.users 
  scope                =  azurerm_resource_group.avd_rg.id
  role_definition_name = "Virtual Machine User Login"  ##Ideally we want to place this role on a VM basis. Needs 
  principal_id         = each.value.object_id
}


# Azure Virtual Desktop Host Pool
resource "azurerm_virtual_desktop_host_pool" "avd_host_pool" {
  name                = "hp-${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

  type                = var.host_pool_type # or "Personal" for personal desktops
  load_balancer_type  = var.load_balancer_type # or "DepthFirst" for load balancing
  preferred_app_group_type = var.preferred_app_group_type # or "RailApplications" for RemoteApp

  custom_rdp_properties    = var.custom_rdp_properties
  # Optional: Set validation environment
  validate_environment = var.validate_environment
 

}

# Azure Virtual Desktop Application Group
resource "azurerm_virtual_desktop_application_group" "avd_app_group" {
  name                = "appG-${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  type                = var.preferred_app_group_type # or "RemoteApp" for RemoteApp groups

  host_pool_id        = azurerm_virtual_desktop_host_pool.avd_host_pool.id
}

resource "azurerm_role_assignment" "avd_app_group_user_access" {
  for_each =  data.azuread_user.users 
  scope                =  azurerm_virtual_desktop_application_group.avd_app_group.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = each.value.object_id
}


# Azure Virtual Desktop Workspace
resource "azurerm_virtual_desktop_workspace" "avd_workspace" {
  name                = "WS-${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

  friendly_name = var.workspace_friendly_name
  description   = var.workspace_description
}

# Associate Application Group with Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "avd_association" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd_workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.avd_app_group.id
}

# Azure Virtual Machine for AVD Session Host
resource "azurerm_windows_virtual_machine" "avd_vm" {
  count                      = var.rdsh_count
  name                = "vm-${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}${count.index + 1}"
  resource_group_name = azurerm_resource_group.avd_rg.name
  location            = azurerm_resource_group.avd_rg.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

   network_interface_ids = ["${azurerm_network_interface.avd_nic.*.id[count.index]}"]

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }
 identity {
    type = "SystemAssigned"
  }
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku 
    version   = var.image_version
  }
}



# Network Interface for AVD VM
resource "azurerm_network_interface" "avd_nic" {
  count                      = var.rdsh_count
  name                = "vm-${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}-${count.index + 1}-nic"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.avd_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Network and Subnet
resource "azurerm_virtual_network" "avd_vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
}

resource "azurerm_subnet" "avd_subnet" {
  name                 = "${var.vnet_name}-default"
  resource_group_name  = azurerm_resource_group.avd_rg.name
  virtual_network_name = azurerm_virtual_network.avd_vnet.name
  address_prefixes     = var.subnet_address_prefixes
}

# Join VM to Microsoft Entra ID (Azure AD)
resource "azurerm_virtual_machine_extension" "aad_join" {
  count                = var.rdsh_count
  name                 = "${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}-${count.index + 1}-AADJoin"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = var.aad_join_extension_version
  
  


}

# Add the VM to the existing AVD host pool
resource "azurerm_virtual_desktop_host_pool_registration_info" "avd_registration" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd_host_pool.id
  expiration_date = timeadd(timestamp(), "720h") # Token expires in 30 days
  

  depends_on = [azurerm_windows_virtual_machine.avd_vm]
}

resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  count                      = var.rdsh_count
  name                       = "${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}-${count.index + 1}-avd_dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = var.dsc_extension_version
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "${var.dsc_modules_url}",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${azurerm_virtual_desktop_host_pool_registration_info.avd_registration.token}"
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.avd_registration.token}"
    }
  }
PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.aad_join
    
  ]
}


# Outputs
output "host_pool_id" {
  value = azurerm_virtual_desktop_host_pool.avd_host_pool.id
}

output "workspace_id" {
  value = azurerm_virtual_desktop_workspace.avd_workspace.id
}