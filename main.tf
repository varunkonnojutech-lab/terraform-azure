# Identity of whoever runs Terraform (used for the Key Vault access policy).
data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Resource group
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-${var.environment}-rg"
  location = var.location

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ---------------------------------------------------------------------------
# App Service plan + Linux web app (.NET 8)
# ---------------------------------------------------------------------------
resource "azurerm_service_plan" "main" {
  name                = "${var.prefix}-${var.environment}-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"

  tags = {
    environment = var.environment
  }
}

resource "azurerm_linux_web_app" "main" {
  name                = "${var.prefix}-${var.environment}-app"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true

    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = {
    ASPNETCORE_ENVIRONMENT = var.environment == "prod" ? "Production" : "Development"
  }

  tags = {
    environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Azure SQL: server + database
# ---------------------------------------------------------------------------
resource "azurerm_mssql_server" "main" {
  name                         = "${var.prefix}-${var.environment}-sql"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_user
  administrator_login_password = var.sql_admin_password

  tags = {
    environment = var.environment
  }
}

resource "azurerm_mssql_database" "main" {
  name      = "${var.prefix}db"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "S0"

  tags = {
    environment = var.environment
  }
}

# NOTE: no firewall rule is created here. To connect from your machine, add one:
#
#   resource "azurerm_mssql_firewall_rule" "office" {
#     name             = "office"
#     server_id        = azurerm_mssql_server.main.id
#     start_ip_address = "<your-public-ip>"
#     end_ip_address   = "<your-public-ip>"
#   }

# ---------------------------------------------------------------------------
# Key Vault (standard SKU)
# ---------------------------------------------------------------------------
resource "azurerm_key_vault" "main" {
  name                            = "${var.prefix}-${var.environment}-kv"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_template_deployment = true

  # The identity running Terraform gets full secret access.
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete"]
  }

  # The web app's managed identity can read secrets (e.g. via Key Vault
  # references in app settings) but not write them.
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_web_app.main.identity[0].principal_id

    secret_permissions = ["Get", "List"]
  }

  tags = {
    environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Service Bus namespace + queue
# ---------------------------------------------------------------------------
resource "azurerm_servicebus_namespace" "main" {
  name                = "${var.prefix}-${var.environment}-sb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  tags = {
    environment = var.environment
  }
}

resource "azurerm_servicebus_queue" "orders" {
  name         = "orders"
  namespace_id = azurerm_servicebus_namespace.main.id

  max_size_in_megabytes = 1024
  default_message_ttl   = "P14D"
}

# ---------------------------------------------------------------------------
# Application Insights
# ---------------------------------------------------------------------------
resource "azurerm_application_insights" "main" {
  name                = "${var.prefix}-${var.environment}-ai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  tags = {
    environment = var.environment
  }
}
