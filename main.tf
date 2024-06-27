#Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.rgname
  location = var.location
}

#Virtual Machine Web
resource "azurerm_network_interface" "nic_web" {
  count               = 2
  name                = "nic_web_${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet[1].id
    private_ip_address_allocation = "Dynamic"
  }

}

resource "azurerm_virtual_machine" "vm_web" {
  count                 = 2
  name                  = "LX-WEB-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_web[count.index].id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "osdisk_${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "adminuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

#Virtual Machine App
resource "azurerm_network_interface" "nic_app" {
  name                = "nic_app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet[0].id
    private_ip_address_allocation = "Dynamic"
  }

}

resource "azurerm_virtual_machine" "vm_app" {
  name                  = "vm_app"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_app.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "osdisk_app"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "adminuser"
    admin_password = var.admpass
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

#SQL Database
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sqlsrv-wenergy-test-01"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sqlpass
}

resource "azurerm_mssql_database" "sql_db" {
  name      = "sqldb-wenergy-test-01"
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = "S1"
}

#Load Balancer
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "public-ip-${var.lbname}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}


resource "azurerm_lb" "lb" {
  name                = var.lbname
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  frontend_ip_configuration {
    name                 = "lbFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = "lbBackendAddressPool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "lbprobe" {
  name                = "http_probe"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "lbrule" {
  name                           = "http_rule"
  loadbalancer_id                = azurerm_lb.lb.id
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id                       = azurerm_lb_probe.lbprobe.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  idle_timeout_in_minutes        = 4
  enable_floating_ip             = false
}

#Network Security Group
resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-${lookup(element(var.subnet_prefix, 0), "tier")}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nsg_app" {
  name                = "nsg-${lookup(element(var.subnet_prefix, 1), "tier")}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_App_Traffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nsg_db" {
  name                = "nsg-${lookup(element(var.subnet_prefix, 2), "tier")}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_SQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_subnet_network_security_group_association" "nsg_association_web" {
  subnet_id                 = azurerm_subnet.subnet[0].id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_app" {
  subnet_id                 = azurerm_subnet.subnet[1].id
  network_security_group_id = azurerm_network_security_group.nsg_app.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_db" {
  subnet_id                 = azurerm_subnet.subnet[2].id
  network_security_group_id = azurerm_network_security_group.nsg_db.id
}

#Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnetname
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = lookup(element(var.subnet_prefix, count.index), "name")
  count                = length(var.subnet_prefix)
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = lookup(element(var.subnet_prefix, count.index), "ip")

}


variable "subnet_prefix" {
  type = list(any)
  default = [
    {
      ip   = ["10.0.1.0/24"]
      name = "subnet-web"
      tier = "web"
    },
    {
      ip   = ["10.0.2.0/24"]
      name = "subnet-app"
      tier = "app"
    },
    {
      ip   = ["10.0.3.0/24"]
      name = "subnet-db"
      tier = "db"
    }
  ]
}


