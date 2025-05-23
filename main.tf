#terraform1
/*
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.27.0"
    }
  }
}
*/

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "36e75950-00c3-4e4d-801b-b3e789e08297" # Replace with your actual subscription ID
}


locals {
  resource_group_name="myrg14"
  location="West Europe"

  virtual_network_name = {
    name="myvnet012"
    address_space=["10.0.0.0/16"]
  }
}

resource "azurerm_resource_group" "Rg" {
  name     = local.resource_group_name
  location = local.location
}



resource "azurerm_virtual_network" "vnetdetails" {
  name                = local.virtual_network_name.name
  address_space       = local.virtual_network_name.address_space
  location            = local.location
  resource_group_name = local.resource_group_name
  depends_on = [ azurerm_resource_group.Rg ]
}

resource "azurerm_subnet" "subnetdetails" {
  name                 = "mysubnet014"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network_name.name
  address_prefixes     = ["10.0.2.0/24"]
  depends_on = [ azurerm_virtual_network.vnetdetails ]
}

resource "azurerm_network_interface" "nicdetails" {
  name                = "mynic14"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnetdetails.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pipdetails.id
  }
  depends_on = [ azurerm_subnet.subnetdetails ]
}
resource "azurerm_public_ip" "pipdetails" {
  name                = "mypip012"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"

  depends_on = [ azurerm_resource_group.Rg ]
}

resource "azurerm_network_security_group" "nsgdetails"{
  name                = "nsg001"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    depends_on = [ azurerm_resource_group.Rg ]
}
resource "azurerm_subnet_network_security_group_association" "nsglink" {
  subnet_id                 = azurerm_subnet.subnetdetails.id
  network_security_group_id = azurerm_network_security_group.nsgdetails.id
}

resource "azurerm_windows_virtual_machine" "vmdetails" {
  name                = "myvm012"
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.nicdetails.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  depends_on = [ azurerm_network_interface.nicdetails,azurerm_resource_group.Rg ]

}
