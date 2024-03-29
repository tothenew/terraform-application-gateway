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
  source  = "kumarvna/application-gateway/azurerm"
  version = "1.1.0"

  # By default, this module will not create a resource group and expect to provide 
  # a existing RG name to use an existing resource group. Location will be same as existing RG. 
  # set the argument to `create_resource_group = true` to create new resrouce.
  resource_group_name  = "Ashwita"
  location             = "Central India"
  virtual_network_name = "vnet-shared-hub-Central India-001"
  subnet_name          = "snet-appgateway"
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
      name  = "appgw-testgateway-Central India-bapool01"
      fqdns = ["example1.com", "example2.com"]
    },
    {
      name         = "appgw-testgateway-Central India-bapool02"
      ip_addresses = ["1.2.3.4", "2.3.4.5"]
    }
  ]

  # `probe_name` argument is required if you are defing health probes.
  backend_http_settings = [
    {
      name                  = "appgw-testgateway-Central India-be-http-set1"
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
      name                  = "appgw-testgateway-Central India-be-http-set2"
      cookie_based_affinity = "Enabled"
      path                  = "/"
      enable_https          = false
      request_timeout       = 30
    }
  ]

  # List of HTTP/HTTPS listeners. SSL Certificate name is required

  http_listeners = [
    {
      name                 = "appgw-testgateway-Central India-be-htln01"
      ssl_certificate_name = "appgw-testgateway-Central India-ssl01"
      host_name            = null
    }
  ]

  request_routing_rules = [
    {
      name                       = "appgw-testgateway-Central India-be-rqrt"
      rule_type                  = "Basic"
      http_listener_name         = "appgw-testgateway-Central India-be-htln01"
      backend_address_pool_name  = "appgw-testgateway-Central India-bapool01"
      backend_http_settings_name = "appgw-testgateway-Central India-be-http-set1"
    }
  ]

  ssl_certificates = [{
    name     = "appgw-testgateway-Central India-ssl01"
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
    ProjectName  = "demo-internal"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}