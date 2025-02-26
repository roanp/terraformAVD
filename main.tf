provider "azurerm" {
  features {}

   subscription_id = "5d4206f2-8af2-479a-b7f9-5fb434457d5f"

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

# Azure Virtual Desktop Host Pool
resource "azurerm_virtual_desktop_host_pool" "avd_host_pool" {
  name                = "hp-${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

  type                = "Pooled" # or "Personal" for personal desktops
  load_balancer_type  = "BreadthFirst" # or "DepthFirst" for load balancing
  preferred_app_group_type = "Desktop" # or "RailApplications" for RemoteApp

  # Optional: Set validation environment
  validate_environment = false
}

# Azure Virtual Desktop Application Group
resource "azurerm_virtual_desktop_application_group" "avd_app_group" {
  name                = "appG-${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  type                = "Desktop" # or "RemoteApp" for RemoteApp groups

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

  friendly_name = "AVD Workspace"
  description   = "Workspace for Azure Virtual Desktop"
}

# Associate Application Group with Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "avd_association" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd_workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.avd_app_group.id
}

# Azure Virtual Machine for AVD Session Host
resource "azurerm_windows_virtual_machine" "avd_vm" {
  name                = "vm-${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}"
  resource_group_name = azurerm_resource_group.avd_rg.name
  location            = azurerm_resource_group.avd_rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!" # Use a secure password or Key Vault

  network_interface_ids = [azurerm_network_interface.avd_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-evd" # Windows 10 Enterprise Multi-Session
    version   = "latest"
  }
}

# Network Interface for AVD VM
resource "azurerm_network_interface" "avd_nic" {
  name                = "vm-${lower(var.location_abv)}-${lower(var.application)}-${lower(var.enviroment)}-nic"
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
  name                = "avd-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
}

resource "azurerm_subnet" "avd_subnet" {
  name                 = "avd-subnet"
  resource_group_name  = azurerm_resource_group.avd_rg.name
  virtual_network_name = azurerm_virtual_network.avd_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Join VM to Microsoft Entra ID (Azure AD)
resource "azurerm_virtual_machine_extension" "aad_join" {
  name                 = "AADJoin"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "1.0"


}

# Add the VM to the existing AVD host pool
resource "azurerm_virtual_desktop_host_pool_registration_info" "avd_registration" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd_host_pool.id
  expiration_date = timeadd(timestamp(), "720h") # Token expires in 30 days
  

  depends_on = [azurerm_windows_virtual_machine.avd_vm]
}

resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  
  name                       = "${azurerm_windows_virtual_machine.avd_vm.name}-avd_dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
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