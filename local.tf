locals {
  frontend_port_name             = "appgw-${var.app_gateway_name}-${local.location}-feport"
  frontend_ip_configuration_name = "appgw-${var.app_gateway_name}-${local.location}-feip"
  gateway_ip_configuration_name  = "appgw-${var.app_gateway_name}-${local.location}-gwipc"

  resource_group_name = data.azurerm_resource_group.rgrp[0].name
  location            = data.azurerm_resource_group.rgrp[0].location
}