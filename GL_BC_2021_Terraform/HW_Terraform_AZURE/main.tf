# Create a logical container for resources
resource "azurerm_resource_group" "webhub" {
    name     = "ws2lb-rg"
    location = var.location
    tags     = merge(var.common_tags, {Name = "HomeWork"})
}

# Create isolated environment for swap data between VMs and other resources
resource "azurerm_virtual_network" "webhub" {
    name                = "ws2lb-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.webhub.name
    tags                = merge(var.common_tags, {Name = "HomeWork"})
}

# Create network security group and rule
resource "azurerm_network_security_group" "webhub" {
    name                = "ws2lb-nsg"
    location            = var.location
    resource_group_name = azurerm_resource_group.webhub.name

    security_rule {
        name                       = "ingress100"
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
        name                       = "ingress101"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "allow-ssh"
        priority                   = 102
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
    }

    tags = merge(var.common_tags, {Name = "HomeWork"})
}
/*
resource "tls_private_key" "example_ssh" {
    algorithm = "RSA"
    rsa_bits = 4096
}
*/


# Data template Bash bootstrapping file
data "template_file" "linux-vm-cloud-init" {
    template = file("azure-user-data.sh")
}


# ▄▀█ █ █ ▄▀█ █ █   ▄▀█ █▄▄ █ █   █ ▀█▀ █▄█   ▀█ █▀█ █▄ █ █▀▀   █
# █▀█ ▀▄▀ █▀█ █ █▄▄ █▀█ █▄█ █ █▄▄ █  █   █    █▄ █▄█ █ ▀█ ██▄   █

# Create a subnet for VM1
resource "azurerm_subnet" "vm1" {
    name                 = "ws2lb-vm1-sn"
    resource_group_name  = azurerm_resource_group.webhub.name
    virtual_network_name = azurerm_virtual_network.webhub.name
    address_prefixes     = ["10.0.1.0/24"]
}

# Associate the web NSG with the subnet vm1
resource "azurerm_subnet_network_security_group_association" "vm1" {
    subnet_id                 = azurerm_subnet.vm1.id
    network_security_group_id = azurerm_network_security_group.webhub.id
}

# public IPs
resource "azurerm_public_ip" "vm1" {
    name                         = "ws2lb-vm1-pip"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.webhub.name
    allocation_method            = "Static"
    availability_zone            = 1
    sku                          = "Standard"
    tags                         = merge(var.common_tags, {Name = "HomeWork"})
}

# Create network interface for VM1
resource "azurerm_network_interface" "vm1" {
    name                      = "ws2lb-vm1-nic"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.webhub.name

    ip_configuration {
        name                          = "NicConfiguration"
        subnet_id                     = azurerm_subnet.vm1.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.vm1.id
    }
}

resource "azurerm_lb_backend_address_pool_address" "vm1" {
    name                    = "vm1"
    backend_address_pool_id = azurerm_lb_backend_address_pool.vms.id
    virtual_network_id      = azurerm_virtual_network.webhub.id
    ip_address              = azurerm_linux_virtual_machine.vm1.private_ip_address
}


############################################################
#         ubuntu 🆅🅸🆁🆃🆄🅰🅻 🅼🅰🅲🅷🅸🅽🅴 I create        #
############################################################
resource "azurerm_linux_virtual_machine" "vm1" {
    name                  = "ws2lb-vm1"
    location              = var.location
    resource_group_name   = azurerm_resource_group.webhub.name
    network_interface_ids = [azurerm_network_interface.vm1.id]
    zone                  = 1
    size                  = "Standard_B1s"
    admin_username        = "azureuser"
    admin_password        = var.azureuser_password
    disable_password_authentication = false
    custom_data           = base64encode(data.template_file.linux-vm-cloud-init.rendered)
    os_disk {
        name                 = "OsDisk1"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }
/*
    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.example_ssh.public_key_openssh
    }
*/
    tags = merge(var.common_tags, {Name = "HomeWork"})

}


# ▄▀█ █ █ ▄▀█ █ █   ▄▀█ █▄▄ █ █   █ ▀█▀ █▄█   ▀█ █▀█ █▄ █ █▀▀   █ █
# █▀█ ▀▄▀ █▀█ █ █▄▄ █▀█ █▄█ █ █▄▄ █  █   █    █▄ █▄█ █ ▀█ ██▄   █ █

