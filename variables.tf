variable "subscription_id" {
  description = "This is the cloud hosting subscription where the Avd will be provisioned."
}

variable "user_principal_names" {
  description = "List of user principal names (UPNs) to assign access to the AVD Application Group"
  type        = list(string)
}
variable "location" {
  description = "This is the cloud hosting region where your resource or app will be deployed."
}

variable "location_abv" {
  description = "This is the cloud hosting region where your resource or app will be deployed."
}

variable "enviroment" {
  description = "This is the environment where your webapp is deployed. uat, qa, prod, or dev"
}

variable "application" {
  description = "This is the name of the application"
}

variable "rdsh_count" {
  description = "Number of AVD machines to deploy"
  default     = 2
}

variable "admin_username" {
  description = "The username for the admin account on the virtual machines."
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "The password for the admin account on the virtual machines."
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "The size of the virtual machines."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "os_disk_caching" {
  description = "The caching type for the OS disk."
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "The storage account type for the OS disk."
  type        = string
  default     = "Standard_LRS"
}

variable "image_publisher" {
  description = "The publisher of the source image."
  type        = string
  default     = "MicrosoftWindowsDesktop"
}

variable "image_offer" {
  description = "The offer of the source image."
  type        = string
  default     = "Office-365"
}

variable "image_sku" {
  description = "The SKU of the source image."
  type        = string
  default     = "win11-23h2-avd-m365"
}

variable "image_version" {
  description = "The version of the source image."
  type        = string
  default     = "latest"
}
variable "vnet_name" {
  description = "This is going to be the vnet name"
  type = string
  default = "avd_vnet"
  
}

variable "vnet_address_space" {
  description = "The address space for the virtual network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "The address prefixes for the subnet."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "host_pool_type" {
  description = "The type of the host pool (Pooled or Personal)."
  type        = string
  default     = "Pooled"
}

variable "load_balancer_type" {
  description = "The load balancer type for the host pool (BreadthFirst or DepthFirst)."
  type        = string
  default     = "BreadthFirst"
}

variable "custom_rdp_properties" {
  description = "Add any custom RDP properties"
  type = string
  default = "targetisaadjoined:i:1"
  
}

variable "preferred_app_group_type" {
  description = "The preferred application group type (Desktop or RailApplications)."
  type        = string
  default     = "Desktop"
}
variable "validate_environment" {
  description = "If this is validation environment."
  type        = bool
  default     = false
}

variable "workspace_friendly_name" {
  description = "The friendly name for the AVD workspace."
  type        = string
  default     = "RP AVD Workspace"
}

variable "workspace_description" {
  description = "The description for the AVD workspace."
  type        = string
  default     = "Workspace for Azure Virtual Desktop"
}

variable "aad_join_extension_version" {
  description = "The version of the AAD join extension."
  type        = string
  default     = "1.0"
}

variable "dsc_extension_version" {
  description = "The version of the DSC extension."
  type        = string
  default     = "2.73"
}

variable "dsc_modules_url" {
  description = "The URL for the DSC modules."
  type        = string
  default     = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02774.414.zip"
}

variable "dsc_configuration_func" {
  description = "The configuration function for the DSC extension."
  type        = string
  default     = "Configuration.ps1\\AddSessionHost"
}

