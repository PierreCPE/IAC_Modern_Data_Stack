# This Terraform script sets up an Azure VM with Airbyte and Azurite using cloud-init for configuration.
# It creates a resource group, virtual network, subnet, public IP, network security group, network interface,
# and a Linux virtual machine. The VM is configured to allow SSH access and has ports for Airbyte and Azurite open.
# The cloud-init script is used to install Docker, Docker Compose, and set up Airbyte and Azurite.
# Ensure you have the Azure CLI installed and authenticated
# before running this script. You can run this script using the command:
# terraform init
# terraform apply
# Make sure to replace the SSH public key path with your own
# and adjust the VM size and location as needed.


provider "azurerm" {
  features {}
  subscription_id = "d38e61da-70aa-47aa-81fd-74d0d6746c65"
}

# Resource group for the VM
resource "azurerm_resource_group" "main" {
  name     = "rg-airbyte-vm"
  location = "westeurope"
}

# Virtual network and subnet for the VM
resource "azurerm_virtual_network" "main" {
  name                = "vnet-airbyte"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet for the VM
resource "azurerm_subnet" "main" {
  name                 = "subnet-airbyte"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP for the VM (cost money, few cents per month)
# resource "azurerm_public_ip" "main" {
#   name                = "ip-airbyte"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   allocation_method   = "Static"
# }

# OR dynamic public IP (free)

resource "azurerm_public_ip" "main" {
  name                = "ip-airbyte"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
}

# Network security group for the VM
# This security group allows SSH, Airbyte, and Azurite access
resource "azurerm_network_security_group" "main" {
  name                = "nsg-airbyte"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Airbyte"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Azurite"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10000-10002"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network interface for the VM
# This interface connects the VM to the virtual network and public IP

resource "azurerm_network_interface" "main" {
  name                = "nic-airbyte"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig-airbyte"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Associate the network security group with the network interface

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Linux virtual machine for Airbyte
# This VM is configured with cloud-init to install Docker, Docker Compose,
# and set up Airbyte and Azurite

resource "azurerm_linux_virtual_machine" "main" {
  name                  = "airbyte-vm"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.main.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = filebase64("cloud-init.yaml")

  tags = {
    environment = "airbyte"
  }
}

# Output the public IP address of the VM
output "vm_ip" {
  value = azurerm_public_ip.main.ip_address
}

# Output the SSH command to connect to the VM

output "ssh_command" {
  value = "ssh azureuser@${azurerm_linux_virtual_machine.main.public_ip_address}"
  description = "Commande SSH pour se connecter à la VM"
}
