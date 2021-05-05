resource "random_string" "log_workspace_suffix" {
  length  = 3
  special = false
  upper   = false
}

resource "azurerm_log_analytics_workspace" "aks" {
  # 4-63 文字で数字、アルファベット、`-`
  name                = "${local.name}-${random_string.log_workspace_suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_in_days
  daily_quota_gb      = var.log_analytics_daily_quota_gb
}
