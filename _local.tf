locals {
  frontend_port_name             = "appgw-${var.app_gateway_name}-${local.location}-feport"
  frontend_ip_configuration_name = "appgw-${var.app_gateway_name}-${local.location}-feip"
  gateway_ip_configuration_name  = "appgw-${var.app_gateway_name}-${local.location}-gwipc"

  # resource_group_name = data.azurerm_resource_group.rgrp[0].name
  # location            = data.azurerm_resource_group.rgrp[0].location
  resource_group_name = length(data.azurerm_resource_group.rgrp) > 0 ? data.azurerm_resource_group.rgrp[0].name : var.resource_group_name
  location            = length(data.azurerm_resource_group.rgrp) > 0 ? data.azurerm_resource_group.rgrp[0].location : var.location

  vnet      = length(data.azurerm_virtual_network.vnet) > 0 ? data.azurerm_virtual_network.vnet[0].name : var.virtual_network_name
  subnet    = length(data.azurerm_subnet.snet) > 0 ? data.azurerm_subnet.snet[0].name : var.subnet_name
  subnet_id = length(data.azurerm_subnet.snet) > 0 ? data.azurerm_subnet.snet[0].id : azurerm_subnet.example[0].id
}