# Create a subnet for VM2
resource "azurerm_subnet" "vm2" {
    name                 = "ws2lb-vm2-sn"
    resource_group_name  = azurerm_resource_group.webhub.name
    virtual_network_name = azurerm_virtual_network.webhub.name
    address_prefixes     = ["10.0.10.0/24"]
}

# Associate the web NSG with the subnet vm2
resource "azurerm_subnet_network_security_group_association" "vm2" {
    subnet_id                 = azurerm_subnet.vm2.id
    network_security_group_id = azurerm_network_security_group.webhub.id
}

# public IPs
resource "azurerm_public_ip" "vm2" {
    name                         = "ws2lb-vm2-pip"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.webhub.name
    allocation_method            = "Static"
    availability_zone            = 1
    sku                          = "Standard"
    tags                         = merge(var.common_tags, {Name = "HomeWork"})
    
}

# Create network interface for VM2
resource "azurerm_network_interface" "vm2" {
    name                      = "ws2lb-vm2-nic"
    location                  = var.location
    resource_group_name       = azurerm_resource_group.webhub.name

    ip_configuration {
        name                          = "NicConfiguration"
        subnet_id                     = azurerm_subnet.vm2.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.vm2.id
    }
}

resource "azurerm_lb_backend_address_pool_address" "vm2" {
  name                    = "vm2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.vms.id
  virtual_network_id      = azurerm_virtual_network.webhub.id
  ip_address              = azurerm_linux_virtual_machine.vm2.private_ip_address
}


############################################################
#         ubuntu 🆅🅸🆁🆃🆄🅰🅻 🅼🅰🅲🅷🅸🅽🅴 II create       #
############################################################
resource "azurerm_linux_virtual_machine" "vm2" {
    name                  = "ws2lb-vm2"
    location              = var.location
    resource_group_name   = azurerm_resource_group.webhub.name
    network_interface_ids = [azurerm_network_interface.vm2.id]
    zone                  = 2
    size                  = "Standard_B1s"
    admin_username        = "azureuser"
    admin_password        = var.azureuser_password
    disable_password_authentication = false
    custom_data           = base64encode(data.template_file.linux-vm-cloud-init.rendered)
    os_disk {
        name                 = "OsDisk2"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }
/*
    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.example_ssh.public_key_openssh
    }
*/
    tags = merge(var.common_tags, {Name = "HomeWork"})
}



#  █── █▀▀█ █▀▀█ █▀▀▄  █▀▀▄ █▀▀█ █── █▀▀█ █▀▀▄ █▀▀ █▀▀ █▀▀█  #
#  █── █──█ █▄▄█ █──█  █▀▀▄ █▄▄█ █── █▄▄█ █──█ █── █▀▀ █▄▄▀  #
#  ▀▀▀ ▀▀▀▀ ▀──▀ ▀▀▀─  ▀▀▀─ ▀──▀ ▀▀▀ ▀──▀ ▀──▀ ▀▀▀ ▀▀▀ ▀─▀▀  #

resource "azurerm_public_ip" "lb" {
    name                = "ws2lb-lb-pip"
    resource_group_name = azurerm_resource_group.webhub.name
    location            = var.location
    allocation_method   = "Static"
    sku                 = "Standard"

    tags                = merge(var.common_tags, {Name = "HomeWork"})
}

resource "azurerm_lb" "webhub" {
    name                = "ws2lb-lb"
    resource_group_name = azurerm_resource_group.webhub.name
    location            = var.location
    sku                 = "Standard"

    frontend_ip_configuration {
      name                 = "PublicIPAddress"
      public_ip_address_id = azurerm_public_ip.lb.id
    }
}

resource "azurerm_lb_probe" "http" {
    resource_group_name = azurerm_resource_group.webhub.name
    loadbalancer_id     = azurerm_lb.webhub.id
    name                = "http"
    port                = 80
}

resource "azurerm_lb_backend_address_pool" "vms" {
    loadbalancer_id = azurerm_lb.webhub.id
    name            = "vms-http"
}

resource "azurerm_lb_rule" "http" {
    resource_group_name            = azurerm_resource_group.webhub.name
    loadbalancer_id                = azurerm_lb.webhub.id
    name                           = "Http"
    protocol                       = "Tcp"
    frontend_port                  = 80
    backend_port                   = 80
    frontend_ip_configuration_name = "PublicIPAddress"
    backend_address_pool_id        = azurerm_lb_backend_address_pool.vms.id
    probe_id                       = azurerm_lb_probe.http.id
}
