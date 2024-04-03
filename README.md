# Azure Application Gateway Terraform Module

[![Lint Status](https://github.com/tothenew/terraform-azurerm-template/workflows/Lint/badge.svg)](https://github.com/tothenew/terraform-azurerm-template/actions)
[![LICENSE](https://img.shields.io/github/license/tothenew/terraform-azurerm-template)](https://github.com/tothenew/terraform-azurerm-template/blob/master/LICENSE)

Azure Application Gateway is a web traffic (OSI layer 7) load balancer that enables you to manage traffic to your web applications. Traditional load balancers operate at the transport layer (OSI layer 4 - TCP and UDP) and route traffic based on source IP address and port, to a destination IP address and port.

This terraform module quickly creates a desired application gateway with additional options like WAF, Custom Error Configuration, URL path mapping and many other options.

## Module Usage

```hcl
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
  source  = "../.."

  # By default, this module will not create a resource group and expect to provide 
  # a existing RG name to use an existing resource group. Location will be same as existing RG. 
  # set the argument to `create_resource_group = true` to create new resrouce.

  resource_group_name  = "Ashwita"
  location             = "Central India"
  virtual_network_name = "vnet-shared-hub-Central India"
  subnet_name          = "snet-appgateway"
  app_gateway_name     = "testgateway"


  sku = {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 15
  }

  # A backend pool routes request to backend servers, which serve the request.
  # Can create different backend pools for different types of requests

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

 # List of backend HTTP settings can be added here.  
  # `probe_name` argument is required if you are defing health probes.

  backend_http_settings = [
    {
      name                  = "appgw-testgateway-Central India-be-http-set1"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      enable_https          = true
      request_timeout       = 30
      probe_name            = "appgw-testgateway-Central India-probe1" # Remove this if `health_probes` object is not defined.
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

  # Request routing rule is to determine how to route traffic on the listener. 

  request_routing_rules = [
    {
      name                       = "appgw-testgateway-Central India-be-rqrt"
      rule_type                  = "Basic"
      http_listener_name         = "appgw-testgateway-Central India-be-htln01"
      backend_address_pool_name  = "appgw-testgateway-Central India-bapool01"
      backend_http_settings_name = "appgw-testgateway-Central India-be-http-set1"
    }
  ]

  health_probes = [
    {
      name                = "appgw-testgateway-Central India-probe1"
      host                = "127.0.0.1"
      interval            = 30
      path                = "/"
      port                = 443
      timeout             = 30
      unhealthy_threshold = 3
    }
  ]

  # Adding TAG's to Azure resources
  tags = {
    CreatedBy    = "ashwita.pal@tothenew.com"
    ProjectName  = "demo-internal"
    Env          = "dev"
  }
}
```

## sku - Which one is the correct sku v1 or V2?

Application Gateway is available under a Standard_v2 SKU. Web Application Firewall (WAF) is available under a WAF_v2 SKU. The v2 SKU offers performance enhancements and adds support for critical new features like autoscaling, zone redundancy, and support for static VIPs.

Application Gateway Standard_v2 supports autoscaling and can scale up or down based on changing traffic load patterns. Autoscaling also removes the requirement to choose a deployment size or instance count during provisioning.

`sku` object supports the following:

| Name | Description
|--|--
`name`|The Name of the `SKU` to use for this Application Gateway. Possible values are `Standard_Small`, `Standard_Medium`, `Standard_Large`, `Standard_v2`, `WAF_Medium`, `WAF_Large`, and `WAF_v2`.
tier|The `Tier` of the `SKU` to use for this Application Gateway. Possible values are `Standard`, `Standard_v2`, WAF and `WAF_v2`.
`capacity`|The Capacity of the `SKU` to use for this Application Gateway. When using a `V1` SKU this value must be between `1` and `32`, and `1` to `125` for a `V2` SKU. This property is optional if `autoscale_configuration` is set.

A `autoscale_configuration` block supports the following:

| Name | Description
|--|--
`min_capacity`|Minimum capacity for autoscaling. Accepted values are in the range `0` to `100`.
`max_capacity`|Maximum capacity for autoscaling. Accepted values are in the range `2` to `125`.
`name`|The name of the Backend HTTP Settings Collection.
`cookie_based_affinity`|Is Cookie-Based Affinity enabled? Possible values are `Enabled` and `Disabled`.
`affinity_cookie_name`|The name of the affinity cookie.
`path`|The Path which should be used as a prefix for all HTTP requests.
`enable_https`|enbale SSL port and https protocol. Possible values are `true` and `false`
`probe_name`|The name of an associated HTTP Probe. Required when health_probes object specified.
`request_timeout`|The request timeout in seconds, which must be between 1 and 86400 seconds.
`host_name`|Host header to be sent to the backend servers. Cannot be set if `pick_host_name_from_backend_address` is set to true.
`pick_host_name_from_backend_address`|Whether host header should be picked from the host name of the backend server. Defaults to `false`.
`authentication_certificate`|One or more authentication_certificate blocks available by specifing `authentication_certificate` object.
`trusted_root_certificate_names`|A list of trusted_root_certificate names.
`connection_draining`|A `connection_draining` object to specified with `enable_connection_draining` and `drain_timeout_sec` arguments.

## Advanced Usage of the Module

### `custom_error_configuration` - Create Application Gateway custom error pages

Application Gateway allows you to create custom error pages instead of displaying default error pages. You can use your own branding and layout using a custom error page.

Custom error pages are supported for the following two scenarios:

* **Maintenance page** - This custom error page is sent instead of a 502 bad gateway page. It's shown when Application Gateway has no backend to route traffic to.
* **Unauthorized access page** - This custom error page is sent instead of a 403 unauthorized access page. It's shown when the Application Gateway WAF detects malicious traffic and blocks it.

Custom error pages can be defined at the global level and the listener level:

* **Global level** - the error page applies to traffic for all the web applications deployed on that application gateway.
* **Listener level** - the error page is applied to traffic received on that listener.
* **Both** - the custom error page defined at the listener level overrides the one set at global level.

> The size of the error page must be less than 1 MB. You may reference either internal or external images/CSS for this HTML file. For externally referenced resources, use absolute URLs that are publicly accessible.

```hcl
module "application-gateway" {
  source  = "../.."

  # .... omitted

  http_listeners = [
    {
      name                 = "appgw-testgateway-Central India-be-htln01"
      ssl_certificate_name = "appgw-testgateway-Central India-ssl01"
      host_name            = null

      custom_error_configuration = [
        {
          custom_error_page_url = "https://example.blob.core.linux.net/appgateway/custom_error_403_page.html"
          status_code           = "HttpStatus403"
        },
        {
          custom_error_page_url = "https://example.blob.core.linux.net/appgateway/custom_error_502_page.html"
          status_code           = "HttpStatus502"
        }
      ]
    }
  ]

  custom_error_configuration = [
    {
      custom_error_page_url = "https://example.blob.core.linux.net/appgateway/custom_error_403_page.html"
      status_code           = "HttpStatus403"
    },
    {
      custom_error_page_url = "https://example.blob.core.linux.net/appgateway/custom_error_502_page.html"
      status_code           = "HttpStatus502"
    }
  ]

  # .... omitted
}
```

### `url_path_maps` - URL Path Based Routing

URL Path Based Routing allows you to route traffic to back-end server pools based on URL Paths of the request. One of the scenarios is to route requests for different content types to different backend server pools.

> For both the v1 and v2 SKUs, rules are processed in the order they are listed in the portal. If a basic listener is listed first and matches an incoming request, it gets processed by that listener. However, it is highly recommended to configure multi-site listeners first prior to configuring a basic listener. This ensures that traffic gets routed to the right back end.

The `url_path_maps` is used to specify Path patterns to back-end server pool mappings. The following code example is the snippet of `url_path_maps` from example file.

```hcl
module "application-gateway" {
  source  = "../.."

  # .... omitted

  url_path_maps = [
    {
      name                               = "testgateway-url-path"
      default_backend_address_pool_name  = "appgw-testgateway-Central India-bapool01"
      default_backend_http_settings_name = "appgw-testgateway-Central India-be-http-set1"
      path_rules = [
        {
          name                       = "api"
          paths                      = ["/api/*"]
          backend_address_pool_name  = "appgw-testgateway-Central India-bapool01"
          backend_http_settings_name = "appgw-testgateway-Central India-be-http-set1"
        },
        {
          name                       = "videos"
          paths                      = ["/videos/*"]
          backend_address_pool_name  = "appgw-testgateway-Central India-bapool02"
          backend_http_settings_name = "appgw-testgateway-Central India-be-http-set2"
        }
      ]
    }
  ]

  # .... omitted
}
```
### `waf_configuration` - Azure Web Application Firewall

Azure Web Application Firewall (WAF) on Azure Application Gateway provides centralized protection of your web applications from common exploits and vulnerabilities. Web applications are increasingly targeted by malicious attacks that exploit commonly known vulnerabilities. SQL injection and cross-site scripting are among the most common attacks.

The `waf_configuration` object is used to specify waf configuration, disabled rule groups and exclusions. The following code example is the snippet of `waf_configuration` from example file.

```hcl
module "application-gateway" {
  source  = "../.."

  # .... omitted

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

  # .... omitted
}
```

For more information on Web Application Firewall CRS rule groups and rules, [visit Microsoft documentation](https://docs.microsoft.com/en-us/azure/web-application-firewall/ag/application-gateway-crs-rulegroups-rules?tabs=owasp32).

## Recommended naming and tagging conventions

Applying tags to your Azure resources, resource groups, and subscriptions to logically organize them into a taxonomy. Each tag consists of a name and a value pair. For example, you can apply the name `Environment` and the value `Production` to all the resources in production.
For recommendations on how to implement a tagging strategy, see Resource naming and tagging decision guide.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| azurerm | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.0 |

## Inputs

Name | Description | Type | Default
---- | ----------- | ---- | -------
`create_resource_group` | Whether to create resource group and use it for all networking resources | string | `"false"`
`resource_group_name`|The name of an existing resource group.|string|`""`
`location`|The location for all resources while creating a new resource group.|string|`""`
`virtual_network_name`|The name of the virtual network|string|`""`
`vnet_resource_group_name`|The resource group name where the virtual network is created|string|`""`
`subnet_name`|The name of the subnet to use in VM scale set|string|`""`
`app_gateway_name`|The name of the application gateway|string|`""`
`domain_name_label`|Label for the Domain Name. Will be used to make up the FQDN|string|`null`
`enable_http2`|Is HTTP2 enabled on the application gateway resource?|string|`false`
`zones`|A collection of availability zones to spread the Application Gateway over|list(string)|`[]`
`firewall_policy_id`|The ID of the Web Application Firewall Policy which can be associated with app gateway|string|`null`
`sku`|The sku pricing model of v1 and v2|object({})|`{}`
`autoscale_configuration`|Minimum or Maximum capacity for autoscaling. Accepted values are for Minimum in the range `0` to `100` and for Maximum in the range `2` to `125`|object|`null`
`private_ip_address`|Private IP Address to assign to the Load Balancer|string|`null`
`backend_address_pools`|List of backend address pools|list(object{})|`[]`
`backend_http_settings`|List of backend HTTP settings|list(object{})|`[]`
`http_listeners`|List of HTTP/HTTPS listeners. SSL Certificate name is required|list(object{})|`[]`
`request_routing_rules`|List of Request routing rules to be used for listeners|list(object{})|`[]`
`identity_ids`|Specifies a list with a single user managed identity id to be assigned to the Application Gateway|list(string)|`null`
`health_probes`|List of Health probes used to test backend pools health|list(object{})|`[]`
`url_path_maps`|List of URL path maps associated to path-based rules|list(object{})|`[]`
`redirect_configuration`|list of maps for redirect configurations|list(map(string))|`[]`
`custom_error_configuration`|Global level custom error configuration for application gateway|list(map(string))|`[]`
`rewrite_rule_set`|List of rewrite rule set including rewrite rules|any|`[]`
`waf_configuration`|Web Application Firewall support for your Azure Application Gateway|object({})|`null`
`Tags`|A map of tags to add to all resources|map|`{}`

## Outputs

Name | Description
---- | -----------
`application_gateway_id`|The ID of the Application Gateway

## Other resources

* [Azure Application Gateway documentation](https://docs.microsoft.com/en-us/azure/application-gateway/)

* [Terraform AzureRM Provider Documentation](https://www.terraform.io/docs/providers/azurerm/index.html)
<!-- END_TF_DOCS -->

## Authors

Module managed by [TO THE NEW Pvt. Ltd.](https://github.com/tothenew)

## License

Apache 2 Licensed. See [LICENSE](https://github.com/tothenew/terraform-azurerm-template/blob/main/LICENSE) for full details.
