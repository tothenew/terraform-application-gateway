# Azurerm Provider configuration
provider "azurerm" {
  features {}
}

resource "azurerm_user_assigned_identity" "example" {
  resource_group_name = "Ashwita"
  location            = "Central India"
  name                = "appgw-api"

    tags = {
    CreatedBy = "ashwita.pal@tothenew.com"
    # Add other tags as needed
  }
}

module "application-gateway" {
  # source = "../.."
  source = "git::https://github.com/tothenew/terraform-application-gateway.git"


  # By default, this module will not create a resource group and a virtual machine expect to provide 
  # a existing RG name and vnet and subnet to use an existing resource group, virtual machine and subnet. Location will be same as existing RG. 
  
  # set `create_resource_group = true` to create new resrouce.
  # set `  create_vnet = true` to create new virtual machine.

  resource_group_name  = "Ashwita"
  location             = "Central India"
  virtual_network_name = "testingcode"
  subnet_name          = "subnet01"
  app_gateway_name     = "testgateway"

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  backend_address_pools = [
    {
      name  = "appgw-testgateway-01pool"
      fqdns = ["example1.com", "example2.com"]
    },
    {
      name         = "appgw-testgateway-02pool"
      ip_addresses = ["1.2.3.4", "2.3.4.5"]
    }
  ]

  backend_http_settings = [
    {
      name                  = "appgw-testgateway-http-set1"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      enable_https          = false
      request_timeout       = 30
      # probe_name            = "appgw-testgateway-Central India-probe1" # Remove this if `health_probes` object is not defined.
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
    },
    {
      name                  = "appgw-testgateway-http-set2"
      cookie_based_affinity = "Enabled"
      path                  = "/"
      enable_https          = false
      request_timeout       = 30
    }
  ]

  http_listeners = [
    {
      name      = "appgw-testgatewayhtln"
      host_name = null
    }
  ]

  request_routing_rules = [
    {
      name                       = "appgw-testgateway-rqrt"
      rule_type                  = "Basic"
      http_listener_name         = "appgw-testgateway-htln"
      backend_address_pool_name  = "appgw-testgateway-01pool"
      backend_http_settings_name = "appgw-testgateway-http-set1"
    }
  ]

  # A list with a single user managed identity id to be assigned to access Keyvault
  identity_ids = ["${azurerm_user_assigned_identity.example.id}"]

  # Adding TAG's to Azure resources
  tags = {
    CreatedBy    = "ashwita.pal@tothenew.com"
    ProjectName  = "demo-internal"
    Env          = "dev"
  }
}