provider "azurerm" {
    features {}

}

resource "azurerm_resource_group" "main" { 
    name = "${var.prefix}-resources"
    location = var.location
    tags = var.tagging
}

resource "azurerm_virtual_network" "main" {
    name                = "${var.prefix}-network"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    tags = var.tagging
}

resource "azurerm_subnet" "internal" {
    name                 = "internal"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.5.0/24"]
}

resource "azurerm_public_ip" "pip" {
    name  = "${var.prefix}-pip"
    resource_group_name = azurerm_resource_group.main.name
    location = azurerm_resource_group.main.location
    allocation_method = "Static"
    tags = var.tagging
}

resource "azurerm_network_interface" "main" {
    count = var.num_of_instances

    name = "${var.prefix}-nic${count.index+1}"
    resource_group_name = azurerm_resource_group.main.name
    location = azurerm_resource_group.main.location

    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.internal.id
      private_ip_address_allocation = "Dynamic"
    }

    tags = var.tagging
}

resource "azurerm_network_security_group" "main" {
    name = "${var.prefix}-nsg"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    security_rule {
        name                       = "InterVMAccess"
        priority                   = 150
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = azurerm_subnet.internal.address_prefix
        destination_address_prefix = azurerm_subnet.internal.address_prefix
    }

    security_rule {
        name                       = "DenyInternetAccess"
        priority                   = 100
        direction                  = "Inbound" 
        access                     = "Deny"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "Internet"
        destination_address_prefix = azurerm_subnet.internal.address_prefix
    }
    

  tags = var.tagging
}

resource "azurerm_lb" "main" {
    name = "${var.prefix}-lb"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    frontend_ip_configuration {
      name = "primary"
      public_ip_address_id = azurerm_public_ip.pip.id
    }

    tags = var.tagging
}

resource "azurerm_lb_backend_address_pool" "main" {
    loadbalancer_id = azurerm_lb.main.id
    name = "backendAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
    count = var.num_of_instances
    
    network_interface_id = element(azurerm_network_interface.main[*].id, count.index)
    ip_configuration_name = "internal"
    backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_availability_set" "main" {
    name = "${var.prefix}-avs"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    platform_update_domain_count = 3
    platform_fault_domain_count = 3
    managed = true

    tags = var.tagging
}

data "azurerm_image" "packerImage" {
  name = var.image_id.managed_image_name
  resource_group_name = var.image_id.managed_image_resource_group_name
}

resource "azurerm_linux_virtual_machine" "main" {
    count = var.num_of_instances 
    
    name = "${var.prefix}-vm-${count.index+1}"
    resource_group_name = azurerm_resource_group.main.name
    location = azurerm_resource_group.main.location
    size = "Standard_D2s_v3"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
    disable_password_authentication = false
    availability_set_id = azurerm_availability_set.main.id

    network_interface_ids = [
      azurerm_network_interface.main[count.index].id,
    ]

    source_image_id = data.azurerm_image.packerImage.id

    os_disk {
      storage_account_type = var.storage_account
      caching              = "ReadWrite"
    }

    tags = var.tagging
}

resource "azurerm_managed_disk" "main" {
    count = var.num_of_instances
    
    name = "${var.prefix}-managed-disk-${count.index+1}"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    storage_account_type = var.storage_account
    create_option = "Empty"
    disk_size_gb = "1"

    tags = var.tagging
}