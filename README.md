# Azure Virtual Desktop (AVD) Terraform Template

This Terraform template automates the deployment of a complete Azure Virtual Desktop (AVD) environment, including:

- Resource Group
- Host Pool
- Application Group
- Workspace
- Virtual Machines (Session Hosts)
- Virtual Network and Subnet
- Azure AD Join for VMs
- DSC Extension for Session Host Configuration

## Prerequisites

Before using this Terraform template, ensure you have the following:

1. **Azure Subscription**: You need an active Azure subscription.
2. **Azure CLI**: Required to authenticate and interact with Azure.
3. **Terraform**: Required to deploy the infrastructure as code.
4. **PowerShell**: Used to run installation and configuration scripts.

---

## Installation Instructions

### 1. Install Terraform

To install Terraform using PowerShell, run the following commands:

```powershell
# Download Terraform
$terraformUrl = "https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_windows_amd64.zip"
$terraformZipPath = "$env:TEMP\terraform.zip"
Invoke-WebRequest -Uri $terraformUrl -OutFile $terraformZipPath

# Extract Terraform
Expand-Archive -Path $terraformZipPath -DestinationPath "$env:SystemDrive\terraform"

# Add Terraform to the system PATH
$env:Path += ";$env:SystemDrive\terraform"

# Verify Installation
terraform --version

## 2. Install Azure CLI

To install Azure CLI using PowerShell, run the following commands:

```powershell
# Download and install Azure CLI
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'

# Verify Installation
az --version


## 3. Authenticate with Azure
After installing Azure CLI, authenticate with your Azure account:

# Log in to Azure
az login

# Set the subscription (replace with your subscription ID)
az account set --subscription "421343h4f"

##How to Use the Terraform Template
1. Clone the Repository
Clone the repository containing the Terraform template:

git clone https://github.com/your-repo/avd-terraform-template.git
cd avd-terraform-template

2. Fill Out terraform.tfvars
The terraform.tfvars file contains the configuration values for your AVD environment. Below is an example of how to fill it out:

subscription_id = "5d4206f2-8af2-479a-b7f9-5fb434457d5f"  # Replace with your Azure subscription ID
user_principal_names = [
  "roan@nerdiomanagerdemo.com"  # Replace with the UPNs of users who will access the AVD environment
]
location                = "East US"  # Azure region for deployment
location_abv            = "eus"      # Abbreviation for the location (e.g., "eus" for East US)
enviroment              = "T"        # Environment type (e.g., "T" for Test)
application             = "rp"       # Application or project name
rdsh_count              = 1          # Number of session host VMs to deploy
admin_username          = "adminuser"  # Admin username for the VMs
admin_password          = "P@ssw0rd1234!"  # Admin password for the VMs
vm_size                 = "Standard_D2s_v3"  # VM size for session hosts
os_disk_caching         = "ReadWrite"  # OS disk caching type
os_disk_storage_account_type = "Standard_LRS"  # OS disk storage type
image_publisher         = "MicrosoftWindowsDesktop"  # Source image publisher
image_offer             = "Office-365"  # Source image offer
image_sku               = "win11-23h2-avd-m365"  # Source image SKU
image_version           = "latest"  # Source image version
vnet_name               = "avd_vnet"  # Name of the virtual network
vnet_address_space      = ["10.0.0.0/16"]  # Address space for the virtual network
subnet_address_prefixes = ["10.0.1.0/24"]  # Address prefixes for the subnet
host_pool_type          = "Pooled"  # Host pool type 


#Notes

Ensure that the admin_password meets Azure's password complexity requirements.

Replace all placeholder values in terraform.tfvars with your specific configuration.

The dsc_modules_url and dsc_configuration_func are specific to the AVD session host configuration. Do not modify these unless you have a custom DSC configuration.

Support
For issues or questions, please open an issue in the repository or contact the maintainers.