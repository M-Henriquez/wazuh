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

// security group
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

// nic
resource "azurerm_network_interface" "nic" {
    name = "wazuh-nic"
    location = azurerm_resource_group.wazuh.location
    resource_group_name = azurerm_resource_group.wazuh.name

    ip_configuration {
        name = "internal"
        subnet_id = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.wazuh_pblic_ip.id
    }

    network_security_group_id = azurer_network_security_group
}

//public ip
resource "azurerm_public_ip" "wazuh_public_ip" {
    name = "wazuh-public-ip"
    location = azurerm_resource_group.wazuh.location
    resource_group_name = azurerm_resource_group.wazuh.name
    allocated_method = "Static"
    sku = "Basic"
}

// virtual machine
resource "azurerm_linux_virtual_machine" "wazuh_vm" {
    name = "wazuh-server"
    resource_group_name = azurerm_resource_group.wazuh.name
    location = azurerm_resource_group.wazuh.location
    size = "Standard_D4s_v3"
    admin_username = "azureuser"
    network_interface_ids = [
        azurerm_network_interface.nic.id
    ]
    admin_ssh_key {
        username = "azureuser"
        public_key = "SSH KEY HERE"
    }

    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
        name = "wazuh-os-disk"
    }

    source_image_reference {
        publisher = "Canonical"
        offer = "0001-com-ubuntu-server-focal"
        sku = "20_04-lts"
        version = "latest"
    }

    computer_name = "wazuhvm"
    disabled_password_authentication = true
}

resource "azurerm_virtual_machine_extension" "wazuh_install" {
    name = "wazuh-installer"
    virtual_machine_id = azurerm_linux_virtual_machine.wazuh_vm.id
    publisher = "Microsoft.Azure.Extensions"
    type = "CustomScript"
    type_handler_version = "2.1"

    settings = <<SETTINGS
    {
    "fileUris": ["https://packages.wazuh.com/4.7/wazuh-install.sh"],
    "commandToExecute": "bash wazuh-install.sh -a"
    }
    SETTINGS
}
