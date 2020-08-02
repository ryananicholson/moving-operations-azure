provider "azurerm" {
  version = "2.20.0"
  features {}
}

resource "random_string" "demo_string" { 
  length = 18
  upper = false
  special = false
}

resource "azurerm_resource_group" "demo_rg" {
  name = "demo_rg"
  location = "East US"
}

resource "azurerm_virtual_network" "demo_vnet" {
  name = "demo_vnet"
  resource_group_name = azurerm_resource_group.demo_rg.name
  location = azurerm_resource_group.demo_rg.location
  address_space = ["10.4.0.0/16"]
}

resource "azurerm_subnet" "demo_subnet" {
  name = "demo_subnet"
  resource_group_name = azurerm_resource_group.demo_rg.name
  virtual_network_name = azurerm_virtual_network.demo_vnet.name
  address_prefixes = ["10.4.88.0/24"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "demo_frontend" {
  name = "demo_frontend"
  resource_group_name = azurerm_resource_group.demo_rg.name
  virtual_network_name = azurerm_virtual_network.demo_vnet.name
  address_prefixes = ["10.4.89.0/24"]
}

resource "azurerm_network_security_group" "demo_nsg" {
  name                = "demoNSG"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name

  security_rule {
    name                       = "HTTP-In"
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
    name                       = "SSH-In"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.4.88.0/24"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "demo_mgmt_nsg" {
  name                = "demo-mgmtNSG"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name

  security_rule {
    name                       = "SSH-In"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_watcher" "demo_nw" {
  name                = "demo_nw"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
}

resource "azurerm_storage_account" "demo_sa" {
  name                = "demosa${random_string.demo_string.result}"
  resource_group_name = azurerm_resource_group.demo_rg.name
  location            = azurerm_resource_group.demo_rg.location

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

resource "azurerm_log_analytics_workspace" "demo_law" {
  name                = "demolaw${random_string.demo_string.result}"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  sku                 = "PerGB2018"
}

resource "azurerm_network_watcher_flow_log" "demo_nwfl" {
  network_watcher_name = azurerm_network_watcher.demo_nw.name
  resource_group_name  = azurerm_resource_group.demo_rg.name

  network_security_group_id = azurerm_network_security_group.demo_nsg.id
  storage_account_id        = azurerm_storage_account.demo_sa.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.demo_law.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.demo_law.location
    workspace_resource_id = azurerm_log_analytics_workspace.demo_law.id
    interval_in_minutes   = 10
  }
}

resource "azurerm_public_ip" "demo_ip" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "demo_ip_mgmt" {
  name                = "PublicIPForMGMT"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "demo_ni" {
  name                = "demo-mgmt-nic"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_ip_mgmt.id
  }
}

resource "azurerm_network_interface_security_group_association" "demo_nsga" {
  network_interface_id      = azurerm_network_interface.demo_ni.id
  network_security_group_id = azurerm_network_security_group.demo_mgmt_nsg.id
}

resource "azurerm_application_gateway" "demo_apigw" {
  name                = "demo-appgateway"
  resource_group_name = azurerm_resource_group.demo_rg.name
  location            = azurerm_resource_group.demo_rg.location

  sku {
    name     = "WAF_Medium"
    tier     = "WAF"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "demo-gateway-ip-configuration"
    subnet_id = azurerm_subnet.demo_frontend.id
  }

  frontend_port {
    name = "HTTP-Frontend"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "HTTP-Frontend-Configuration"
    public_ip_address_id = azurerm_public_ip.demo_ip.id
  }

  backend_address_pool {
    name = "Backend-Pool"
  }

  backend_http_settings {
    name                  = "HTTP-Settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "HTTP-Listener"
    frontend_ip_configuration_name = "HTTP-Frontend-Configuration"
    frontend_port_name             = "HTTP-Frontend"
    protocol                       = "Http"
  }
  
  request_routing_rule {
    name                       = "Routing-Rule"
    rule_type                  = "Basic"
    http_listener_name         = "HTTP-Listener"
    backend_address_pool_name  = "Backend-Pool"
    backend_http_settings_name = "HTTP-Settings"
  }

  waf_configuration {
    enabled = true
    firewall_mode = "Prevention"
    rule_set_type = "OWASP"
    rule_set_version = "3.0"
    request_body_check = true
  }
}

resource "null_resource" "demo_public_ip" {
  provisioner "local-exec" {
    command = "echo -n 'demo-mgmt IP:  ' > ${path.module}/addresses.txt; az network public-ip list | jq -r '.[] | select(.name == \"PublicIPForMGMT\") .ipAddress' >> ${path.module}/addresses.txt; echo -n 'Web App FQDN:  ' >> ${path.module}/addresses.txt; az network public-ip show --name PublicIPForLB --resource-group demo_rg | jq -r '. .dnsSettings.fqdn' >> ${path.module}/addresses.txt"
  }
  depends_on = [azurerm_application_gateway.demo_apigw, azurerm_public_ip.demo_ip_mgmt]
}

resource "azurerm_linux_virtual_machine_scale_set" "demo_vmss" {
  name                = "demo_vmss"
  resource_group_name = azurerm_resource_group.demo_rg.name
  location            = azurerm_resource_group.demo_rg.location
  sku                 = "Standard_B1s"
  instances           = 2
  computer_name_prefix = "demo-web"
  admin_username      = "student"
  disable_password_authentication = false
  admin_password = "Security488!"
  custom_data = base64encode(replace(replace(file("${path.module}/web-build.sh"),"IPADDR" ,"${azurerm_private_endpoint.demo_endpoint.custom_dns_configs[0].ip_addresses[0]}"),"DBSERVER", replace("${azurerm_mysql_server.demo_db_server.fqdn}", ".mysql.database.azure.com","")))
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "demo_webserver_interface"
    primary = true
    network_security_group_id = azurerm_network_security_group.demo_nsg.id

    ip_configuration {
      name      = "demo_internal"
      primary   = true
      subnet_id = azurerm_subnet.demo_subnet.id
      application_gateway_backend_address_pool_ids = [azurerm_application_gateway.demo_apigw.backend_address_pool[0].id]
    }
  }
}

resource "azurerm_mysql_server" "demo_db_server" {
  name                = "demoss${random_string.demo_string.result}"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name

  administrator_login          = "student"
  administrator_login_password = "Security488!"

  sku_name   = "GP_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = false
}

resource "azurerm_mysql_configuration" "demo_db_audit_log_enabled" {
  name                = "audit_log_enabled"
  resource_group_name = azurerm_resource_group.demo_rg.name
  server_name         = azurerm_mysql_server.demo_db_server.name
  value               = "ON"
}

resource "azurerm_mysql_configuration" "demo_db_audit_log_events" {
  name                = "audit_log_events"
  resource_group_name = azurerm_resource_group.demo_rg.name
  server_name         = azurerm_mysql_server.demo_db_server.name
  value               = "CONNECTION,DCL,DDL,DML"
}

resource "azurerm_mysql_firewall_rule" "demo_db_firewall" {
  name                = "demo-web-servers"
  resource_group_name = azurerm_resource_group.demo_rg.name
  server_name         = azurerm_mysql_server.demo_db_server.name
  start_ip_address    = "10.4.88.4"
  end_ip_address      = "10.4.88.254"
}

resource "azurerm_mysql_database" "demo_db" {
  name                = "demo-db"
  resource_group_name = azurerm_resource_group.demo_rg.name
  server_name         = azurerm_mysql_server.demo_db_server.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_private_endpoint" "demo_endpoint" {
  name                = "demoep${random_string.demo_string.result}"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  subnet_id           = azurerm_subnet.demo_subnet.id

  private_service_connection {
    name                           = "demopc${random_string.demo_string.result}"
    private_connection_resource_id = azurerm_mysql_server.demo_db_server.id
    is_manual_connection           = false
    subresource_names              = ["mysqlServer"]
  }
}

resource "azurerm_linux_virtual_machine" "demo_mgmt" {
  name                = "demo-mgmt"
  resource_group_name = azurerm_resource_group.demo_rg.name
  location            = azurerm_resource_group.demo_rg.location
  size                = "Standard_B1s"
  admin_username      = "student"
  disable_password_authentication = false
  admin_password = "Security488!"
  custom_data = base64encode(replace(replace(file("${path.module}/mgmt-build.sh"),"IPADDR" ,"${azurerm_private_endpoint.demo_endpoint.custom_dns_configs[0].ip_addresses[0]}"),"DBSERVER", replace("${azurerm_mysql_server.demo_db_server.fqdn}", ".mysql.database.azure.com","")))
  network_interface_ids = [
    azurerm_network_interface.demo_ni.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [azurerm_mysql_server.demo_db_server]
}

resource "azurerm_monitor_diagnostic_setting" "demo_mon_nsg" {
  name               = "demo-mon-nsg"
  target_resource_id = azurerm_network_security_group.demo_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo_law.id

  log {
    category = "NetworkSecurityGroupEvent"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "NetworkSecurityGroupRuleCounter"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "demo_mon_apigw" {
  name               = "demo-mon-apigw"
  target_resource_id = azurerm_application_gateway.demo_apigw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo_law.id

  log {
    category = "ApplicationGatewayAccessLog"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "ApplicationGatewayFirewallLog"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "demo_mon_db" {
  name               = "demo-mon-db"
  target_resource_id = azurerm_mysql_server.demo_db_server.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo_law.id

  log {
    category = "MySqlSlowLogs"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "MySqlAuditLogs"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}
