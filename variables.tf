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