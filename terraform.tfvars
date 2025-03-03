subscription_id = "5d4206f2-8af2-479a-b7f9-5fb434457d5f"
user_principal_names = [
  "roan@nerdiomanagerdemo.com"

]
location                = "East US"
location_abv            = "eus"
enviroment              = "P"
application             = "rsp"
rdsh_count              = 1
admin_username = "adminuser"
admin_password = "P@ssw0rd1234!"
vm_size = "Standard_D2s_v3"
os_disk_caching = "ReadWrite"
os_disk_storage_account_type = "Standard_LRS"
image_publisher = "MicrosoftWindowsDesktop"
image_offer = "Office-365"
image_sku = "win11-23h2-avd-m365"
image_version = "latest"
vnet_name = "avd_vnet"
vnet_address_space = ["10.0.0.0/16"]
subnet_address_prefixes = ["10.0.1.0/24"]
host_pool_type = "Pooled"
load_balancer_type = "BreadthFirst"
custom_rdp_properties = "targetisaadjoined:i:1"
preferred_app_group_type = "Desktop"
validate_environment = "false"
workspace_friendly_name = "RP AVD Workspace"
workspace_description = "Workspace for Azure Virtual Desktop"
aad_join_extension_version = "1.0"
dsc_extension_version = "2.73"
dsc_modules_url = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02774.414.zip"
dsc_configuration_func = "Configuration.ps1\\AddSessionHost"

