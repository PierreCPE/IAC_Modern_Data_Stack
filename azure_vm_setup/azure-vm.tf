provider "azurerm" {
  features {}
}


variable "vm_username" {
  description = "Username for the VM"
  default     = "azureuser"
}

variable "vm_password" {
  description = "Password for the VM"
  sensitive   = true
}

# Create resource group
resource "azurerm_resource_group" "airbyte_rg" {
  name     = "airbyte-resources"
  location = "East US"
}

# Create virtual network
resource "azurerm_virtual_network" "airbyte_vnet" {
  name                = "airbyte-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.airbyte_rg.location
  resource_group_name = azurerm_resource_group.airbyte_rg.name
}

# Create subnet
resource "azurerm_subnet" "airbyte_subnet" {
  name                 = "airbyte-subnet"
  resource_group_name  = azurerm_resource_group.airbyte_rg.name
  virtual_network_name = azurerm_virtual_network.airbyte_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "airbyte_public_ip" {
  name                = "airbyte-public-ip"
  location            = azurerm_resource_group.airbyte_rg.location
  resource_group_name = azurerm_resource_group.airbyte_rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "airbyte_nsg" {
  name                = "airbyte-nsg"
  location            = azurerm_resource_group.airbyte_rg.location
  resource_group_name = azurerm_resource_group.airbyte_rg.name

  security_rule {
    name                       = "SSH"
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
    name                       = "Airbyte"
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
    name                       = "Azurite"
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

# Create network interface
resource "azurerm_network_interface" "airbyte_nic" {
  name                = "airbyte-nic"
  location            = azurerm_resource_group.airbyte_rg.location
  resource_group_name = azurerm_resource_group.airbyte_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.airbyte_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.airbyte_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "airbyte_nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.airbyte_nic.id
  network_security_group_id = azurerm_network_security_group.airbyte_nsg.id
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "airbyte_vm" {
  name                = "airbyte-vm"
  location            = azurerm_resource_group.airbyte_rg.location
  resource_group_name = azurerm_resource_group.airbyte_rg.name
  size                = "Standard_D4s_v3"  # 4 vCPUs, 16 GB RAM - recommended for Airbyte
  admin_username      = var.vm_username
  admin_password      = var.vm_password 

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.airbyte_nic.id,
  ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 100  # Increased to accommodate Docker images and data
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# Install dependencies using custom script extension
resource "azurerm_virtual_machine_extension" "airbyte_setup" {
  name                 = "airbyte-setup"
  virtual_machine_id   = azurerm_linux_virtual_machine.airbyte_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    "script": base64encode(file("setup-airbyte.sh"))
  })
}

# Output the public IP
output "public_ip_address" {
  value = azurerm_public_ip.airbyte_public_ip.ip_address
}