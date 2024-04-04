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
  resource_group_name = var.vnet_resource_group_name == null ? data.azurerm_resource_group.rgrp[0].name : var.vnet_resource_group_name
  location            = local.location
  address_space       = var.virtual_network_address
  tags     = merge({ "ResourceName" = format("%s", var.resource_group_name) }, var.tags, )
}

# Create subnet only if var.create_vnet is true
resource "azurerm_subnet" "example" {
  count                = var.create_vnet ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = var.vnet_resource_group_name == null ? local.resource_group_name : var.vnet_resource_group_name
  virtual_network_name = local.vnet
  address_prefixes     = var.subnet_address
}

data "azurerm_subnet" "snet" {
  count               = var.create_vnet == false ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = local.vnet
  resource_group_name  = local.resource_group_name
}
