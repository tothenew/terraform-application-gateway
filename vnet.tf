data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = merge({ "ResourceName" = format("%s", var.resource_group_name) }, var.tags, )
}

data "azurerm_virtual_network" "vnet" {
  count               = var.create_vnet == false ? 1 : 0
  name                = var.virtual_network_name
  resource_group_name = var.vnet_resource_group_name == null ? local.resource_group_name : var.vnet_resource_group_name
}

resource "azurerm_virtual_network" "example" {
  count               = var.create_vnet ? 1 : 0
  name                = var.virtual_network_name
  resource_group_name = var.vnet_resource_group_name == null ? local.resource_group_name : var.vnet_resource_group_name
  location            = azurerm_resource_group.rg[0].location
  address_space       = var.virtual_network_address
}

# Create subnet only if var.create_vnet is true
resource "azurerm_subnet" "example" {
  count                = var.create_vnet ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg[0].name
  virtual_network_name = azurerm_virtual_network.example[0].name
  address_prefixes     = var.subnet_address
}

data "azurerm_subnet" "snet" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet[0].name
  resource_group_name  = data.azurerm_virtual_network.vnet[0].resource_group_name
}