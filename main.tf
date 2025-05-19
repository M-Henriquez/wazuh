provider "azurerm" {
    features {}
}

// create resource group
resource "azurerm_resource_group" "wazuh" {
    name = "wazuh-rg"
    location = "East US"
}

// virtual network
resource "azurerm_virtual_network" "vnet" {
    name = "wazuh-vnet"
    address_space = ["10.0.0.0/16"]
    location = azurerm_resource_group.wazuh.location
    resource_group_name = azurerm_resource_group.wazuh.name
}

// subnet
resource "azurerm_subnet" "subnet" {
    name = "wazuh-subnet"
    resource_group_name = azurerm_resource_group.wazuh.name
    virtual_network_name = azurerm_resource_group.vnet.name
    address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
    name = "wazuh-nsg"
    location = azurerm_resource_group.wazuh.location
    resource_group_name = azurer_resource_group.wazuh.name

    security_rule {
        name = "SSH"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "PUBLIC_IP/32"
        destination_address_prefix = "*"

    }

    security_rule {
        name = "Wazuh-Ports"
        priority = 200
        direction = "Inbound"
        access = "Allow"
        protocol = "*"
        source_port_range = "*"
        destination_port_ranges = ["443", "1514", "1515", "5601", "9200"]
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
}
