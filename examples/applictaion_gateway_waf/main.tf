# Azurerm Provider configuration
provider "azurerm" {
  features {}
}

resource "azurerm_user_assigned_identity" "example" {
  resource_group_name = "Ashwita"
  location            = "Central India"
  name                = "appgw-api"
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
  subnet_name          = "sdefault"
  app_gateway_name     = "testgateway"

  sku = {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 15
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

  # `probe_name` argument is required if you are defing health probes.
  backend_http_settings = [
    {
      name                  = "appgw-testgateway-http-set1"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      enable_https          = true
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

  # List of HTTP/HTTPS listeners. SSL Certificate name is required

  http_listeners = [
    {
      name                 = "appgw-testgateway-htln01"
      ssl_certificate_name = "appgw-testgateway-ssl01"
      host_name            = null
    }
  ]

  request_routing_rules = [
    {
      name                       = "appgw-testgateway-rqrt"
      rule_type                  = "Basic"
      http_listener_name         = "appgw-testgateway-htln01"
      backend_address_pool_name  = "appgw-testgateway-01pool"
      backend_http_settings_name = "appgw-testgateway-http-set1"
    }
  ]

  ssl_certificates = [{
    name     = "appgw-testgateway-ssl01"
    data     = "./keyBag.pfx"
    password = "P@$$w0rd123"
  }]

  # WAF configuration, disabled rule groups and exclusions.depends_on

  waf_configuration = {
    firewall_mode            = "Detection"
    rule_set_version         = "3.1"
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128

    disabled_rule_group = [
      {
        rule_group_name = "REQUEST-930-APPLICATION-ATTACK-LFI"
        rules           = ["930100", "930110"]
      },
      {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rules           = ["920160"]
      }
    ]

    exclusion = [
      {
        match_variable          = "RequestCookieNames"
        selector                = "SomeCookie"
        selector_match_operator = "Equals"
      },
      {
        match_variable          = "RequestHeaderNames"
        selector                = "referer"
        selector_match_operator = "Equals"
      }
    ]
  }

  identity_ids = ["${azurerm_user_assigned_identity.example.id}"]

  # Adding TAG's to Azure resources
  tags = {
    CreatedBy    = "ashwita.pal@tothenew.com"
    ProjectName  = "demo-internal"
    Env          = "dev"
  }
}