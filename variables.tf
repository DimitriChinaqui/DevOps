#Load Balancer
variable "lbname" {
  default = "lb-web"
}


#Resource Group
variable "rgname" {
  default = "RG-DEVOPS-ASSESSMENT"
}

variable "location" {
  default = "brazilsouth"
}

#Virtual Machine
variable "admpass" {
  sensitive = true
  default = ""
}

#SQL Database
variable "sqlpass" {
  sensitive = true
  default = ""
}

#Virtual Network
variable "nsgname" {
  default = "nsg-wenergy-webapp"

}

variable "vnetname" {
  default = "vnet-wenergy-webapp"
}